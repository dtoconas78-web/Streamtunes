import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_entradas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos_firestore.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';

// Fake en memoria de FuenteFirestore con control de concurrencia OPTIMISTA
// real (sin resultados predeterminados):
// - Almacena documentos y les asigna una versión por documento que sube en
//   cada escritura.
// - Las lecturas dentro de una transacción registran la versión observada.
// - En el commit se detecta conflicto si alguna versión observada ya no es
//   la actual; en ese caso NO se aplica nada y el callback se reejecuta
//   automáticamente (reintento) con lecturas frescas.
// - Las escrituras se bufferizan y se aplican todas juntas (atómicamente) sólo
//   cuando el commit es válido.
// - Si el callback lanza una excepción, no se aplica ninguna escritura
//   (rollback completo: no hay escrituras parciales).
class FakeFuenteFirestore implements FuenteFirestore, GeneradorIdsFirestore {
  final Map<String, Map<String, Map<String, dynamic>>> docs = {};
  final Map<String, Map<String, int>> _versiones = {};
  final Map<String, StreamController<List<DocumentoFirestore>>> _ctrl = {};
  int _autoId = 0;

  // Contadores de instrumentación para las pruebas.
  int llamadasGenerarId = 0;
  int llamadasRunTransaction = 0;
  int conflictosDetectados = 0;
  int reintentos = 0;

  static const int _maxReintentos = 25;

  Map<String, Map<String, dynamic>> col(String coleccion) =>
      docs.putIfAbsent(coleccion, () => {});

  Map<String, int> vers(String coleccion) =>
      _versiones.putIfAbsent(coleccion, () => {});

  int versionDe(String coleccion, String id) => vers(coleccion)[id] ?? 0;

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
    vers(coleccion)[id] = versionDe(coleccion, id) + 1;
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
  String generarId(String coleccion) {
    llamadasGenerarId++;
    return 'auto-${++_autoId}';
  }

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(TransaccionFirestore txn) actualizar,
  ) async {
    llamadasRunTransaction++;
    var intento = 0;
    while (true) {
      intento++;
      if (intento > _maxReintentos) {
        throw StateError('runTransaction: demasiados reintentos ($intento)');
      }
      final txn = _TxnFake(this);
      final T resultado;
      try {
        resultado = await actualizar(txn);
      } catch (_) {
        // Rollback: las escrituras quedaron sólo en el buffer de la txn y
        // nunca se aplicaron; no hay escrituras parciales.
        rethrow;
      }
      // Detección de conflicto optimista: ¿alguna lectura quedó desactualizada?
      final hayConflicto = txn.lecturas.entries.any((lectura) {
        final partes = lectura.key.split('/');
        return versionDe(partes[0], partes[1]) != lectura.value;
      });
      if (hayConflicto) {
        conflictosDetectados++;
        reintentos++;
        continue; // reejecuta el callback con lecturas frescas
      }
      // Commit atómico: todas las escrituras bufferizadas se aplican juntas.
      final coleccionesTocadas = <String>{};
      for (final w in txn.escrituras) {
        col(w.coleccion)[w.id] = Map<String, dynamic>.from(w.datos);
        vers(w.coleccion)[w.id] = versionDe(w.coleccion, w.id) + 1;
        coleccionesTocadas.add(w.coleccion);
      }
      for (final c in coleccionesTocadas) {
        emitir(c);
      }
      return resultado;
    }
  }
}

class _EscrituraFake {
  _EscrituraFake(this.coleccion, this.id, this.datos);
  final String coleccion;
  final String id;
  final Map<String, dynamic> datos;
}

class _TxnFake implements TransaccionFirestore {
  _TxnFake(this._fuente);

  final FakeFuenteFirestore _fuente;

  // 'coleccion/id' -> versión observada en la lectura.
  final Map<String, int> lecturas = {};
  final List<_EscrituraFake> escrituras = [];

  @override
  Future<DocumentoFirestore?> leer(String coleccion, String id) async {
    lecturas['$coleccion/$id'] = _fuente.versionDe(coleccion, id);
    final datos = _fuente.col(coleccion)[id];
    return datos == null ? null : DocumentoFirestore(id: id, datos: datos);
  }

  @override
  void set(String coleccion, String id, Map<String, dynamic> datos) {
    escrituras.add(_EscrituraFake(coleccion, id, datos));
  }
}

/// Implementación que declara SOLO `FuenteFirestore` (como el fake preexistente
/// del Bloque A): no declara `GeneradorIdsFirestore`, así que el despacho
/// dinámico de la extensión debe usar el generador de respaldo.
class _FuenteSoloContrato implements FuenteFirestore {
  @override
  Stream<List<DocumentoFirestore>> snapshotsColeccion(String coleccion) =>
      Stream.empty();

  @override
  Future<int> contar(String coleccion) async => 0;

  @override
  Future<bool> existeDocumento(String coleccion, String id) async => false;

