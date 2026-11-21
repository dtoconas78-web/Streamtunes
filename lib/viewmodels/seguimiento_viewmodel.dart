import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/artista.dart';

// Regla de StreamTunes: para donarle a un artista, primero lo seguís.
// Este viewmodel guarda a quiénes sigue el oyente de esta sesión:
// artistas (para donar) y álbumes (aparecen en la Biblioteca al seguirlos).
// Los datos de artistas y álbumes vienen de los repositorios inyectados
// (albumesSeguidos recorre el catálogo real, no una copia).
class SeguimientoViewModel extends ChangeNotifier {
  SeguimientoViewModel({
    required this._repositorioArtistas,
    required this._repositorioCatalogo,
  }) {
    // Reactividad: se reemiten los cambios de ambos repositorios (snapshots
    // de Firestore o altas en memoria); las notificaciones propias de seguir
    // y alternarAlbum siguen notificando directo, sin duplicarse.
    _repositorioArtistas.addListener(notifyListeners);
    _repositorioCatalogo.addListener(notifyListeners);
  }

  final RepositorioArtistas _repositorioArtistas;
  final RepositorioCatalogo _repositorioCatalogo;

  final Set<String> _idsSeguidos = {};
  final Set<String> _albumesSeguidos = {};

  bool sigo(String id) => _idsSeguidos.contains(id);

  Artista? porId(String id) => _repositorioArtistas.porId(id);

  List<Artista> get seguidos =>
      _repositorioArtistas.todos.where((a) => sigo(a.id)).toList();

  List<Artista> get noSeguidos =>
      _repositorioArtistas.todos.where((a) => !sigo(a.id)).toList();

  void seguir(String id) {
    if (_idsSeguidos.add(id)) notifyListeners();
  }

  void dejarDeSeguir(String id) {
    if (_idsSeguidos.remove(id)) notifyListeners();
  }

  void alternar(String id) {
    if (sigo(id)) {
      dejarDeSeguir(id);
    } else {
      seguir(id);
    }
  }

  // ---- Álbumes seguidos (corazón en la pantalla del álbum) ----

  bool sigoAlbum(String id) => _albumesSeguidos.contains(id);

  // Solo los álbumes seguidos aparecen en la Biblioteca.
  List<Album> get albumesSeguidos => [
    for (final a in _repositorioCatalogo.albumes)
      if (_albumesSeguidos.contains(a.id)) a,
  ];

  void alternarAlbum(String id) {
    if (_albumesSeguidos.contains(id)) {
      _albumesSeguidos.remove(id);
    } else {
      _albumesSeguidos.add(id);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorioArtistas.removeListener(notifyListeners);
    _repositorioCatalogo.removeListener(notifyListeners);
    super.dispose();
  }
}
