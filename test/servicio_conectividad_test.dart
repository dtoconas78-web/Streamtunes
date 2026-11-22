import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/services/fuente_conectividad.dart';
import 'package:streamtunes_demo/services/servicio_conectividad.dart';
import 'package:streamtunes_demo/views/widgets/banner_sin_conexion.dart';

/// Fuente falsa para tests: no toca el plugin real ni hardware. El controlador
/// es sincrónico para que los eventos lleguen en el mismo instante del emit.
class FuenteConectividadFalsa implements FuenteConectividad {
  FuenteConectividadFalsa({this.estado = true});

  final StreamController<bool> _controlador = StreamController<bool>.broadcast(
    sync: true,
  );
  bool estado;

  @override
  Stream<bool> get cambios => _controlador.stream;

  @override
  Future<bool> get estadoActual async => estado;

  void emitir(bool online) {
    estado = online;
    _controlador.add(online);
  }

  Future<void> cerrar() => _controlador.close();
}

void main() {
  test('el stream emite solo cambios, sin duplicados', () async {
    final fuente = FuenteConectividadFalsa();
    final servicio = ServicioConectividad(fuente: fuente);
    final recibidos = <bool>[];
    final sub = servicio.cambiosConectividad.listen(recibidos.add);

    fuente.emitir(false);
    fuente.emitir(false); // duplicado: no debe llegar al stream
    fuente.emitir(true);
    await Future<void>.delayed(Duration.zero);

    expect(recibidos, [false, true]);
    expect(servicio.estaConectado, isTrue);

    await sub.cancel();
    servicio.dispose();
    await fuente.cerrar();
  });

  test('el estado inicial de la fuente pisa el valor por defecto', () async {
    final fuente = FuenteConectividadFalsa(estado: false);
    final servicio = ServicioConectividad(fuente: fuente);
    await Future<void>.delayed(Duration.zero);

    expect(servicio.estaConectado, isFalse);

    servicio.dispose();
    await fuente.cerrar();
  });

  test('dispose cancela la suscripción y no emite ni notifica más', () async {
    final fuente = FuenteConectividadFalsa();
    final servicio = ServicioConectividad(fuente: fuente);
    final recibidos = <bool>[];
    var notificaciones = 0;
    final sub = servicio.cambiosConectividad.listen(recibidos.add);
    servicio.addListener(() => notificaciones++);

    fuente.emitir(false);
    await Future<void>.delayed(Duration.zero);
    expect(recibidos, [false]);
    expect(notificaciones, 1);

    servicio.dispose();
    fuente.emitir(true);
    await Future<void>.delayed(Duration.zero);
    expect(recibidos, [false]);
    expect(notificaciones, 1);

    await sub.cancel();
    await fuente.cerrar();
  });

  testWidgets('el banner aparece solo sin conexión', (tester) async {
    final fuente = FuenteConectividadFalsa(estado: true);
    final servicio = ServicioConectividad(fuente: fuente);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BannerSinConexion(servicio: servicio)),
      ),
    );
    await tester.pump();
    expect(find.text(politicas.avisoSinConexion), findsNothing);

    fuente.emitir(false);
    await tester.pump();
    expect(find.text(politicas.avisoSinConexion), findsOneWidget);

    fuente.emitir(true);
    await tester.pump();
    expect(find.text(politicas.avisoSinConexion), findsNothing);

    servicio.dispose();
    await fuente.cerrar();
  });
}
