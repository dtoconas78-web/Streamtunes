import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

/// Entradas y conciertos en Cloud Firestore (colecciones `conciertos` y
/// `entradas`) con snapshots en tiempo real y COMPRA ATÓMICA transaccional.
///
/// Compra atómica (`descontarDisponiblesAsync`): una única `runTransaction`
/// lee el concierto, valida (existe, cantidad > 0, stock suficiente) y
/// escribe en el mismo commit el stock descontado + el doc de la entrada +
/// el doc del movimiento. Si cualquier validación falla, no se escribe NADA
/// (nunca hay stock descontado sin entrada y movimiento). Los ids de entrada
/// y movimiento se generan ANTES de la transacción (`generarId` o derivados
/// de `operacionId`), así permanecen estables ante los reintentos de
/// Firestore. Con `operacionId` la operación es idempotente: si ambos docs
/// ya existen no se repite; si existe solo uno, se rechaza (inconsistente).
///
/// Las entradas se filtran por `usuarioId` (uid de la sesión válida vía
/// [uidActual], resuelto de forma diferida); sin sesión válida la lista
/// queda vacía y nunca se exponen entradas de otros usuarios. La caché
/// arranca vacía y se llena con el primer snapshot; ante error del stream se
/// conserva la última caché válida y se registra en [ultimoError].
class RepositorioEntradasFirestore extends RepositorioEntradas {
  RepositorioEntradasFirestore({required this._fuente, this.uidActual}) {
    _susConciertos = _fuente
        .snapshotsColeccion('conciertos')
        .map(
          (docs) => [
            for (final d in docs) Concierto.fromMap(d.datos, id: d.id),
          ],
        )
        .listen(_alCambiarConciertos, onError: _alError);
    _susEntradas = _fuente
        .snapshotsColeccion('entradas')
        .map((docs) {
          final uid = uidActual?.call();
          if (uid == null || uid.isEmpty) return <Entrada>[];
          return [
            for (final d in docs)
              if (d.datos['usuarioId'] == uid)
                Entrada.fromMap(d.datos, id: d.id),
          ];
        })
        .listen(_alCambiarEntradas, onError: _alError);
  }

  final FuenteFirestore _fuente;

  /// Proveedor diferido del uid de la sesión válida (null = invitado o sin
  /// sesión Firebase). Se resuelve en cada uso, nunca en el constructor.
  final String? Function()? uidActual;

  List<Concierto> _conciertos = [];
  List<Entrada> _entradas = [];
  StreamSubscription<List<Concierto>>? _susConciertos;
  StreamSubscription<List<Entrada>>? _susEntradas;

  /// Último error de stream o de escritura (se conserva la última caché
  /// válida).
  Object? ultimoError;

  @override
  bool get soportaCompraAtomica => true;

  @override
  List<Entrada> get entradasCompradas => List.unmodifiable(_entradas);

  @override
  List<Concierto> get conciertosDisponibles => List.unmodifiable(_conciertos);

  void _alCambiarConciertos(List<Concierto> lista) {
    if (listEquals(_conciertos, lista)) return; // sin cambio real, no notifica
    _conciertos = lista;
    notifyListeners();
  }

  void _alCambiarEntradas(List<Entrada> lista) {
    if (listEquals(_entradas, lista)) return;
    _entradas = lista;
    notifyListeners();
  }

  void _alError(Object e) {
    ultimoError = e;
    debugPrint(
      'RepositorioEntradasFirestore: error de stream '
      '(se conserva la última caché válida): $e',
    );
  }

  // ---- Compra atómica (única operación transaccional) ----

  @override
  bool descontarDisponibles(Concierto concierto, int cantidad) {
    // En Firestore el descuento REAL ocurre solo dentro de la transacción
    // (descontarDisponiblesAsync). Este método sync sólo valida contra la
    // caché local y NO modifica nada.
    if (cantidad <= 0) return false;
    final almacenado = _conciertos
        .where(
          (c) =>
              c.id == concierto.id || (concierto.id.isEmpty && c == concierto),
        )
        .firstOrNull;
    if (almacenado == null) return false;
    return cantidad <= almacenado.disponibles;
  }

