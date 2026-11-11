import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Estilo común para los campos de los formularios.
InputDecoration decoracionFormulario(String etiqueta) {
  return InputDecoration(
    labelText: etiqueta,
    filled: true,
    fillColor: colorTarjeta,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}