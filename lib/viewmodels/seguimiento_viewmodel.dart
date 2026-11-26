import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/artista.dart';

// Regla de StreamTunes: para donarle a un artista, primero lo seguís.
// Este viewmodel expone a quiénes sigue el oyente: artistas (para donar) y
// álbumes (aparecen en la Biblioteca al seguirlos). Los ids seguidos viven en
// el [RepositorioSeguimiento] inyectado (en el celular se guardan con
// shared_preferences); los datos de artistas y álbumes vienen de sus
// repositorios (albumesSeguidos recorre el catálogo real, no una copia).
class SeguimientoViewModel extends ChangeNotifier {
  SeguimientoViewModel({
    required this._repositorioArtistas,
    required this._repositorioCatalogo,
    RepositorioSeguimiento? repositorioSeguimiento,
  }) : _repositorioSeguimiento =
           repositorioSeguimiento ?? RepositorioSeguimientoMemoria() {
    // Reactividad: se reemiten los cambios de los tres repositorios
    // (snapshots de Firestore, altas en memoria o seguir/dejar de seguir).
    // Las acciones de abajo NO notifican directo: lo hace el repositorio de
    // seguimiento, así hay una sola notificación por cambio real.
    _repositorioArtistas.addListener(notifyListeners);
    _repositorioCatalogo.addListener(notifyListeners);
    _repositorioSeguimiento.addListener(notifyListeners);
  }

  final RepositorioArtistas _repositorioArtistas;
  final RepositorioCatalogo _repositorioCatalogo;
  final RepositorioSeguimiento _repositorioSeguimiento;

  bool sigo(String id) => _repositorioSeguimiento.sigueArtista(id);

  Artista? porId(String id) => _repositorioArtistas.porId(id);

  List<Artista> get seguidos =>
      _repositorioArtistas.todos.where((a) => sigo(a.id)).toList();

  List<Artista> get noSeguidos =>
      _repositorioArtistas.todos.where((a) => !sigo(a.id)).toList();

  void seguir(String id) => _repositorioSeguimiento.seguirArtista(id);

  void dejarDeSeguir(String id) =>
      _repositorioSeguimiento.dejarDeSeguirArtista(id);

  void alternar(String id) {
    if (sigo(id)) {
      dejarDeSeguir(id);
    } else {
      seguir(id);
    }
  }

  // ---- Álbumes seguidos (corazón en la pantalla del álbum) ----

  bool sigoAlbum(String id) => _repositorioSeguimiento.sigueAlbum(id);

  // Solo los álbumes seguidos aparecen en la Biblioteca.
  List<Album> get albumesSeguidos => [
    for (final a in _repositorioCatalogo.albumes)
      if (sigoAlbum(a.id)) a,
  ];

  void alternarAlbum(String id) => _repositorioSeguimiento.alternarAlbum(id);

  @override
  void dispose() {
    _repositorioArtistas.removeListener(notifyListeners);
    _repositorioCatalogo.removeListener(notifyListeners);
    _repositorioSeguimiento.removeListener(notifyListeners);
    super.dispose();
  }
}
