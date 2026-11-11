import 'package:flutter/material.dart';

// Países disponibles en la pantalla Editar perfil.
const List<String> paises = [
  'Argentina',
  'Chile',
  'Uruguay',
  'Paraguay',
  'Bolivia',
  'Brasil',
  'Colombia',
  'México',
  'España',
  'Otro',
];

// Límites sugeridos para contener el costo de almacenamiento y ancho de banda.
// Por ahora solo se muestran como texto. Con un selector de archivos real,
// se validan al elegir cada audio.
const int maxMbPorArchivo = 50;
const int maxMinutosPorCancion = 10;

// Géneros disponibles en la pantalla Subir música.
const List<String> generos = [
  'Rock',
  'Pop',
  'Electrónica',
  'Hip hop',
  'Folklore',
  'Indie',
  'Otro',
];

// Colores entre los que se elige la portada (la imagen real se conecta después).
const List<Color> coloresPortada = [
  Color(0xFFFF5500),
  Color(0xFF3D5AFE),
  Color(0xFF00BFA5),
  Color(0xFFD500F9),
  Color(0xFFFFC107),
  Color(0xFFE91E63),
];
