import 'dart:ui' show Color;

import 'package:streamtunes_demo/theme/colores.dart';

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

// Colores entre los que se elige la portada, definidos una sola vez en theme/colores.dart.
const List<Color> coloresPortada = [
  colorAcento,
  colorAzul,
  colorVerificado,
  colorMagenta,
  colorAmarillo,
  colorRosa,
];
