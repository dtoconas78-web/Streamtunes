import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

// Dueño del catálogo (canciones y álbumes). La UI ya no muta las listas
// globales de datos_ejemplo a mano: pasa por acá y las pantallas se
// actualizan solas con ListenableBuilder.
class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel({List<Cancion>? cancionesIniciales, List<Album>? albumesIniciales})
    : canciones = List.of(cancionesIniciales ?? datos.canciones),
      albumes = List.of(albumesIniciales ?? datos.albumes);

  final List<Cancion> canciones;
  final List<Album> albumes;

  // Publica canciones nuevas (sueltas o como álbum) y notifica.
  void publicar({
    required List<Cancion> nuevas,
    String? tituloAlbum,
    String? anioAlbum,
    required Color colorPortada,
  }) {
    final primero = canciones.length;
    canciones.addAll(nuevas);
    if (tituloAlbum != null) {
      albumes.add(
        Album(
          titulo: tituloAlbum,
          anio: anioAlbum ?? '',
          colorPortada: colorPortada,
          indices: [for (int i = 0; i < nuevas.length; i++) primero + i],
        ),
      );
    }
    notifyListeners();
  }
}

// Instancia compartida por toda la app.
final CatalogoViewModel catalogo = CatalogoViewModel();
