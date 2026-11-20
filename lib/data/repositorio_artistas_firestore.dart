import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/models/artista.dart';

/// Artistas en Cloud Firestore (colección `artistas`) con snapshots en tiempo
/// real. Contrato de solo lectura: los cambios entran por el stream.
///
/// Igual que en el catálogo: la caché arranca vacía y se llena con el primer
/// snapshot; ante error del stream se conserva la última caché válida y se
/// registra en [ultimoError]; la lectura pública (modo invitado) funciona sin
/// cuenta.
class RepositorioArtistasFirestore extends RepositorioArtistas {
  RepositorioArtistasFirestore({required this._fuente}) {
    _suscripcion = _fuente
        .snapshotsColeccion('artistas')
        .map(
          (docs) => [for (final d in docs) Artista.fromMap(d.datos, id: d.id)],
        )
        .listen(_alCambiar, onError: _alError);
  }

  final FuenteFirestore _fuente;

  List<Artista> _artistas = [];
  StreamSubscription<List<Artista>>? _suscripcion;

  /// Último error del stream (la última caché válida se conserva).
  Object? ultimoError;

  @override
  List<Artista> get todos => List.unmodifiable(_artistas);

  @override
  Artista? porId(String id) {
    for (final a in _artistas) {
      if (a.id == id) return a;
    }
    return null;
  }

  // Comparación equivalente a .distinct(): si el snapshot no cambió la caché,
  // no se notifica.
  void _alCambiar(List<Artista> lista) {
    if (listEquals(_artistas, lista)) return;
    _artistas = lista;
    notifyListeners();
  }

  void _alError(Object e) {
    ultimoError = e;
    debugPrint(
      'RepositorioArtistasFirestore: error de stream '
      '(se conserva la última caché válida): $e',
    );
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
