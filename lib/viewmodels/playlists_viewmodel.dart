import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/playlist.dart';

// Playlists del oyente: crear, agregar/quitar canciones y eliminar.
// Vive fuera de las pantallas para que la Biblioteca se actualice sola.
class PlaylistsViewModel extends ChangeNotifier {
  final List<Playlist> _playlists = [];
  int _contador = 0;

  List<Playlist> get playlists => List.unmodifiable(_playlists);

  Playlist? porId(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  Playlist crear(String nombre) {
    _contador++;
    final playlist = Playlist(id: 'playlist-$_contador', nombre: nombre.trim());
    _playlists.add(playlist);
    notifyListeners();
    return playlist;
  }

  void renombrar(String id, String nuevoNombre) {
    final p = porId(id);
    if (p == null || p.nombre == nuevoNombre.trim()) return;
    p.nombre = nuevoNombre.trim();
    notifyListeners();
  }

  void agregarCancion(String playlistId, String cancionId) {
    final p = porId(playlistId);
    if (p == null || p.cancionIds.contains(cancionId)) return;
    p.cancionIds.add(cancionId);
    notifyListeners();
  }

  void quitarCancion(String playlistId, String cancionId) {
    final p = porId(playlistId);
    if (p == null || !p.cancionIds.remove(cancionId)) return;
    notifyListeners();
  }

  void eliminar(String playlistId) {
    final antes = _playlists.length;
    _playlists.removeWhere((p) => p.id == playlistId);
    if (_playlists.length != antes) notifyListeners();
  }
}

// Instancia compartida por toda la app.
final PlaylistsViewModel playlistsViewModel = PlaylistsViewModel();
