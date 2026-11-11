// Gestor de playlists (ChangeNotifier), igual que `reproductor` y `perfil`:
// una única instancia compartida, y las pantallas se redibujan solas al cambiar.

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/models/playlist.dart';
import 'package:streamtunes_demo/utils/constantes.dart';

class GestorPlaylists extends ChangeNotifier {
  // Datos de ejemplo.
  final List<Playlist> lista = [
    Playlist(
      nombre: 'Para el viaje',
      descripcion: 'Rutas, ventanilla y volumen alto.',
      color: const Color(0xFF00BFA5),
      indices: [2, 3, 0],
    ),
    Playlist(
      nombre: 'Noche en la ciudad',
      descripcion: 'Para volver caminando.',
      color: const Color(0xFFD500F9),
      indices: [0, 1],
    ),
  ];

  // Crea una playlist vacía y la devuelve para poder abrirla enseguida.
  Playlist crear(String nombre) {
    final nueva = Playlist(
      nombre: nombre,
      color: coloresPortada[lista.length % coloresPortada.length],
    );
    lista.add(nueva);
    notifyListeners();
    return nueva;
  }

  void eliminar(Playlist playlist) {
    lista.remove(playlist);
    notifyListeners();
  }

  void renombrar(Playlist playlist, String nombre) {
    playlist.nombre = nombre;
    notifyListeners();
  }

  bool contiene(Playlist playlist, int indice) => playlist.indices.contains(indice);

  void agregarCancion(Playlist playlist, int indice) {
    if (contiene(playlist, indice)) return;
    playlist.indices.add(indice);
    notifyListeners();
  }

  // Devuelve el índice quitado (sirve para "Deshacer").
  int quitarCancion(Playlist playlist, int posicion) {
    final indice = playlist.indices.removeAt(posicion);
    notifyListeners();
    return indice;
  }

  // Vuelve a poner una canción en su lugar original (Deshacer).
  void insertarCancion(Playlist playlist, int posicion, int indice) {
    if (contiene(playlist, indice)) return;
    final destino = posicion > playlist.indices.length ? playlist.indices.length : posicion;
    playlist.indices.insert(destino, indice);
    notifyListeners();
  }
}

final GestorPlaylists gestorPlaylists = GestorPlaylists();
