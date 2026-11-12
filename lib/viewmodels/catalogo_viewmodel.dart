import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

// Dueño del catálogo (canciones y álbumes). La UI ya no muta las listas
// globales de datos_ejemplo a mano: pasa por acá y las pantallas se
// actualizan solas con ListenableBuilder.
class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel({
    List<Cancion>? cancionesIniciales,
    List<Album>? albumesIniciales,
  }) : canciones = List.of(cancionesIniciales ?? datos.canciones),
       albumes = List.of(albumesIniciales ?? datos.albumes);

  final List<Cancion> canciones;
  final List<Album> albumes;
  int _contadorAlbumes = 0;

  // Publica canciones nuevas (sueltas o como álbum) y notifica.
  void publicar({
    required List<Cancion> nuevas,
    String? tituloAlbum,
    String? anioAlbum,
    required Color colorPortada,
  }) {
    canciones.addAll(nuevas);
    if (tituloAlbum != null) {
      _contadorAlbumes++;
      albumes.add(
        Album(
          id: 'album-publicado-$_contadorAlbumes',
          titulo: tituloAlbum,
          anio: anioAlbum ?? '',
          colorPortada: colorPortada.toARGB32(),
          cancionIds: [for (final c in nuevas) c.id],
        ),
      );
    }
    notifyListeners();
  }
}

// Instancia compartida por toda la app.
final CatalogoViewModel catalogo = CatalogoViewModel();