  @override
  Future<void> setDocumento(
    String coleccion,
    String id,
    Map<String, dynamic> datos,
  ) async {}

  @override
  Future<String> agregarDocumento(
    String coleccion,
    Map<String, dynamic> datos,
  ) async => 'doc';

  @override
  Future<T> runTransaction<T>(
    Future<T> Function(TransaccionFirestore txn) actualizar,
  ) async => throw UnimplementedError('sin transacciones en este fake mínimo');
}

// ---- Espías y helpers para las pruebas de flujo (13.2-13.6) ----

/// Cuenta si el flujo en memoria llegó a ejecutar el camino transaccional
/// async (no debe ocurrir cuando soportaCompraAtomica == false).
class _MemoriaEspia extends RepositorioEntradasMemoria {
  _MemoriaEspia({super.conciertos, super.entradas});

  int llamadasDescontarAsync = 0;

  @override
  Future<bool> descontarDisponiblesAsync(
    String conciertoId,
    int cantidad, {
    Entrada? entradaGenerada,
    Movimiento? movimientoGenerado,
    String? operacionId,
  }) async {
    llamadasDescontarAsync++;
    return super.descontarDisponiblesAsync(
      conciertoId,
      cantidad,
      entradaGenerada: entradaGenerada,
      movimientoGenerado: movimientoGenerado,
      operacionId: operacionId,
    );
  }
}

/// Cuenta si el flujo Firestore llegó a usar el descuento SÍNC (no debe
/// ocurrir en una compra atómica: el descuento real va dentro de la txn).
class _FirestoreEntradasEspia extends RepositorioEntradasFirestore {
  _FirestoreEntradasEspia({required super.fuente, super.uidActual});

  int llamadasDescontarSync = 0;

  @override
  bool descontarDisponibles(Concierto concierto, int cantidad) {
    llamadasDescontarSync++;
    return super.descontarDisponibles(concierto, cantidad);
  }
}

/// Cuenta si el movimiento de una compra Firestore se escribió por una ruta
/// independiente (no debe ocurrir: el movimiento se crea dentro de la txn).
class _FirestoreMovimientosEspia extends RepositorioMovimientosFirestore {
  _FirestoreMovimientosEspia({required super.fuente, super.uidActual});

  int llamadasRegistrar = 0;

  @override
  void registrar(Movimiento movimiento) {
    llamadasRegistrar++;
    super.registrar(movimiento);
  }
}

final _fechaConcierto = DateTime(2026, 12, 24, 20, 0);
final _fechaMovimiento = DateTime(2026, 11, 20, 12, 0);

Map<String, dynamic> _conciertoMap({int disponibles = 5}) => {
  'nombre': 'Show de Prueba',
  'lugar': 'Arena Central',
  'fecha': _fechaConcierto.toIso8601String(),
  'precio': 1000.0,
  'disponibles': disponibles,
};

Concierto _concierto({String id = 'c1', int disponibles = 5}) => Concierto(
  id: id,
  nombre: 'Show de Prueba',
  lugar: 'Arena Central',
  fecha: _fechaConcierto,
  precio: 1000,
  disponibles: disponibles,
);

Entrada _entrada({String conciertoId = 'c1', String usuarioId = 'uid-1'}) =>
    Entrada(
      concierto: 'Show de Prueba',
      conciertoId: conciertoId,
      lugar: 'Arena Central',
      fecha: _fechaConcierto,
      precio: 1000,
      cantidad: 2,
      usuarioId: usuarioId,
    );

Movimiento _movimiento({String usuarioId = 'uid-1'}) => Movimiento(
  tipo: TipoMovimiento.venta,
  detalle: 'Show de Prueba x2',
  monto: 2000,
  fecha: _fechaMovimiento,
  usuarioId: usuarioId,
);