  @override
  Future<bool> descontarDisponiblesAsync(
    String conciertoId,
    int cantidad, {
    Entrada? entradaGenerada,
    Movimiento? movimientoGenerado,
    String? operacionId,
  }) async {
    // Validaciones previas a CUALQUIER escritura.
    if (cantidad <= 0) return false;
    if (entradaGenerada == null || movimientoGenerado == null) {
      debugPrint(
        'RepositorioEntradasFirestore: compra rechazada antes de escribir: '
        'falta entradaGenerada o movimientoGenerado',
      );
      return false;
    }
    final uid = uidActual?.call();
    if (uid == null || uid.isEmpty) {
      ultimoError = StateError(
        'No hay una sesión de usuario válida para asociar la compra',
      );
      debugPrint(
        'RepositorioEntradasFirestore: compra rechazada (sin uid de sesión '
        'válida; los ids locales de invitado no son uid de Firebase)',
      );
      return false;
    }
    // Ids estables: generados ANTES de runTransaction (sobreviven a los
    // reintentos). Con operacionId son determinísticos (idempotencia).
    final entradaId = operacionId != null
        ? 'entrada-$operacionId'
        : _fuente.generarId('entradas');
    final movimientoId = operacionId != null
        ? 'movimiento-$operacionId'
        : _fuente.generarId('movimientos');

    try {
      return await _fuente.runTransaction((txn) async {
        // Idempotencia: comprobar ANTES de descontar si la operación ya se
        // procesó (dentro de la misma transacción).
        if (operacionId != null) {
          final entradaPrevia = await txn.leer('entradas', entradaId);
          final movimientoPrevio = await txn.leer('movimientos', movimientoId);
          if (entradaPrevia != null && movimientoPrevio != null) {
            return true; // ya procesada: no se repite nada
          }
          if (entradaPrevia != null || movimientoPrevio != null) {
            return false; // estado inconsistente: se rechaza sin escribir
          }
        }
        // 1) Leer el concierto dentro de la transacción.
        final doc = await txn.leer('conciertos', conciertoId);
        if (doc == null) return false; // concierto inexistente
        final concierto = Concierto.fromMap(doc.datos, id: doc.id);
        // 2-3) Validar cantidad y stock (nunca stock negativo).
        if (cantidad <= 0 || cantidad > concierto.disponibles) return false;
        // 4-6) Los tres cambios en UN SOLO commit atómico.
        txn.set(
          'conciertos',
          conciertoId,
          concierto.conDisponibles(concierto.disponibles - cantidad).toMap(),
        );
        txn.set('entradas', entradaId, {
          ...entradaGenerada.toMap(),
          'usuarioId': uid,
          'conciertoId': conciertoId,
        });
        txn.set('movimientos', movimientoId, {
          ...movimientoGenerado.toMap(),
          'usuarioId': uid,
        });
        return true;
      });
    } catch (e) {
      ultimoError = e;
      debugPrint(
        'RepositorioEntradasFirestore: la compra atómica falló '
        '(no se aplicó ningún cambio parcial): $e',
      );
      return false;
    }
  }

  // ---- Escrituras simples (se confirman vía snapshot) ----

  @override
  void agregarConcierto(Concierto concierto) {
    unawaited(_escribir('conciertos', null, concierto.toMap()));
  }

  @override
  void agregarEntrada(Entrada entrada) {
    final uid = uidActual?.call();
    unawaited(
      _escribir('entradas', null, {
        ...entrada.toMap(),
        if (uid != null && uid.isNotEmpty) 'usuarioId': uid,
      }),
    );
  }

  Future<void> _escribir(
    String coleccion,
    String? id,
    Map<String, dynamic> datos,
  ) async {
    try {
      if (id == null) {
        await _fuente.agregarDocumento(coleccion, datos);
      } else {
        await _fuente.setDocumento(coleccion, id, datos);
      }
    } catch (e) {
      ultimoError = e;
      debugPrint(
        'RepositorioEntradasFirestore: falló la escritura en '
        '"$coleccion": $e',
      );
    }
  }

  // ---- Liberación de recursos ----

  @override
  void dispose() {
    unawaited(cerrar()); // cancel() es asíncrono; cerrar() hay que esperarla
    super.dispose();
  }

  /// Cancela todas las suscripciones a snapshots. Hay que esperarla
  /// (`await cerrar()`) para liberar de verdad.
  Future<void> cerrar() async {
    final a = _susConciertos?.cancel();
    final b = _susEntradas?.cancel();
    _susConciertos = null;
    _susEntradas = null;
    await a;
    await b;
  }
}
