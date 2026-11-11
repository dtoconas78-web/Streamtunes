import 'package:flutter/material.dart';

// Modelo simple para representar un álbum.
// "indices" son las posiciones de sus canciones en la lista `canciones`.
class Album {
  final String titulo;
  final String anio;
  final Color colorPortada;
  final List<int> indices;

  const Album({
    required this.titulo,
    required this.anio,
    required this.colorPortada,
    required this.indices,
  });
}