void main() {
  group('13.1 capacidad de compra atómica', () {
    test(
      'RepositorioEntradasMemoria informa soportaCompraAtomica == false',
      () {
        final repo = RepositorioEntradasMemoria(conciertos: [], entradas: []);
        expect(repo.soportaCompraAtomica, isFalse);
        repo.dispose();
      },
    );

    test(
      'RepositorioEntradasFirestore informa soportaCompraAtomica == true',
      () async {
        final fuente = FakeFuenteFirestore();
        final repo = RepositorioEntradasFirestore(
          fuente: fuente,
          uidActual: () => 'uid-1',
        );
        expect(repo.soportaCompraAtomica, isTrue);
        await repo.cerrar();
        repo.dispose();
      },
    );
  });

  group('13.2 flujo en memoria vía comprarAsync', () {
    test(
      'soportaCompraAtomica == false -> delega en comprar: descuenta stock, '
      'registra 1 entrada y 1 movimiento, sin ejecutar la vía transaccional',
      () async {
        final concierto = _concierto(disponibles: 5);
        final repoE = _MemoriaEspia(conciertos: [concierto], entradas: []);
        final repoM = RepositorioMovimientosMemoria(movimientos: []);
        final vm = EntradasViewModel(
          repositorioEntradas: repoE,
          repositorioMovimientos: repoM,
          reloj: RelojFijo(_fechaMovimiento),
          uidActual: () => 'uid-1',
        );
        // La bifurcación es por la capacidad declarada, no por el tipo.
        expect(repoE.soportaCompraAtomica, isFalse);

        final ok = await vm.comprarAsync(concierto, 2);
        expect(ok, isTrue);
        expect(repoE.conciertosDisponibles.single.disponibles, 3);
        expect(repoE.entradasCompradas, hasLength(1));
        expect(repoE.entradasCompradas.single.cantidad, 2);
        expect(repoM.movimientos, hasLength(1));
        expect(repoM.movimientos.single.tipo, TipoMovimiento.venta);
        expect(repoM.movimientos.single.monto, 2000);
        // No se ejecutó el camino transaccional async.
        expect(repoE.llamadasDescontarAsync, 0);

        // Compra rechazada por stock insuficiente (4 > 3 restantes): no
        // agrega entrada ni movimiento ni toca el stock.
        final ok2 = await vm.comprarAsync(_concierto(disponibles: 5), 4);
        expect(ok2, isFalse);
        expect(repoE.conciertosDisponibles.single.disponibles, 3);
        expect(repoE.entradasCompradas, hasLength(1));
        expect(repoM.movimientos, hasLength(1));
        expect(repoE.llamadasDescontarAsync, 0);

        vm.dispose();
        repoE.dispose();
        repoM.dispose();
      },
    );
  });

  group('13.3 flujo Firestore vía comprarAsync', () {
    test('soportaCompraAtomica == true -> una única transacción; no llama a '
        'comprar ni registra el movimiento aparte', () async {
      final fuente = FakeFuenteFirestore();
      await fuente.setDocumento('conciertos', 'c1', _conciertoMap());
      final repoE = _FirestoreEntradasEspia(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      final repoM = _FirestoreMovimientosEspia(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      final vm = EntradasViewModel(
        repositorioEntradas: repoE,
        repositorioMovimientos: repoM,
        reloj: RelojFijo(_fechaMovimiento),
        uidActual: () => 'uid-1',
      );
      expect(repoE.soportaCompraAtomica, isTrue);

      final ok = await vm.comprarAsync(_concierto(), 2);
      expect(ok, isTrue);
      // Exactamente UNA operación transaccional.
      expect(fuente.llamadasRunTransaction, 1);
      // No pasó por el flujo sync de descuento ni por registrar aparte.
      expect(repoE.llamadasDescontarSync, 0);
      expect(repoM.llamadasRegistrar, 0);
      // Los tres documentos quedaron escritos.
      expect(fuente.col('conciertos')['c1']!['disponibles'], 3);
      expect(fuente.col('entradas'), hasLength(1));
      expect(fuente.col('movimientos'), hasLength(1));
      final entradaDoc = fuente.col('entradas').values.single;
      expect(entradaDoc['usuarioId'], 'uid-1');
      expect(entradaDoc['conciertoId'], 'c1');
      expect(entradaDoc['cantidad'], 2);
      final movDoc = fuente.col('movimientos').values.single;
      expect(movDoc['usuarioId'], 'uid-1');
      expect(movDoc['tipo'], 'venta');
      expect(movDoc['monto'], 2000);

      // Las cachés del repo se actualizan vía snapshots.
      await pumpEventQueue();
      expect(repoE.conciertosDisponibles.single.disponibles, 3);
      expect(repoE.entradasCompradas, hasLength(1));
      expect(repoE.entradasCompradas.single.usuarioId, 'uid-1');
      expect(repoE.entradasCompradas.single.conciertoId, 'c1');

      // Compra rechazada por stock insuficiente: otra txn, sin nuevos docs.
      final ok2 = await vm.comprarAsync(_concierto(disponibles: 5), 4);
      expect(ok2, isFalse);
      expect(fuente.llamadasRunTransaction, 2);
      expect(fuente.col('conciertos')['c1']!['disponibles'], 3);
      expect(fuente.col('entradas'), hasLength(1));
      expect(fuente.col('movimientos'), hasLength(1));
      expect(repoE.llamadasDescontarSync, 0);
      expect(repoM.llamadasRegistrar, 0);

      vm.dispose();
      await repoE.cerrar();
      repoE.dispose();
      await repoM.cerrar();
      repoM.dispose();
    });
  });

  group('13.4 atomicidad y rollback', () {
    late FakeFuenteFirestore fuente;
    late RepositorioEntradasFirestore repo;

    setUp(() async {
      fuente = FakeFuenteFirestore();
      await fuente.setDocumento('conciertos', 'c1', _conciertoMap());
      repo = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
    });

    tearDown(() async {
      await repo.cerrar();
      repo.dispose();
    });

    void expectSinEscrituras({int disponiblesEsperados = 5}) {
      expect(
        fuente.col('conciertos')['c1']!['disponibles'],
        disponiblesEsperados,
      );
      expect(fuente.col('entradas'), isEmpty);
      expect(fuente.col('movimientos'), isEmpty);
    }

    test(
      'compra válida escribe stock + entrada + movimiento en un commit',
      () async {
        final ok = await repo.descontarDisponiblesAsync(
          'c1',
          2,
          entradaGenerada: _entrada(),
          movimientoGenerado: _movimiento(),
        );
        expect(ok, isTrue);
        expect(fuente.llamadasRunTransaction, 1);
        expect(fuente.col('conciertos')['c1']!['disponibles'], 3);
        expect(fuente.col('entradas'), hasLength(1));
        expect(fuente.col('movimientos'), hasLength(1));
        final e = fuente.col('entradas').values.single;
        expect(e['usuarioId'], 'uid-1');
        expect(e['conciertoId'], 'c1');
        expect(e['cantidad'], 2);
        expect(e['concierto'], 'Show de Prueba');
        final m = fuente.col('movimientos').values.single;
        expect(m['usuarioId'], 'uid-1');
        expect(m['tipo'], 'venta');
        expect(m['monto'], 2000);
      },
    );

    test('concierto inexistente: false sin escrituras parciales', () async {
      final ok = await repo.descontarDisponiblesAsync(
        'no-existe',
        1,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
      );
      expect(ok, isFalse);
      expectSinEscrituras();
    });

    test('stock insuficiente: false sin escrituras parciales', () async {
      final ok = await repo.descontarDisponiblesAsync(
        'c1',
        6,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
      );
      expect(ok, isFalse);
      expectSinEscrituras();
    });

    test('cantidad <= 0: false sin ejecutar transacción ni escribir', () async {
      for (final cantidad in [0, -3]) {
        final ok = await repo.descontarDisponiblesAsync(
          'c1',
          cantidad,
          entradaGenerada: _entrada(),
          movimientoGenerado: _movimiento(),
        );
        expect(ok, isFalse);
      }
      expect(fuente.llamadasRunTransaction, 0);
      expectSinEscrituras();
    });

    test('entradaGenerada == null: false antes de escribir', () async {
      final ok = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        movimientoGenerado: _movimiento(),
      );
      expect(ok, isFalse);
      expect(fuente.llamadasRunTransaction, 0);
      expectSinEscrituras();
    });

    test('movimientoGenerado == null: false antes de escribir', () async {
      final ok = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: _entrada(),
      );
      expect(ok, isFalse);
      expect(fuente.llamadasRunTransaction, 0);
      expectSinEscrituras();
    });

    test('sin sesión válida (uid null): false sin escrituras', () async {
      final repoSinSesion = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => null,
      );
      final ok = await repoSinSesion.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
      );
      expect(ok, isFalse);
      expect(repoSinSesion.ultimoError, isNotNull);
      expect(fuente.llamadasRunTransaction, 0);
      expectSinEscrituras();
      await repoSinSesion.cerrar();
      repoSinSesion.dispose();
    });
  });

  group('13.5 carrera concurrente real (stock 1)', () {
    test(
      'ambas operaciones leen la misma versión inicial; una confirma, la otra '
      'detecta el conflicto, reintenta, encuentra stock 0 y retorna false',
      () async {
        final fuente = FakeFuenteFirestore();
        await fuente.setDocumento(
          'conciertos',
          'c1',
          _conciertoMap(disponibles: 1),
        );
        final repo = RepositorioEntradasFirestore(
          fuente: fuente,
          uidActual: () => 'uid-1',
        );

        Future<bool> compra() => repo.descontarDisponiblesAsync(
          'c1',
          1,
          entradaGenerada: _entrada(),
          movimientoGenerado: _movimiento(),
        );

        // Determinista: ambas llamadas se ejecutan sincrónicamente hasta su
        // primera lectura dentro de la txn, así las dos registran la MISMA
        // versión del concierto antes de cualquier commit.
        final resultados = await Future.wait([compra(), compra()]);

        // Exactamente una compra exitosa y una rechazada.
        expect(resultados.where((r) => r), hasLength(1));
        expect(resultados.where((r) => !r), hasLength(1));
        // La que perdió detectó el conflicto de versión y reintentó.
        expect(fuente.conflictosDetectados, greaterThanOrEqualTo(1));
        expect(fuente.reintentos, greaterThanOrEqualTo(1));
        // Estado final: stock 0 (nunca negativo), 1 entrada, 1 movimiento,
        // sin escrituras parciales.
        expect(fuente.col('conciertos')['c1']!['disponibles'], 0);
        expect(fuente.col('entradas'), hasLength(1));
        expect(fuente.col('movimientos'), hasLength(1));
        // 2 ids por operación (entrada + movimiento), generados ANTES de la
        // transacción: 4 en total y no aumentan con el reintento.
        expect(fuente.llamadasGenerarId, 4);
        // La operación que reintentó corrió el callback 2 veces.
        expect(fuente.llamadasRunTransaction, greaterThanOrEqualTo(2));

        await repo.cerrar();
        repo.dispose();
      },
    );
  });

  group('13.6 ids estables e idempotencia', () {
    late FakeFuenteFirestore fuente;
    late RepositorioEntradasFirestore repo;

    setUp(() async {
      fuente = FakeFuenteFirestore();
      await fuente.setDocumento('conciertos', 'c1', _conciertoMap());
      repo = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
    });

    tearDown(() async {
      await repo.cerrar();
      repo.dispose();
    });

    test('con operacionId los documentos usan la convención real '
        'entrada-<op> / movimiento-<op> y no se llama generarId', () async {
      final ok = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
        operacionId: 'op-x',
      );
      expect(ok, isTrue);
      expect(fuente.llamadasGenerarId, 0);
      expect(await fuente.existeDocumento('entradas', 'entrada-op-x'), isTrue);
      expect(
        await fuente.existeDocumento('movimientos', 'movimiento-op-x'),
        isTrue,
      );
      expect(fuente.col('conciertos')['c1']!['disponibles'], 3);
      expect(fuente.col('entradas'), hasLength(1));
      expect(fuente.col('movimientos'), hasLength(1));
    });

    test('repetir el mismo operacionId no descuenta ni duplica nada', () async {
      final args = {
        'entradaGenerada': _entrada(),
        'movimientoGenerado': _movimiento(),
        'operacionId': 'op-x',
      };
      final primera = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: args['entradaGenerada'] as Entrada,
        movimientoGenerado: args['movimientoGenerado'] as Movimiento,
        operacionId: args['operacionId'] as String,
      );
      expect(primera, isTrue);
      expect(fuente.col('conciertos')['c1']!['disponibles'], 3);

      // Misma operación repetida: se reconoce como ya procesada.
      final repetida = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
        operacionId: 'op-x',
      );
      expect(repetida, isTrue);
      expect(fuente.col('conciertos')['c1']!['disponibles'], 3);
      expect(fuente.col('entradas'), hasLength(1));
      expect(fuente.col('movimientos'), hasLength(1));
      expect(await fuente.existeDocumento('entradas', 'entrada-op-x'), isTrue);
      expect(
        await fuente.existeDocumento('movimientos', 'movimiento-op-x'),
        isTrue,
      );
    });

    test('estado inconsistente (existe sólo la entrada de la operación): '
        'rechaza sin escrituras adicionales', () async {
      await fuente.setDocumento('entradas', 'entrada-op-y', _entrada().toMap());
      final ok = await repo.descontarDisponiblesAsync(
        'c1',
        2,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
        operacionId: 'op-y',
      );
      expect(ok, isFalse);
      // No se descontó stock ni se creó el movimiento huérfano.
      expect(fuente.col('conciertos')['c1']!['disponibles'], 5);
      expect(fuente.col('entradas'), hasLength(1)); // sólo la preexistente
      expect(fuente.col('movimientos'), isEmpty);
      expect(
        await fuente.existeDocumento('movimientos', 'movimiento-op-y'),
        isFalse,
      );
    });

    test('los ids generados antes de la transacción permanecen estables ante '
        'un reintento por conflicto', () async {
      await fuente.setDocumento(
        'conciertos',
        'c1',
        _conciertoMap(disponibles: 1),
      );
      Future<bool> compra() => repo.descontarDisponiblesAsync(
        'c1',
        1,
        entradaGenerada: _entrada(),
        movimientoGenerado: _movimiento(),
      );
      final resultados = await Future.wait([compra(), compra()]);
      expect(resultados.where((r) => r), hasLength(1));
      // 2 ids por operación, generados una sola vez antes de runTransaction:
      // el reintento del callback NO vuelve a generar ids.
      expect(fuente.llamadasGenerarId, 4);
      expect(fuente.reintentos, greaterThanOrEqualTo(1));
      // La entrada y el movimiento escritos usan ids autogenerados previos.
      expect(fuente.col('entradas').keys.single, startsWith('auto-'));
      expect(fuente.col('movimientos').keys.single, startsWith('auto-'));
      expect(fuente.col('conciertos')['c1']!['disponibles'], 0);
    });
  });

  group('13.7 streams, filtrado por usuario y cierre', () {
    test('emite conciertos (todos), entradas y movimientos filtrados por '
        'usuarioId, y se actualiza con los snapshots', () async {
      final fuente = FakeFuenteFirestore();
      await fuente.setDocumento('conciertos', 'c1', _conciertoMap());
      await fuente.setDocumento('conciertos', 'c2', _conciertoMap());
      await fuente.setDocumento(
        'entradas',
        'e1',
        _entrada(usuarioId: 'uid-1').toMap(),
      );
      await fuente.setDocumento(
        'entradas',
        'e2',
        _entrada(usuarioId: 'otro').toMap(),
      );
      await fuente.setDocumento(
        'movimientos',
        'm1',
        _movimiento(usuarioId: 'uid-1').toMap(),
      );
      await fuente.setDocumento(
        'movimientos',
        'm2',
        _movimiento(usuarioId: 'otro').toMap(),
      );

      final repoE = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      final repoM = RepositorioMovimientosFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      await pumpEventQueue();

      // Conciertos: todos. Entradas/movimientos: sólo del usuario activo.
      expect(repoE.conciertosDisponibles, hasLength(2));
      expect(repoE.entradasCompradas, hasLength(1));
      expect(repoE.entradasCompradas.single.id, 'e1');
      expect(repoM.movimientos, hasLength(1));
      expect(repoM.movimientos.single.id, 'm1');

      // Reactividad: un cambio en el snapshot actualiza los datos.
      await fuente.setDocumento(
        'conciertos',
        'c1',
        _conciertoMap(disponibles: 1),
      );
      await pumpEventQueue();
      expect(
        repoE.conciertosDisponibles
            .singleWhere((c) => c.id == 'c1')
            .disponibles,
        1,
      );

      // Otro usuario ve únicamente sus propios registros.
      final repoOtro = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => 'otro',
      );
      await pumpEventQueue();
      expect(repoOtro.entradasCompradas, hasLength(1));
      expect(repoOtro.entradasCompradas.single.id, 'e2');

      await repoE.cerrar();
      repoE.dispose();
      await repoM.cerrar();
      repoM.dispose();
      await repoOtro.cerrar();
      repoOtro.dispose();
    });

    test('sin sesión válida (uid null o vacío) las listas quedan vacías y '
        'nunca se exponen datos de otros usuarios', () async {
      final fuente = FakeFuenteFirestore();
      await fuente.setDocumento(
        'entradas',
        'e1',
        _entrada(usuarioId: 'uid-1').toMap(),
      );
      await fuente.setDocumento(
        'movimientos',
        'm1',
        _movimiento(usuarioId: 'uid-1').toMap(),
      );
      for (final uid in <String?>[null, '']) {
        final repoE = RepositorioEntradasFirestore(
          fuente: fuente,
          uidActual: () => uid,
        );
        final repoM = RepositorioMovimientosFirestore(
          fuente: fuente,
          uidActual: () => uid,
        );
        await pumpEventQueue();
        expect(repoE.entradasCompradas, isEmpty);
        expect(repoM.movimientos, isEmpty);
        await repoE.cerrar();
        repoE.dispose();
        await repoM.cerrar();
        repoM.dispose();
      }
    });

    test(
      'snapshots idénticos no producen notificaciones redundantes',
      () async {
        final fuente = FakeFuenteFirestore();
        await fuente.setDocumento('entradas', 'e1', _entrada().toMap());
        final repo = RepositorioEntradasFirestore(
          fuente: fuente,
          uidActual: () => 'uid-1',
        );
        await pumpEventQueue();
        var notificaciones = 0;
        repo.addListener(() => notificaciones++);
        final base = notificaciones; // la emisión inicial ya se entregó

        fuente.emitir('entradas'); // mismo contenido: no debe notificar
        await pumpEventQueue();
        expect(notificaciones, base);

        await fuente.setDocumento('entradas', 'e2', _entrada().toMap());
        await pumpEventQueue();
        expect(notificaciones, base + 1); // cambio real: notifica una vez

        await repo.cerrar();
        repo.dispose();
      },
    );

    test('ante error del stream conserva la última caché válida y registra '
        'ultimoError; el stream sigue vivo', () async {
      final fuente = FakeFuenteFirestore();
      await fuente.setDocumento('movimientos', 'm1', _movimiento().toMap());
      final repo = RepositorioMovimientosFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      await pumpEventQueue();
      expect(repo.movimientos, hasLength(1));

      fuente.fallar('movimientos', StateError('sin conexión'));
      await pumpEventQueue();
      expect(repo.ultimoError, isA<StateError>());
      expect(repo.movimientos, hasLength(1)); // caché conservada

      await fuente.setDocumento('movimientos', 'm2', _movimiento().toMap());
      await pumpEventQueue();
      expect(repo.movimientos, hasLength(2)); // recuperación

      await repo.cerrar();
      repo.dispose();
    });

    test('await cerrar() cancela las suscripciones de cada repositorio '
        '(el fake queda sin listeners)', () async {
      final fuente = FakeFuenteFirestore();
      final repoE = RepositorioEntradasFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      final repoM = RepositorioMovimientosFirestore(
        fuente: fuente,
        uidActual: () => 'uid-1',
      );
      await pumpEventQueue();
      expect(fuente.ctrl('conciertos').hasListener, isTrue);
      expect(fuente.ctrl('entradas').hasListener, isTrue);
      expect(fuente.ctrl('movimientos').hasListener, isTrue);

      await repoE.cerrar();
      await repoM.cerrar();
      repoE.dispose();
      repoM.dispose();

      expect(fuente.ctrl('conciertos').hasListener, isFalse);
      expect(fuente.ctrl('entradas').hasListener, isFalse);
      expect(fuente.ctrl('movimientos').hasListener, isFalse);
    });
  });

  group('13.8 modelos Entrada y Movimiento', () {
    test(
      'Entrada: round-trip toMap/fromMap conserva usuarioId y conciertoId',
      () {
        final e = _entrada(usuarioId: 'uid-9');
        final map = e.toMap();
        expect(map['usuarioId'], 'uid-9');
        expect(map['conciertoId'], 'c1');
        final e2 = Entrada.fromMap(map);
        expect(e2, e);
        expect(e2.hashCode, e.hashCode);
      },
    );

    test('Entrada: documento antiguo sin usuarioId/conciertoId usa ""', () {
      final viejo = {
        'concierto': 'Show Viejo',
        'lugar': 'Teatro',
        'fecha': _fechaConcierto.toIso8601String(),
        'precio': 500.0,
        'cantidad': 1,
      };
      final e = Entrada.fromMap(viejo, id: 'e-vieja');
      expect(e.usuarioId, '');
      expect(e.conciertoId, '');
      expect(e.id, 'e-vieja');
      expect(e.concierto, 'Show Viejo');
      expect(e.cantidad, 1);
    });

    test(
      'Entrada: igualdad por valor; instancias distintas no son iguales',
      () {
        final a = _entrada();
        final b = _entrada();
        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a == _entrada(usuarioId: 'otro'), isFalse);
      },
    );

    test('Movimiento: round-trip conserva usuarioId; doc antiguo usa ""', () {
      final m = _movimiento(usuarioId: 'uid-9');
      final map = m.toMap();
      expect(map['usuarioId'], 'uid-9');
      expect(map['tipo'], 'venta');
      final m2 = Movimiento.fromMap(map);
      expect(m2, m);
      expect(m2.hashCode, m.hashCode);

      final viejo = {
        'tipo': 'donacion',
        'detalle': 'Donación',
        'monto': 100.0,
        'fecha': _fechaMovimiento.toIso8601String(),
      };
      final mViejo = Movimiento.fromMap(viejo, id: 'm-viejo');
      expect(mViejo.usuarioId, '');
      expect(mViejo.tipo, TipoMovimiento.donacion);
      expect(m == _movimiento(usuarioId: 'otro'), isFalse);
    });
  });

  group('13.9 ViewModels reactivos y ciclo de vida', () {
    Cancion cancion(String id) => Cancion(
      id: id,
      titulo: 'Tema $id',
      duracionSegundos: 200,
      reproducciones: 0,
      tendencia: '',
      lugar: '',
      horarioPico: '',
      colorPortada: 1,
    );

    test(
      'CatalogoViewModel (memoria): publicar no duplica notificaciones y el '
      'VM reacciona a cambios directos del repo; dispose corta la suscripción',
      () {
        final repo = RepositorioCatalogoMemoria(canciones: [], albumes: []);
        final vm = CatalogoViewModel(repositorio: repo);
        var notifs = 0;
        vm.addListener(() => notifs++);
        // Una sola suscripción: cada alta del repo produce UNA notificación.

        vm.publicar(
          nuevas: [cancion('c-1')],
          tituloAlbum: null,
          colorPortada: 1,
        );
        expect(notifs, 1); // sólo la notificación del repo, sin duplicar
        expect(vm.canciones, hasLength(1));

        vm.publicar(
          nuevas: [cancion('c-2')],
          tituloAlbum: 'Album X',
          anioAlbum: '2026',
          colorPortada: 2,
        );
        expect(notifs, 3); // 2 altas del repo (canciones + álbum), reemitidas
        expect(vm.albumes, hasLength(1));

        // Reactividad: un cambio directo en el repo también llega al VM.
        repo.agregarCanciones([cancion('c-3')]);
        expect(notifs, 4);
        expect(vm.canciones, hasLength(3));

        vm.dispose();
        repo.agregarCanciones([cancion('c-4')]);
        expect(notifs, 4); // listener liberado: sin notificaciones tras dispose
        expect(vm.canciones, hasLength(4)); // el repo sí siguió cambiando
        repo.dispose();
      },
    );

    test('EntradasViewModel (memoria): publicar/comprar/comprarAsync mantienen '
        'su comportamiento y dispose corta la reactividad', () async {
      final repoE = RepositorioEntradasMemoria(conciertos: [], entradas: []);
      final repoM = RepositorioMovimientosMemoria(movimientos: []);
      final vm = EntradasViewModel(
        repositorioEntradas: repoE,
        repositorioMovimientos: repoM,
        reloj: RelojFijo(_fechaMovimiento),
        uidActual: () => 'uid-1',
      );
      var notifs = 0;
      vm.addListener(() => notifs++);

      vm.publicarConcierto(
        nombre: 'Show',
        lugar: 'Arena',
        fecha: _fechaConcierto,
        precio: 1000,
        disponibles: 5,
      );
      expect(notifs, 1); // una notificación por el alta del repo
      expect(vm.conciertosDisponibles, hasLength(1));

      final ok = vm.comprar(vm.conciertosDisponibles.single, 2);
      expect(ok, isTrue);
      expect(notifs, 3); // descuento (1) + entrada (1) vía el repo
      expect(vm.conciertosDisponibles.single.disponibles, 3);
      expect(vm.entradasCompradas, hasLength(1));
      expect(repoM.movimientos, hasLength(1));

      // comprarAsync en memoria usa el mismo flujo completo, sin duplicar.
      // (Se pasa la instancia almacenada: el repo compara por valor.)
      final ok2 = await vm.comprarAsync(vm.conciertosDisponibles.single, 1);
      expect(ok2, isTrue);
      expect(vm.entradasCompradas, hasLength(2));
      expect(repoM.movimientos, hasLength(2));
      expect(vm.conciertosDisponibles.single.disponibles, 2);

      vm.dispose();
      repoE.agregarConcierto(_concierto(id: 'c9'));
      final despuesDeDispose = notifs;
      expect(vm.conciertosDisponibles, hasLength(2)); // el repo cambió
      expect(notifs, despuesDeDispose); // pero el VM ya no notifica
      repoE.dispose();
      repoM.dispose();
    });

    test('SeguimientoViewModel (memoria): seguir/alternar/alternarAlbum '
        'notifican una vez, reacciona a los repos y dispose libera ambos listeners', () {
      final repoA = RepositorioArtistasMemoria(
        artistas: [const Artista(id: 'a1', nombre: 'A1')],
      );
      final repoC = RepositorioCatalogoMemoria(
        canciones: [],
        albumes: [
          const Album(
            id: 'al1',
            titulo: 'Al',
            anio: '2026',
            colorPortada: 1,
            cancionIds: [],
          ),
        ],
      );
      final vm = SeguimientoViewModel(
        repositorioArtistas: repoA,
        repositorioCatalogo: repoC,
      );
      var notifs = 0;
      vm.addListener(() => notifs++);

      vm.seguir('a1');
      expect(notifs, 1);
      expect(vm.sigo('a1'), isTrue);
      vm.alternar('a1');
      expect(notifs, 2);
      expect(vm.sigo('a1'), isFalse);

      vm.alternarAlbum('al1');
      expect(notifs, 3);
      expect(vm.sigoAlbum('al1'), isTrue);
      expect(vm.albumesSeguidos, hasLength(1));

      // Reactividad ante cambios de los repositorios.
      repoC.agregarCanciones([cancion('c-1')]);
      expect(notifs, 4);

      vm.dispose();
      repoC.agregarCanciones([cancion('c-2')]);
      expect(
        notifs,
        4,
      ); // ambos listeners liberados: sin notificar tras dispose
      repoA.dispose();
      repoC.dispose();
    });
  });

  group('despacho dinámico de generarId (extensión FuenteFirestoreIds)', () {
    test(
      'impl que declara GeneradorIdsFirestore (FakeFuenteFirestore) delega en '
      'su método e incrementa llamadasGenerarId',
      () {
        final fuente = FakeFuenteFirestore();
        final id = fuente.generarId('entradas');
        expect(fuente.llamadasGenerarId, 1);
        expect(id, startsWith('auto-'));
        expect(fuente.generarId('movimientos'), startsWith('auto-'));
        expect(fuente.llamadasGenerarId, 2);
      },
    );

    test(
      'impl que declara SOLO FuenteFirestore usa el generador de respaldo de '
      'la extensión (id aleatorio de 20 caracteres, sin tocar contadores)',
      () {
        final fuente = _FuenteSoloContrato();
        final id = fuente.generarId('entradas');
        expect(id, hasLength(20)); // formato auto-id de Firestore
        expect(id, isNot(startsWith('auto-')));
        // El fake con GeneradorIdsFirestore aparte no se ve afectado.
        final fake = FakeFuenteFirestore();
        fake.generarId('entradas');
        expect(fake.llamadasGenerarId, 1);
      },
    );

    test(
      'en una compra atómica con reintento, llamadasGenerarId no aumenta con '
      'los reintentos (ids generados antes de la transacción)',
      () async {
        final fuente = FakeFuenteFirestore();
        await fuente.setDocumento(
          'conciertos',
          'c1',
          _conciertoMap(disponibles: 1),
        );
        final repo = RepositorioEntradasFirestore(
          fuente: fuente,
          uidActual: () => 'uid-1',
        );
        Future<bool> compra() => repo.descontarDisponiblesAsync(
          'c1',
          1,
          entradaGenerada: _entrada(),
          movimientoGenerado: _movimiento(),
        );
        final resultados = await Future.wait([compra(), compra()]);
        expect(resultados.where((r) => r), hasLength(1));
        expect(fuente.reintentos, greaterThanOrEqualTo(1));
        // 2 ids por operación, una sola vez: el reintento no regenera ids.
        expect(fuente.llamadasGenerarId, 4);
        await repo.cerrar();
        repo.dispose();
      },
    );
  });
}
