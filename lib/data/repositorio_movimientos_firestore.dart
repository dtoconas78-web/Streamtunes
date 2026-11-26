import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

/// Movimientos económicos en Cloud Firestore (colección `movimientos`) con
/// snapshots en tiempo real, filtrados por `usuarioId` (uid de la sesión
/// válida vía [uidActual], resuelto de forma diferida; sin sesión válida la
/// lista queda vacía y nunca se exponen movimientos de otros usuarios).
///
/// Excepción: si la sesión es de un artista ([artistaActual] devuelve su
/// id), también se incluyen las DONACIONES dirigidas a ese artista aunque
/// las haya hecho otro usuario (así ve quién lo banca y recibe el aviso).
///
/// El movimiento de una COMPRA no se escribe desde acá: se crea dentro de la
/// transacción atómica de `RepositorioEntradasFirestore` (única ruta de
/// escritura para ese registro). Acá `registrar` sólo cubre altas sueltas
/// (p. ej. donaciones). La caché arranca vacía y se llena con el primer
/// snapshot; ante error del stream se conserva la última caché válida y se
/// registra en [ultimoError].
class RepositorioMovimientosFirestore extends RepositorioMovimientos {
  RepositorioMovimientosFirestore({
    required this._fuente,
    this.uidActual,
    this.artistaActual,
  }) {
    _suscripcion = _fuente
        .snapshotsColeccion('movimientos')
        .map((docs) {
          _ultimosDocs = docs;
          return _filtrar(docs);
        })
        .listen(_alCambiar, onError: _alError);
  }

  // Últimos documentos recibidos: al cambiar la sesión se vuelven a filtrar
  // sin esperar otro snapshot (el repo puede crearse antes del login).
  List<DocumentoFirestore> _ultimosDocs = const [];

  List<Movimiento> _filtrar(List<DocumentoFirestore> docs) {
    final uid = uidActual?.call();
    if (uid == null || uid.isEmpty) return <Movimiento>[];
    final artista = artistaActual?.call();
    bool esDonacionParaMi(Map<String, dynamic> datos) =>
        artista != null &&
        artista.isNotEmpty &&
        datos['tipo'] == TipoMovimiento.donacion.name &&
        datos['artistaId'] == artista;
    return [
      for (final d in docs)
        if (d.datos['usuarioId'] == uid || esDonacionParaMi(d.datos))
          Movimiento.fromMap(d.datos, id: d.id),
    ];
  }

  /// La sesión cambió (login, logout, otro rol): vuelve a filtrar los
  /// últimos documentos recibidos.
  void actualizarSesion() {
    try {
      _alCambiar(_filtrar(_ultimosDocs));
    } catch (e) {
      _alError(e);
    }
  }

  final FuenteFirestore _fuente;

  /// Proveedor diferido del uid de la sesión válida (null = sin sesión).
  final String? Function()? uidActual;

  /// Proveedor diferido del id del artista de la sesión (null = la sesión no
  /// es de un artista).
  final String? Function()? artistaActual;

  List<Movimiento> _movimientos = [];
  StreamSubscription<List<Movimiento>>? _suscripcion;

  /// Último error del stream (la última caché válida se conserva).
  Object? ultimoError;

  @override
  List<Movimiento> get movimientos => List.unmodifiable(_movimientos);

  void _alCambiar(List<Movimiento> lista) {
    if (listEquals(_movimientos, lista)) return; // sin cambio real, no notifica
    _movimientos = lista;
    notifyListeners();
  }

  void _alError(Object e) {
    ultimoError = e;
    debugPrint(
      'RepositorioMovimientosFirestore: error de stream '
      '(se conserva la última caché válida): $e',
    );
  }

  @override
  void registrar(Movimiento movimiento) {
    final uid = uidActual?.call();
    unawaited(
      _escribir({
        ...movimiento.toMap(),
        if (uid != null && uid.isNotEmpty) 'usuarioId': uid,
      }),
    );
  }

  Future<void> _escribir(Map<String, dynamic> datos) async {
    try {
      await _fuente.agregarDocumento('movimientos', datos);
    } catch (e) {
      ultimoError = e;
      debugPrint(
        'RepositorioMovimientosFirestore: falló el registro del movimiento: $e',
      );
    }
  }

  @override
  void dispose() {
    unawaited(cerrar());
    super.dispose();
  }

  /// Cancela la suscripción al snapshot (esperar con `await cerrar()`).
  Future<void> cerrar() async {
    final c = _suscripcion?.cancel();
    _suscripcion = null;
    await c;
  }
}
