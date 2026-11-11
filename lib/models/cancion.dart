import 'package:flutter/material.dart';

// Modelo simple para representar una canción.
class Cancion {
  final String titulo;
  final String duracion;
  final String reproducciones;
  final String tendencia;
  final String lugar;
  final String horarioPico;
  final Color colorPortada;
  final String genero;
  final String descripcion;
  final bool publica;

  const Cancion({
    required this.titulo,
    required this.duracion,
    required this.reproducciones,
    required this.tendencia,
    required this.lugar,
    required this.horarioPico,
    required this.colorPortada,
    this.genero = '',
    this.descripcion = '',
    this.publica = true,
  });
}