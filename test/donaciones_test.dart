import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos_firestore.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/services/aviso_donaciones.dart';
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/hoja_donacion.dart';

import 'dobles_notificaciones.dart';

/// Fuente con la colección `movimientos` controlada por el test.
class _FuenteMovimientos implements FuenteFirestore {
  final _docs = StreamController<List<DocumentoFirestore>>.broadcast();

  void emitir(List<DocumentoFirestore> docs) => _docs.add(docs);

  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) =>
      _docs.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Reloj que el test puede adelantar.
class _RelojMovil implements Reloj {
  _RelojMovil(this.actual);
  DateTime actual;
  @override
  DateTime ahora() => actual;
}

/// Sesión mínima para el aviso (cambia el artista de la sesión).
class _Sesion extends ChangeNotifier {
  String? artista;
  void entrar(String? id) {
    artista = id;
    notifyListeners();
  }
}

Movimiento _donacion(
  double monto,
  DateTime fecha, {
  String donante = '',
  String artistaId = 'mateo-cabral',
}) => Movimiento(
  tipo: TipoMovimiento.donacion,
  detalle: 'Donación',
  monto: monto,
  fecha: fecha,
  donante: donante,
  artistaId: artistaId,
);

void main() {
  final fecha = DateTime(2026, 11, 26, 20);

  group('Movimiento con donante', () {
    test('ida y vuelta toMap/fromMap conserva donante y artista', () {
      final m = _donacion(1000, fecha, donante: 'Juana');
      expect(Movimiento.fromMap(m.toMap()), m);
      expect(m.esAnonima, isFalse);
    });

    test('un documento viejo sin donante se lee como anónimo', () {
      final m = Movimiento.fromMap({
        'tipo': 'donacion',
        'detalle': 'Donación de un fan',
        'monto': 500,
        'fecha': fecha,
      });
      expect(m.donante, '');
      expect(m.artistaId, '');
      expect(m.esAnonima, isTrue);
    });

    test('una venta nunca es "anónima"', () {
      final venta = Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: 'Show',
        monto: 1000,
        fecha: fecha,
      );
      expect(venta.esAnonima, isFalse);
    });
  });

  group('VentasViewModel', () {
    late VentasViewModel vm;
    setUp(() {
      vm = VentasViewModel(
        repositorio: RepositorioMovimientosMemoria(movimientos: []),
        reloj: RelojFijo(fecha),
      );
    });

    test('registrarDonacion guarda donante (sin espacios) y artista', () {
      vm.registrarDonacion(
        'Donación a Mateo',
        2000,
        donante: '  Juana  ',
        artistaId: 'mateo-cabral',
      );
      final m = vm.movimientos.single;
      expect(m.donante, 'Juana');
      expect(m.artistaId, 'mateo-cabral');
      expect(m.comision, 0); // las donaciones llegan completas
    });

    test('sin donante la donación queda anónima', () {
      vm.registrarDonacion('Donación', 500);
      expect(vm.movimientos.single.esAnonima, isTrue);
    });

    test(
      'quién te banca: agrupa por nombre, anónimos juntos, mayor primero',
      () {
        vm
          ..registrarDonacion('d', 1000, donante: 'Juana')
          ..registrarDonacion('d', 500)
          ..registrarDonacion('d', 3000, donante: 'Beto')
          ..registrarDonacion('d', 2500, donante: 'Juana')
          ..registrarDonacion('d', 700)
          ..registrarVenta('Show', 9000); // las ventas no cuentan

        expect(vm.quienesTeBancan, const [
          Bancador(nombre: 'Juana', total: 3500, cantidad: 2),
          Bancador(nombre: 'Beto', total: 3000, cantidad: 1),
          Bancador(nombre: '', total: 1200, cantidad: 2),
        ]);
        expect(vm.quienesTeBancan.last.anonimo, isTrue);
      },
    );

    test('sin donaciones la lista está vacía', () {
      vm.registrarVenta('Show', 1000);
      expect(vm.quienesTeBancan, isEmpty);
    });
  });

  group('RepositorioMovimientosFirestore: donaciones al artista', () {
    DocumentoFirestore doc(String id, Movimiento m, {String usuarioId = ''}) =>
        DocumentoFirestore(
          id: id,
          datos: {...m.toMap(), 'usuarioId': usuarioId},
        );

    Future<List<String>> idsVistos({String? artista}) async {
      final fuente = _FuenteMovimientos();
      final repo = RepositorioMovimientosFirestore(
        fuente: fuente,
        uidActual: () => 'uid-artista',
        artistaActual: () => artista,
      );
      fuente.emitir([
        // Donación de un fan al artista: la hizo otro usuario.
        doc('d1', _donacion(1000, fecha, donante: 'Juana'), usuarioId: 'fan'),
        // Donación a otro artista.
        doc(
          'd2',
          _donacion(500, fecha, artistaId: 'otro-artista'),
          usuarioId: 'fan',
        ),
        // Movimiento propio de la sesión.
        doc(
          'v1',
          Movimiento(
            tipo: TipoMovimiento.venta,
            detalle: 'Show',
            monto: 1000,
            fecha: fecha,
          ),
          usuarioId: 'uid-artista',
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      final ids = [for (final m in repo.movimientos) m.id];
      await repo.cerrar();
      return ids;
    }

    test(
      'el artista ve las donaciones que le hicieron otros usuarios',
      () async {
        expect(await idsVistos(artista: 'mateo-cabral'), ['d1', 'v1']);
      },
    );

    test('si la sesión no es de artista, solo ve lo propio', () async {
      expect(await idsVistos(), ['v1']);
    });
  });

  group('AvisoDonaciones', () {
    late RepositorioMovimientosMemoria repo;
    late _Sesion sesion;
    late _RelojMovil reloj;
    late RecordatoriosFalsos avisos;
    late bool activo;
    late AvisoDonaciones aviso;

    setUp(() {
      repo = RepositorioMovimientosMemoria(movimientos: []);
      sesion = _Sesion()..artista = 'mateo-cabral';
      reloj = _RelojMovil(fecha);
      avisos = RecordatoriosFalsos();
      activo = true;
      aviso = AvisoDonaciones(
        repositorio: repo,
        sesion: sesion,
        artistaActual: () => sesion.artista,
        activo: () => activo,
        avisar: avisos.mostrarDonacionRecibida,
        reloj: reloj,
      )..iniciar();
    });
    tearDown(() => aviso.detener());

    final despues = fecha.add(const Duration(minutes: 1));

    test('avisa una donación nueva una sola vez', () async {
      repo.registrar(_donacion(1000, despues, donante: 'Juana'));
      repo.registrar(_donacion(500, despues)); // vuelve a notificar el repo
      await Future<void>.delayed(Duration.zero);

      expect(avisos.donaciones, [
        (monto: 1000.0, donante: 'Juana'),
        (monto: 500.0, donante: ''),
      ]);
    });

    test('no avisa las donaciones viejas que llegan al abrir', () async {
      repo.registrar(_donacion(1000, fecha.subtract(const Duration(days: 1))));
      await Future<void>.delayed(Duration.zero);
      expect(avisos.donaciones, isEmpty);
    });

    test('no avisa donaciones a otro artista ni ventas', () async {
      repo.registrar(_donacion(1000, despues, artistaId: 'otro-artista'));
      repo.registrar(
        Movimiento(
          tipo: TipoMovimiento.venta,
          detalle: 'Show',
          monto: 1000,
          fecha: despues,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(avisos.donaciones, isEmpty);
    });

    test('con las notificaciones apagadas no avisa (ni después)', () async {
      activo = false;
      repo.registrar(_donacion(1000, despues));
      activo = true;
      repo.registrar(_donacion(700, despues.add(const Duration(seconds: 1))));
      await Future<void>.delayed(Duration.zero);
      expect(avisos.donaciones, [(monto: 700.0, donante: '')]);
    });

    test('si la sesión no es de un artista no avisa nada', () async {
      sesion.entrar(null); // un fan
      repo.registrar(_donacion(1000, despues));
      await Future<void>.delayed(Duration.zero);
      expect(avisos.donaciones, isEmpty);
    });

    test('al volver a entrar como artista cuenta desde ese momento', () async {
      sesion.entrar(null);
      reloj.actual = fecha.add(const Duration(hours: 1));
      sesion.entrar('mateo-cabral');
      // Llegó mientras no estaba (fecha anterior a la nueva sesión).
      repo.registrar(_donacion(1000, despues));
      repo.registrar(_donacion(900, fecha.add(const Duration(hours: 2))));
      await Future<void>.delayed(Duration.zero);
      expect(avisos.donaciones, [(monto: 900.0, donante: '')]);
    });

    test('texto del aviso con nombre y anónimo', () {
      expect(textoDonacionRecibida(r'$1.000', 'Juana'), (
        titulo: 'Recibiste una donación',
        cuerpo: r'Juana te donó $1.000',
      ));
      expect(
        textoDonacionRecibida(r'$500', '').cuerpo,
        r'Alguien te donó $500 de forma anónima',
      );
    });
  });

  group('HojaDonacion', () {
    Future<List<EleccionDonacion>> abrir(
      WidgetTester tester, {
      required String nombreFan,
    }) async {
      final elegidas = <EleccionDonacion>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HojaDonacion(
              nombreArtista: 'Mateo Cabral',
              nombreFan: nombreFan,
              alConfirmar: elegidas.add,
            ),
          ),
        ),
      );
      return elegidas;
    }

    testWidgets('por defecto dona con su nombre; el switch la hace anónima', (
      tester,
    ) async {
      final elegidas = await abrir(tester, nombreFan: 'Juana');
      expect(find.textContaining('fuiste vos: Juana'), findsOneWidget);

      await tester.tap(find.text(r'$1.000'));
      await tester.pump();
      await tester.tap(find.text(r'Donar $1.000'));
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('El artista no va a ver tu nombre'), findsOneWidget);
      await tester.tap(find.text(r'Donar $1.000'));

      expect(elegidas, [
        (monto: 1000.0, anonima: false),
        (monto: 1000.0, anonima: true),
      ]);
    });

    testWidgets('sin nombre en la cuenta solo puede ser anónima', (
      tester,
    ) async {
      final elegidas = await abrir(tester, nombreFan: '');
      final interruptor = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(interruptor.value, isTrue);
      expect(interruptor.onChanged, isNull);

      await tester.enterText(find.byType(TextField), '1500');
      await tester.pump();
      await tester.tap(find.text(r'Donar $1.500'));
      expect(elegidas, [(monto: 1500.0, anonima: true)]);
    });
  });
}
