import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/models/playlist.dart';

// Playlists del oyente: crear, agregar/quitar canciones y eliminar.
// Vive fuera de las pantallas para que la Biblioteca se actualice sola.
// Los datos viven en el [RepositorioPlaylists] inyectado (ver
// lib/inyeccion.dart: en el celular se guardan con shared_preferences); sin
// repositorio se usa uno en memoria.
class PlaylistsViewModel extends ChangeNotifier {
  PlaylistsViewModel({RepositorioPlaylists? repositorio})
    : _repositorio = repositorio ?? RepositorioPlaylistsMemoria() {
    // Reactividad: cada cambio real del repositorio (alta, edición o cambio
    // de usuario) se reemite una sola vez.
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioPlaylists _repositorio;

  List<Playlist> get playlists => _repositorio.playlists;

  Playlist? porId(String id) => _repositorio.porId(id);

  Playlist crear(String nombre) => _repositorio.crear(nombre);

  void renombrar(String id, String nuevoNombre) =>
      _repositorio.renombrar(id, nuevoNombre);

  void agregarCancion(String playlistId, String cancionId) =>
      _repositorio.agregarCancion(playlistId, cancionId);

  void quitarCancion(String playlistId, String cancionId) =>
      _repositorio.quitarCancion(playlistId, cancionId);

  void eliminar(String playlistId) => _repositorio.eliminar(playlistId);

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
