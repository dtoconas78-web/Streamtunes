import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo_firestore.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/services/firebase_semilla.dart';

// Fake en memoria de FuenteFirestore: sin red ni Firebase real. Emite el
// estado actual al suscribirse y luego cada cambio, como hace Firestore.
class FakeFuenteFirestore implements FuenteFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> docs = {};
  final Map<String, StreamController<List<DocumentoFirestore>>> _ctrl = {};
  int _autoId = 0;

  Map<String, Map<String, dynamic>> col(String coleccion) =>
      docs.putIfAbsent(coleccion, () => {});

  StreamController<List<DocumentoFirestore>> ctrl(String coleccion) =>
      _ctrl.putIfAbsent(
        coleccion,
        () => StreamController<List<DocumentoFirestore>>.broadcast(),
      );

  List<DocumentoFirestore> _snapshot(String coleccion) => [
    for (final e in col(coleccion).entries)
      DocumentoFirestore(id: e.key, datos: e.value),
  ];

  void emitir(String coleccion) => ctrl(coleccion).add(_snapshot(coleccion));

  void fallar(String coleccion, Object error) =>
      ctrl(coleccion).addError(error);

  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) async* {
    yield _snapshot(coleccion); // estado actual apenas se suscribe
    yield* ctrl(coleccion).stream;
  }

  @override
  Future<int> contar(String coleccion) async => col(coleccion).length;

  @override
  Future<bool> existeDocumento(String coleccion, String id) async =>
      col(coleccion).containsKey(id);

  @override
  Future<void> setDocumento(
    String coleccion,
    String id,
    Map<String, dynamic> datos,
  ) async {
    col(coleccion)[id] = Map<String, dynamic>.from(datos);
    emitir(coleccion);
  }

  @override
  Future<String> agregarDocumento(
    String coleccion,
    Map<String, dynamic> datos,
  ) async {
    final id = 'auto-${++_autoId}';
    await setDocumento(coleccion, id, datos);
    return id;
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(TransaccionFirestore txn) actualizar,
  ) async {
    return actualizar(_FakeTxn(this));
  }
}

class _FakeTxn implements TransaccionFirestore {
  _FakeTxn(this._fuente);

  final FakeFuenteFirestore _fuente;

  @override
  Future<DocumentoFirestore?> leer(String coleccion, String id) async {
    final datos = _fuente.col(coleccion)[id];
    return datos == null ? null : DocumentoFirestore(id: id, datos: datos);
  }

  @override
  void set(String coleccion, String id, Map<String, dynamic> datos) {
    _fuente.col(coleccion)[id] = Map<String, dynamic>.from(datos);
  }
}

Cancion _cancionPrueba(String id) => Cancion(
  id: id,
  titulo: 'Tema $id',
  duracionSegundos: 200,
  reproducciones: 10,
  tendencia: '+1%',
  lugar: 'Mendoza, AR',
  horarioPico: '20hs',
  colorPortada: 0xFF112233,
);

