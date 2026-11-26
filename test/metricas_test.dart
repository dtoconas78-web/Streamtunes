import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_ciudad.dart';
import 'package:streamtunes_demo/data/repositorio_metricas.dart';
import 'package:streamtunes_demo/data/reproducciones_dao.dart';
import 'package:streamtunes_demo/data/services/base_datos_local.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/services/sincronizacion_metricas.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/metricas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/perfil_oyente_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/estadisticas_cancion_screen.dart';

import 'dobles_persistencia.dart';

Cancion _cancion(String id, {int duracion = 180}) => Cancion(
  id: id,
  titulo: 'Tema $id',
  duracionSegundos: duracion,
  reproducciones: 0,
  tendencia: '',
  lugar: '',
  horarioPico: '',
  colorPortada: 0xFFFF5500,
);

/// Fuente con `metricas` controlada por el test y que registra incrementos.
class _FuenteMetricas implements FuenteFirestore, IncrementadorFirestore {
  final docs = StreamController<List<DocumentoFirestore>>.broadcast();
  final incrementos = <(String, String, Map<String, Object>)>[];

  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) =>
      docs.stream;

  @override
  Future<void> incrementar(
    String coleccion,
    String id,
    Map<String, Object> incrementos,
  ) async => this.incrementos.add((coleccion, id, incrementos));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FuenteSinIncrementos implements FuenteFirestore {
  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('modelo', () {
    test('franjas horarias en los bordes', () {
      expect(FranjaHoraria.de(0), FranjaHoraria.madrugada);
      expect(FranjaHoraria.de(5), FranjaHoraria.madrugada);
      expect(FranjaHoraria.de(6), FranjaHoraria.manana);
      expect(FranjaHoraria.de(11), FranjaHoraria.manana);
      expect(FranjaHoraria.de(12), FranjaHoraria.tarde);
      expect(FranjaHoraria.de(18), FranjaHoraria.tarde);
      expect(FranjaHoraria.de(19), FranjaHoraria.noche);
      expect(FranjaHoraria.de(23), FranjaHoraria.noche);
    });

    test('normalizarCiudad limpia espacios, puntos y vacíos', () {
      expect(normalizarCiudad('  San   Rafael '), 'San Rafael');
      expect(normalizarCiudad('Gral. Alvear'), 'Gral Alvear');
      expect(normalizarCiudad(''), ciudadSinDeclarar);
      expect(normalizarCiudad(null), ciudadSinDeclarar);
      expect(normalizarCiudad('x' * 60).length, 40);
    });

    test('sumar y fromMap tolerante', () {
      final a = MetricasCancion.una('Mendoza', FranjaHoraria.noche);
      final b = MetricasCancion.una('Córdoba', FranjaHoraria.noche);
      expect(
        a.sumar(b).sumar(a),
        const MetricasCancion(
          total: 3,
          ciudades: {'Mendoza': 2, 'Córdoba': 1},
          franjas: {'noche': 3},
        ),
      );
      expect(MetricasCancion.fromMap(a.toMap()), a);
      expect(
        MetricasCancion.fromMap({
          'total': 'mucho',
          'ciudades': {'Mendoza': 2, 'Rara': 'x', 'Negativa': -1},
          'franjas': 'no',
        }),
        const MetricasCancion(ciudades: {'Mendoza': 2}),
      );
      expect(MetricasCancion.fromMap(null).vacia, isTrue);
    });

    test('resumen: total, ciudades de mayor a menor y franja pico', () {
      final r = resumirMetricas([
        const MetricasCancion(
          total: 3,
          ciudades: {'Mendoza': 2, 'Córdoba': 1},
          franjas: {'noche': 2, 'tarde': 1},
        ),
        const MetricasCancion(
          total: 2,
          ciudades: {'Córdoba': 1, 'Buenos Aires': 1},
          franjas: {'noche': 2},
        ),
      ]);
      expect(r.total, 5);
      expect(
        [for (final c in r.ciudades) (c.ciudad, c.cantidad)],
        [('Córdoba', 2), ('Mendoza', 2), ('Buenos Aires', 1)],
      );
      expect(r.franjaPico, FranjaHoraria.noche);
      expect(r.proporcion(FranjaHoraria.noche), 0.8);
      expect(r.franjas[FranjaHoraria.madrugada], 0);
      expect(resumirMetricas(const []).franjaPico, isNull);
    });
  });

  group('conteo en el reproductor', () {
    late List<String> contadas;
    late ControladorReproduccion r;

    ControladorReproduccion crear(List<Cancion> canciones) {
      contadas = [];
      return r = ControladorReproduccion(
        repositorioCatalogo: RepositorioCatalogoMemoria(canciones: canciones),
        alContarReproduccion: (c) => contadas.add(c.id),
      );
    }

    testWidgets('cuenta a los 30 segundos, no a los 29, y una sola vez', (
      tester,
    ) async {
      crear([_cancion('a'), _cancion('b')]).reproducir(0);
      await tester.pump(const Duration(seconds: 29));
      expect(contadas, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(contadas, ['a']);
      await tester.pump(const Duration(seconds: 60));
      expect(contadas, ['a']);
      r.dispose();
    });

    testWidgets('adelantar con la barra no suma segundos escuchados', (
      tester,
    ) async {
      crear([_cancion('a')]).reproducir(0);
      r.saltarA(170);
      await tester.pump(const Duration(seconds: 5));
      expect(contadas, isEmpty);
      r.dispose();
    });

    testWidgets('pausado no cuenta', (tester) async {
      crear([_cancion('a')]).reproducir(0);
      r.alternarPausa();
      await tester.pump(const Duration(seconds: 40));
      expect(contadas, isEmpty);
      r.dispose();
    });

    testWidgets('una canción corta cuenta al escucharla entera', (
      tester,
    ) async {
      crear([_cancion('corta', duracion: 10), _cancion('b')]).reproducir(0);
      await tester.pump(const Duration(seconds: 9));
      expect(contadas, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(contadas, ['corta']);
      r.dispose();
    });

    testWidgets('pasar a otra y repetir la misma son escuchas nuevas', (
      tester,
    ) async {
      crear([_cancion('a'), _cancion('b')]).reproducir(0);
      await tester.pump(const Duration(seconds: 30));
      r.siguiente();
      await tester.pump(const Duration(seconds: 30));
      r.anterior(); // pasaron más de 3 s: vuelve a empezar "b"
      await tester.pump(const Duration(seconds: 30));
      expect(contadas, ['a', 'b', 'b']);
      r.dispose();
    });
  });

  group('SQLite: cola de reproducciones', () {
    late Database db;
    late ReproduccionesDao dao;
    final ahora = DateTime(2026, 11, 26, 21);

    setUp(() async {
      db = await baseEnMemoria();
      dao = ReproduccionesDao(db);
    });
    tearDown(() => db.close());

    Future<void> registrar(String cancionId, [String ciudad = 'Mendoza']) =>
        dao.registrar(
          cancionId: cancionId,
          ciudad: ciudad,
          franja: FranjaHoraria.noche,
          fecha: ahora,
        );

    test('un lote reservado no lo vuelve a tomar otro', () async {
      await registrar('a');
      await registrar('b');
      final primero = await dao.tomarLote(ahora: ahora);
      expect(primero.reproducciones.map((r) => r.cancionId), ['a', 'b']);
      expect((await dao.tomarLote(ahora: ahora)).vacio, isTrue);

      await registrar('c');
      final segundo = await dao.tomarLote(ahora: ahora);
      expect(segundo.reproducciones.map((r) => r.cancionId), ['c']);
    });

    test('confirmar borra y liberar devuelve a la cola', () async {
      await registrar('a');
      await registrar('b');
      final lote = await dao.tomarLote(ahora: ahora);
      await dao.confirmar(lote.id, [lote.reproducciones.first.id]);
      await dao.liberar(lote.id);
      expect(await dao.pendientes(), 1);
      final otra = await dao.tomarLote(ahora: ahora);
      expect(otra.reproducciones.single.cancionId, 'b');
    });

    test('una reserva colgada vence y se puede volver a tomar', () async {
      await registrar('a');
      await dao.tomarLote(ahora: ahora); // nadie la confirma ni la libera
      final despues = ahora.add(
        ReproduccionesDao.vencimientoLote + const Duration(seconds: 1),
      );
      expect(
        (await dao.tomarLote(ahora: despues)).reproducciones,
        hasLength(1),
      );
    });

    test('la base vieja (v1) se actualiza sin perder las playlists', () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('streamtunes');
      final ruta = '${dir.path}/v1.db';
      try {
        final v1 = await databaseFactoryFfi.openDatabase(
          ruta,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute(
                'CREATE TABLE playlists (id TEXT PRIMARY KEY, uid TEXT NOT NULL, '
                'nombre TEXT NOT NULL, orden INTEGER NOT NULL)',
              );
              await db.insert('playlists', {
                'id': 'p1',
                'uid': 'u1',
                'nombre': 'Vieja',
                'orden': 0,
              });
            },
          ),
        );
        await v1.close();

        final v2 = await databaseFactoryFfi.openDatabase(
          ruta,
          options: opcionesBaseDatos(unicaInstancia: false),
        );
        expect(await v2.getVersion(), versionBaseDatos);
        expect((await v2.query('playlists')).single['nombre'], 'Vieja');
        expect(await v2.query('portadas'), isEmpty); // tabla de la v3
        await ReproduccionesDao(v2).registrar(
          cancionId: 'a',
          ciudad: 'Mendoza',
          franja: FranjaHoraria.tarde,
          fecha: ahora,
        );
        expect(await ReproduccionesDao(v2).pendientes(), 1);
        await v2.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    group('sincronizarMetricas', () {
      test('suma un incremento por canción y vacía la cola', () async {
        await registrar('a', 'Mendoza');
        await registrar('a', 'Córdoba');
        await registrar('b', 'Mendoza');
        final sumados = <String, MetricasCancion>{};

        final n = await sincronizarMetricas(
          dao: dao,
          sumar: (id, inc) async => sumados[id] = inc,
          ahora: ahora,
        );

        expect(n, 3);
        expect(sumados, {
          'a': const MetricasCancion(
            total: 2,
            ciudades: {'Mendoza': 1, 'Córdoba': 1},
            franjas: {'noche': 2},
          ),
          'b': const MetricasCancion(
            total: 1,
            ciudades: {'Mendoza': 1},
            franjas: {'noche': 1},
          ),
        });
        expect(await dao.pendientes(), 0);
      });

      test('lo que falla queda en la cola y se sube la próxima', () async {
        await registrar('a');
        await registrar('b');
        var falla = true;
        final sumados = <String>[];
        Future<void> sumar(String id, MetricasCancion _) async {
          if (id == 'b' && falla) throw StateError('sin red');
          sumados.add(id);
        }

        expect(
          await sincronizarMetricas(dao: dao, sumar: sumar, ahora: ahora),
          1,
        );
        expect(await dao.pendientes(), 1);

        falla = false;
        expect(
          await sincronizarMetricas(dao: dao, sumar: sumar, ahora: ahora),
          1,
        );
        expect(sumados, ['a', 'b']);
        expect(await dao.pendientes(), 0);
      });
    });

    test(
      'RegistroReproducciones guarda en la cola y sube al sincronizar',
      () async {
        final metricas = RepositorioMetricasMemoria();
        final registro = RegistroReproducciones(
          metricas: metricas,
          ciudad: () => 'Mendoza',
          dao: dao,
          reloj: RelojFijo(ahora),
        );
        registro.contar(_cancion('a'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(await dao.pendientes(), 1);
        expect(metricas.de('a'), isNull); // todavía no se subió

        // Dos pedidos a la vez comparten la misma sincronización.
        final uno = registro.sincronizar();
        final dos = registro.sincronizar();
        expect(identical(uno, dos), isTrue);
        expect(await uno, 1);
        expect(metricas.de('a')!.ciudades, {'Mendoza': 1});
      },
    );
  });

  test('sin base local, RegistroReproducciones suma directo', () async {
    final metricas = RepositorioMetricasMemoria();
    RegistroReproducciones(
      metricas: metricas,
      ciudad: () => '',
      reloj: RelojFijo(DateTime(2026, 11, 26, 8)),
    ).contar(_cancion('a'));
    await Future<void>.delayed(Duration.zero);
    expect(
      metricas.de('a'),
      const MetricasCancion(
        total: 1,
        ciudades: {ciudadSinDeclarar: 1},
        franjas: {'manana': 1},
      ),
    );
  });

  group('RepositorioMetricasFirestore', () {
    test('lee la colección y suma con incrementos atómicos', () async {
      final fuente = _FuenteMetricas();
      final repo = RepositorioMetricasFirestore(fuente: fuente);
      fuente.docs.add([
        const DocumentoFirestore(
          id: 'a',
          datos: {
            'total': 4,
            'ciudades': {'Mendoza': 4},
            'franjas': {'noche': 4},
          },
        ),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(repo.esRemoto, isTrue);
      expect(repo.de('a')!.total, 4);
      expect(repo.de('otra'), isNull);

      final inc = MetricasCancion.una('Córdoba', FranjaHoraria.tarde);
      await repo.sumar('a', inc);
      final (coleccion, id, datos) = fuente.incrementos.single;
      expect((coleccion, id), ('metricas', 'a'));
      expect(MetricasCancion.fromMap(datos), inc);
      await repo.cerrar();
    });

    test('una fuente que no sabe incrementar falla claro', () {
      final repo = RepositorioMetricasFirestore(
        fuente: _FuenteSinIncrementos(),
      );
      expect(
        () => repo.sumar('a', const MetricasCancion(total: 1)),
        throwsUnsupportedError,
      );
    });
  });

  test('MetricasViewModel recalcula el resumen del artista', () async {
    final repo = RepositorioMetricasMemoria();
    final vm = MetricasViewModel(repositorio: repo);
    await Future<void>.delayed(Duration.zero);
    expect(vm.resumenArtista.vacio, isTrue);

    await repo.sumar('a', MetricasCancion.una('Mendoza', FranjaHoraria.noche));
    await repo.sumar('b', MetricasCancion.una('Mendoza', FranjaHoraria.tarde));
    await Future<void>.delayed(Duration.zero);
    expect(vm.calculando, isFalse);
    expect(vm.resumenArtista.total, 2);
    expect(vm.resumenArtista.ciudades.single.ciudad, 'Mendoza');
    expect(vm.resumenDe('a')!.total, 1);
    expect(vm.resumenDe('c'), isNull);
  });

  group('PerfilOyenteViewModel (ciudad)', () {
    test('guarda por usuario y normaliza', () async {
      final prefs = preferenciasEnMemoria();
      final vm = PerfilOyenteViewModel(
        repositorio: RepositorioCiudadPreferencias(prefs: prefs),
      )..usarUsuario('u1');
      await vm.listo;
      expect(vm.ciudad, '');
      expect(vm.ciudadParaMetricas, ciudadSinDeclarar);

      await vm.guardarCiudad('  San   Rafael ');
      expect(vm.ciudad, 'San Rafael');
      expect(
        await prefs.getString(RepositorioCiudadPreferencias.clave('u1')),
        'San Rafael',
      );

      vm.usarUsuario('u2');
      expect(vm.ciudad, '');
      vm.usarUsuario('u1');
      await vm.listo;
      expect(vm.ciudad, 'San Rafael');
    });

    test('sin sesión (invitado) no puede declarar', () async {
      final repo = RepositorioCiudadMemoria();
      final vm = PerfilOyenteViewModel(repositorio: repo);
      expect(vm.puedeDeclarar, isFalse);
      await vm.guardarCiudad('Mendoza');
      expect(vm.ciudad, '');
    });
  });

  group('PantallaB con métricas reales', () {
    testWidgets('muestra total, franjas y ciudades reales', (tester) async {
      final repo = RepositorioMetricasMemoria();
      await repo.sumar(
        'a',
        const MetricasCancion(
          total: 1234,
          ciudades: {'Mendoza': 1000, 'Córdoba': 234},
          franjas: {'noche': 1000, 'tarde': 234},
        ),
      );
      final vm = MetricasViewModel(repositorio: repo);
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaB(cancion: _cancion('a'), metricas: vm),
        ),
      );
      await tester.pump();

      expect(find.text('1.234'), findsOneWidget);
      expect(find.text('Mendoza'), findsOneWidget);
      expect(find.text(FranjaHoraria.noche.etiqueta), findsOneWidget);
      expect(find.textContaining('Datos de ejemplo'), findsNothing);
      // Con datos reales el contador no se simula.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('1.234'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });

    testWidgets('sin datos y sin Firebase avisa que son de ejemplo', (
      tester,
    ) async {
      final vm = MetricasViewModel(repositorio: RepositorioMetricasMemoria());
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaB(cancion: _cancion('a'), metricas: vm),
        ),
      );
      expect(find.textContaining('Datos de ejemplo'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    });
  });
}
