import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

/// Catálogo en Cloud Firestore (colecciones `canciones` y `albumes`) con
/// snapshots en tiempo real.
///
/// Comportamiento asíncrono de la caché: los getters son SINCROS por contrato
/// y la caché local arranca VACÍA; se llena con el primer snapshot (la semilla
/// y luego los cambios remotos llegan solos, sin estados de carga en la UI).
/// Ante un error del stream se conserva la última caché válida y se registra
/// en [ultimoError] (con debugPrint): nunca hay excepciones asíncronas sin
/// manejar y el modo invitado (lectura pública) no se ve afectado.
class RepositorioCatalogoFirestore extends RepositorioCatalogo {
  RepositorioCatalogoFirestore({required this._fuente}) {
    _susCanciones = _fuente
        .snapshotsColeccion('canciones')
        .map(
          (docs) => [for (final d in docs) Cancion.fromMap(d.datos, id: d.id)],
        )
        .listen(_alCambiarCanciones, onError: _alError);
    _susAlbumes = _fuente
        .snapshotsColeccion('albumes')
        .map((docs) => [for (final d in docs) Album.fromMap(d.datos, id: d.id)])
        .listen(_alCambiarAlbumes, onError: _alError);
  }

  final FuenteFirestore _fuente;

  List<Cancion> _canciones = [];
  List<Album> _albumes = [];
  StreamSubscription<List<Cancion>>? _susCanciones;
  StreamSubscription<List<Album>>? _susAlbumes;

  /// Último error de stream o de escritura (la última caché válida se
  /// conserva igual).
  Object? ultimoError;

  @override
  List<Cancion> get canciones => List.unmodifiable(_canciones);

  @override
  List<Album> get albumes => List.unmodifiable(_albumes);

  // Comparación equivalente a .distinct(): si el snapshot no cambió la caché
  // (incluido el snapshot inicial cuando la colección ya estaba vacía), no se
  // notifica.
  void _alCambiarCanciones(List<Cancion> lista) {
    if (listEquals(_canciones, lista)) return;
    _canciones = lista;
    notifyListeners();
  }

  void _alCambiarAlbumes(List<Album> lista) {
    if (listEquals(_albumes, lista)) return;
    _albumes = lista;
    notifyListeners();
  }

  void _alError(Object e) {
    ultimoError = e;
    debugPrint(
      'RepositorioCatalogoFirestore: error de stream '
      '(se conserva la última caché válida): $e',
    );
  }

  // ---- Escrituras ----
  // Son async por contrato sync: se disparan con unawaited + try/catch, y el
  // cambio se confirma cuando llega el snapshot (que actualiza la caché y
  // notifica). Los ids son los del modelo (determinísticos).
  @override
  void agregarCanciones(List<Cancion> nuevas) {
    if (nuevas.isEmpty) return;
    unawaited(
      _setDocs('canciones', [for (final c in nuevas) (c.id, c.toMap())]),
    );
  }

  @override
  void agregarAlbum(Album album) {
    unawaited(_setDocs('albumes', [(album.id, album.toMap())]));
  }

  Future<void> _setDocs(
    String coleccion,
    List<(String, Map<String, dynamic>)> docs,
  ) async {
    try {
      for (final (id, datos) in docs) {
        await _fuente.setDocumento(coleccion, id, datos);
      }
    } catch (e) {
      ultimoError = e;
      debugPrint(
        'RepositorioCatalogoFirestore: falló la escritura en "$coleccion": $e',
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
  /// (`await cerrar()`) para liberar de verdad; los tests lo verifican así.
  Future<void> cerrar() async {
    final a = _susCanciones?.cancel();
    final b = _susAlbumes?.cancel();
    _susCanciones = null;
    _susAlbumes = null;
    await a;
    await b;
  }
}