void main() {
  group('6.1 serialización de modelos', () {
    test('Cancion: ida y vuelta toMap/fromMap con id externo', () {
      final c = _cancionPrueba('c1');
      final map = c.toMap();
      expect(map['id'], isNull); // el id no se duplica dentro del doc
      final deVuelta = Cancion.fromMap(map, id: 'c1');
      expect(deVuelta.id, 'c1');
      expect(deVuelta.titulo, c.titulo);
      expect(deVuelta.colorPortada, c.colorPortada);
      expect(deVuelta.publica, isTrue);
      // el id también puede venir de map['id']
      expect(Cancion.fromMap({...map, 'id': 'doc-9'}).id, 'doc-9');
    });

    test('Album: ida y vuelta, cancionIds como lista de Strings', () {
      final a = Album(
        id: 'a1',
        titulo: 'Postales',
        anio: '2024',
        colorPortada: 123,
        cancionIds: const ['c1', 'c2'],
      );
      final deVuelta = Album.fromMap(a.toMap(), id: a.id);
      expect(deVuelta.id, 'a1');
      expect(deVuelta.cancionIds, ['c1', 'c2']);
      expect(deVuelta.colorPortada, 123);
    });

    test('Artista: ida y vuelta', () {
      final a = Artista(id: 'mateo-cabral', nombre: 'Mateo Cabral');
      final deVuelta = Artista.fromMap(a.toMap(), id: a.id);
      expect(deVuelta.id, 'mateo-cabral');
      expect(deVuelta.nombre, 'Mateo Cabral');
    });

    test('Concierto: Timestamp, DateTime e ISO en fecha; id opcional', () {
      final fecha = DateTime(2026, 12, 5);
      final c = Concierto(
        nombre: 'En vivo',
        lugar: 'Teatro',
        fecha: fecha,
        precio: 15000,
        disponibles: 120,
      );
      expect(c.id, ''); // default: sin asignar
      final map = c.toMap();
      expect(map['fecha'], isA<Timestamp>());

      // Timestamp (Firestore real)
      expect(Concierto.fromMap(map).fecha, fecha);
      // DateTime (fake en memoria)
      expect(Concierto.fromMap({...map, 'fecha': fecha}).fecha, fecha);
      // String ISO (fake)
      expect(
        Concierto.fromMap({...map, 'fecha': fecha.toIso8601String()}).fecha,
        fecha,
      );
      // id por parámetro gana sobre el del mapa
      final conId = Concierto.fromMap({
        ...map,
        'id': 'otro',
      }, id: 'concierto-1');
      expect(conId.id, 'concierto-1');
      // conDisponibles conserva el id
      expect(conId.conDisponibles(5).id, 'concierto-1');
      expect(conId.conDisponibles(5).disponibles, 5);
    });

    test('Entrada: ida y vuelta con fecha Timestamp', () {
      final e = Entrada(
        concierto: 'En vivo',
        lugar: 'Teatro',
        fecha: DateTime(2026, 12, 5),
        precio: 15000,
        cantidad: 2,
      );
      final deVuelta = Entrada.fromMap(e.toMap(), id: 'entrada-1');
      expect(deVuelta.id, 'entrada-1');
      expect(deVuelta.cantidad, 2);
      expect(deVuelta.precio, 15000);
      expect(deVuelta.fecha, DateTime(2026, 12, 5));
    });

    test('Movimiento: enum como String, fecha Timestamp, monto num', () {
      final m = Movimiento(
        tipo: TipoMovimiento.donacion,
        detalle: 'Donación de un fan',
        monto: 5000,
        fecha: DateTime(2026, 11, 4),
      );
      final map = m.toMap();
      expect(map['tipo'], 'donacion');
      final deVuelta = Movimiento.fromMap(map, id: 'movimiento-1');
      expect(deVuelta.tipo, TipoMovimiento.donacion);
      expect(deVuelta.id, 'movimiento-1');
      expect(deVuelta.monto, 5000);
      // monto como int (num) también se acepta
      expect(Movimiento.fromMap({...map, 'monto': 5000}).monto, 5000.0);
    });

    test(
      'fromMap lanza FormatException ante datos inválidos (sin inventar)',
      () {
        final base = _cancionPrueba('c1').toMap();
        expect(
          () => Cancion.fromMap(base),
          throwsA(isA<FormatException>()),
        ); // sin id
        expect(
          () => Cancion.fromMap({...base, 'titulo': 42}, id: 'c1'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Cancion.fromMap({...base, 'colorPortada': 'rojo'}, id: 'c1'),
          throwsA(isA<FormatException>()),
        );
        final cBase = Concierto(
          nombre: 'x',
          lugar: 'y',
          fecha: DateTime(2026, 1, 1),
          precio: 1,
          disponibles: 1,
        ).toMap();
        expect(
          () => Concierto.fromMap({...cBase, 'fecha': 123}),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => Concierto.fromMap({...cBase, 'fecha': 'no-es-fecha'}),
          throwsA(isA<FormatException>()),
        );
        final mBase = Movimiento(
          tipo: TipoMovimiento.venta,
          detalle: 'd',
          monto: 1,
          fecha: DateTime(2026, 1, 1),
        ).toMap();
        expect(
          () => Movimiento.fromMap({...mBase, 'tipo': 'magia'}),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('6.3 semilla idempotente', () {
    test(
      'puebla colecciones vacías con ids determinísticos (17 docs)',
      () async {
        final fuente = FakeFuenteFirestore();
        final r = await poblarSemillaSiVacia(fuente);
        expect(r.escritosPorColeccion, {
          'canciones': 4,
          'albumes': 2,
          'artistas': 1,
          'conciertos': 4,
          'entradas': 3,
          'movimientos': 3,
        });
        expect(r.total, 17);
        expect(await fuente.contar('canciones'), 4);
        expect(
          await fuente.existeDocumento('canciones', 'luces-de-la-ciudad'),
          isTrue,
        );
        expect(
          await fuente.existeDocumento('artistas', 'mateo-cabral'),
          isTrue,
        );
        expect(
          await fuente.existeDocumento('conciertos', 'concierto-1'),
          isTrue,
        );
        expect(
          await fuente.existeDocumento('movimientos', 'movimiento-3'),
          isTrue,
        );
      },
    );

    test('es idempotente: segunda corrida no escribe ni pisa nada', () async {
      final fuente = FakeFuenteFirestore();
      await poblarSemillaSiVacia(fuente);
      final antes = Map.of(fuente.docs['canciones']!);
      final r2 = await poblarSemillaSiVacia(fuente);
      expect(r2.escritosPorColeccion, isEmpty);
      expect(r2.total, 0);
      expect(fuente.docs['canciones'], antes); // mismos datos, sin cambios
      expect(await fuente.contar('canciones'), 4);
    });

    test('no toca colecciones que ya tienen documentos', () async {
      final fuente = FakeFuenteFirestore();
      await fuente.setDocumento('artistas', 'otro', {'nombre': 'Otro'});
      final r = await poblarSemillaSiVacia(fuente);
      expect(r.escritosPorColeccion['artistas'], isNull); // no se sembró
      expect(await fuente.contar('artistas'), 1);
      expect(fuente.docs['artistas']!['otro']!['nombre'], 'Otro'); // intacto
      expect(r.escritosPorColeccion['canciones'], 4); // las demás sí
    });

    test(
      'ejecuciones concurrentes no duplican (mismos ids determinísticos)',
      () async {
        final fuente = FakeFuenteFirestore();
        await Future.wait([
          poblarSemillaSiVacia(fuente),
          poblarSemillaSiVacia(fuente),
          poblarSemillaSiVacia(fuente),
        ]);
        expect(await fuente.contar('canciones'), 4);
        expect(await fuente.contar('conciertos'), 4);
        expect(await fuente.contar('movimientos'), 3);
      },
    );
  });

  group('6.4 repositorios Firestore en tiempo real', () {
    test('catalogo: snapshot actualiza caché y notifica; sin cambio no; '
        'error conserva caché; dispose cancela', () async {
      final fuente = FakeFuenteFirestore();
      final repo = RepositorioCatalogoFirestore(fuente: fuente);
      var notificaciones = 0;
      repo.addListener(() => notificaciones++);

      await pumpEventQueue();
      expect(repo.canciones, isEmpty); // antes del primer snapshot: vacío
      expect(repo.albumes, isEmpty);
      expect(notificaciones, 0); // snapshot inicial vacío = caché vacía

      // alta vía contrato (escritura) -> el fake emite snapshot -> caché
      repo.agregarCanciones([_cancionPrueba('c1')]);
      await pumpEventQueue();
      expect(await fuente.contar('canciones'), 1);
      expect(repo.canciones.length, 1);
      expect(repo.canciones.first.id, 'c1');
      expect(repo.canciones.first.titulo, 'Tema c1');
      expect(notificaciones, 1);

      // snapshot idéntico: distinct filtra, no hay notificación redundante
      fuente.emitir('canciones');
      await pumpEventQueue();
      expect(notificaciones, 1);

      // error del stream: se registra, se conserva la caché, no notifica
      fuente.fallar('canciones', StateError('sin red'));
      await pumpEventQueue();
      expect(repo.ultimoError, isA<StateError>());
      expect(repo.canciones.length, 1);
      expect(notificaciones, 1);

      // dispose: cancela suscripciones (hay que esperar el cancel async)
      repo.dispose();
      await repo.cerrar();
      expect(fuente.ctrl('canciones').hasListener, isFalse);
      expect(fuente.ctrl('albumes').hasListener, isFalse);

      // después de dispose no llega nada más
      await fuente.setDocumento(
        'canciones',
        'c2',
        _cancionPrueba('c2').toMap(),
      );
      await pumpEventQueue();
      expect(repo.canciones.length, 1);
      expect(notificaciones, 1);
    });

    test('artistas: snapshot puebla todos/porId; dispose cancela', () async {
      final fuente = FakeFuenteFirestore();
      final repo = RepositorioArtistasFirestore(fuente: fuente);
      var notificaciones = 0;
      repo.addListener(() => notificaciones++);

      await pumpEventQueue();
      expect(repo.todos, isEmpty);
      expect(repo.porId('mateo-cabral'), isNull);

      await fuente.setDocumento('artistas', 'mateo-cabral', {
        'nombre': 'Mateo Cabral',
      });
      await pumpEventQueue();
      expect(repo.todos.length, 1);
      expect(repo.porId('mateo-cabral')?.nombre, 'Mateo Cabral');
      expect(notificaciones, 1);

      repo.dispose();
      await repo.cerrar();
      expect(fuente.ctrl('artistas').hasListener, isFalse);

      await fuente.setDocumento('artistas', 'otro', {'nombre': 'Otro'});
      await pumpEventQueue();
      expect(repo.todos.length, 1); // no recibió nada tras dispose
      expect(notificaciones, 1);
    });
  });
}
