import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/artista.dart';

/// Contrato del repositorio de artistas (a quiénes se puede seguir y donar).
///
/// Es observable (ChangeNotifier): con backend, los cambios remotos de la
/// colección `artistas` (snapshots) notifican a los listeners. La
/// implementación de demo es en memoria (semilla: datos_ejemplo.dart).
abstract class RepositorioArtistas extends ChangeNotifier {
  /// Artistas de solo lectura.
  List<Artista> get todos;

  Artista? porId(String id);
}

/// Implementación en memoria: arranca con los datos de ejemplo.
class RepositorioArtistasMemoria extends RepositorioArtistas {
  RepositorioArtistasMemoria({List<Artista>? artistas})
    : _artistas = List.of(artistas ?? datos.artistas);

  final List<Artista> _artistas;

  @override
  List<Artista> get todos => List.unmodifiable(_artistas);

  @override
  Artista? porId(String id) {
    for (final a in _artistas) {
      if (a.id == id) return a;
    }
    return null;
  }
}
