import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano.dart';
import 'package:streamtunes_demo/services/verificacion_novedades.dart';

import 'dobles_persistencia.dart';

/// Fuente de Firestore mínima: solo la colección `conciertos`, que se puede
/// cambiar entre corridas (como si se publicaran conciertos nuevos).
class _FuenteConciertos implements FuenteFirestore {
  List<DocumentoFirestore> conciertos = [];
  bool fallar = false;
  bool colgarse = false;

  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) {
    expect(coleccion, 'conciertos');
    if (fallar) return Stream.error(StateError('sin red'));
    // Stream que nunca emite: simula Firestore colgado (sin respuesta).
    if (colgarse) return StreamController<List<DocumentoFirestore>>().stream;
    return Stream.value(List.of(conciertos));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

DocumentoFirestore _concierto(String id, String nombre) => DocumentoFirestore(
  id: id,
  datos: {
    'nombre': nombre,
    'lugar': 'Lugar',
    'fecha': '2027-05-01T21:00:00.000',
    'precio': 1000,
    'disponibles': 10,
  },
);

void main() {
  late _FuenteConciertos fuente;
  late SharedPreferencesAsync prefs;
  late List<List<String>> avisos;

  Future<void> avisar(List<String> nombres) async => avisos.add(nombres);

  setUp(() async {
    prefs = preferenciasEnMemoria();
    fuente = _FuenteConciertos();
    avisos = [];
  });

  group('verificarNovedades', () {
    test('la primera corrida guarda la base y no avisa', () async {
      fuente.conciertos = [_concierto('c1', 'Uno'), _concierto('c2', 'Dos')];

      final nuevos = await verificarNovedades(
        fuente: fuente,
        prefs: prefs,
        avisar: avisar,
      );

      expect(nuevos, isEmpty);
      expect(avisos, isEmpty);
      expect(await prefs.getStringList(claveConciertosVistos), ['c1', 'c2']);
    });

    test('avisa solo los conciertos nuevos desde la última corrida', () async {
      fuente.conciertos = [_concierto('c1', 'Uno')];
      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);

      fuente.conciertos = [
        _concierto('c1', 'Uno'),
        _concierto('c2', 'Dos'),
        _concierto('c3', 'Tres'),
      ];
      final nuevos = await verificarNovedades(
        fuente: fuente,
        prefs: prefs,
        avisar: avisar,
      );

      expect(nuevos.map((c) => c.id), ['c2', 'c3']);
      expect(avisos, [
        ['Dos', 'Tres'],
      ]);

      // Una tercera corrida sin cambios no vuelve a avisar.
      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);
      expect(avisos.length, 1);
    });

    test('si avisar falla, no marca como vistos (se reintenta)', () async {
      fuente.conciertos = [];
      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);
      fuente.conciertos = [_concierto('c1', 'Uno')];

      await expectLater(
        verificarNovedades(
          fuente: fuente,
          prefs: prefs,
          avisar: (_) async => throw StateError('plugin caído'),
        ),
        throwsStateError,
      );
      expect(await prefs.getStringList(claveConciertosVistos), isEmpty);

      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);
      expect(avisos, [
        ['Uno'],
      ]);
    });

    test('un documento mal formado se ignora', () async {
      fuente.conciertos = [];
      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);
      fuente.conciertos = [
        DocumentoFirestore(id: 'roto', datos: {'nombre': 42}),
        _concierto('c1', 'Uno'),
      ];

      await verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar);
      expect(avisos, [
        ['Uno'],
      ]);
    });

    test('un error de Firestore se propaga sin tocar lo guardado', () async {
      await prefs.setStringList(claveConciertosVistos, ['c1']);
      fuente.fallar = true;

      await expectLater(
        verificarNovedades(fuente: fuente, prefs: prefs, avisar: avisar),
        throwsStateError,
      );
      expect(await prefs.getStringList(claveConciertosVistos), ['c1']);
      expect(avisos, isEmpty);
    });

    test('si Firestore no responde, corta por timeout', () async {
      fuente.colgarse = true;
      final completer = Completer<Object>();
      unawaited(
        verificarNovedades(
          fuente: fuente,
          prefs: prefs,
          avisar: avisar,
          limite: const Duration(milliseconds: 10),
        ).then<void>((_) {}, onError: completer.complete),
      );
      expect(await completer.future, isA<TimeoutException>());
    });
  });

  test('ServicioTareasNulo no hace nada ni falla', () async {
    const tareas = ServicioTareasNulo();
    await tareas.registrarVerificacionPeriodica();
    await tareas.cancelar();
  });
}
