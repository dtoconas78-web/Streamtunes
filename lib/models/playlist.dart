// Modelo de playlist. Guarda las posiciones de sus canciones en la lista `canciones`.

import 'package:flutter/material.dart';

// Una playlist guarda las posiciones de sus canciones en la lista global `canciones`.
class Playlist {
  String nombre;
  String descripcion;
  final Color color;
  final List<int> indices;

  Playlist({
    required this.nombre,
    this.descripcion = '',
    required this.color,
    List<int>? indices,
  }) : indices = indices ?? [];
}
