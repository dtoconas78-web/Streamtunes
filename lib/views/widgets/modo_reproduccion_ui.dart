import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

// Presentación visual del modo de reproducción: ícono y etiqueta.
// El ViewModel solo guarda el modo; acá vive cómo se muestra.
extension ModoReproduccionUI on ModoReproduccion {
  String get etiqueta => switch (this) {
    ModoReproduccion.enOrden => 'En orden',
    ModoReproduccion.aleatorio => 'Aleatoria',
    ModoReproduccion.repetirUna => 'Solo esta canción',
  };

  IconData get icono => switch (this) {
    ModoReproduccion.enOrden => Icons.repeat,
    ModoReproduccion.aleatorio => Icons.shuffle,
    ModoReproduccion.repetirUna => Icons.repeat_one,
  };
}
