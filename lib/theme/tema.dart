import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Radio estándar de las tarjetas y campos.
const BorderRadius radioTarjeta = BorderRadius.all(Radius.circular(12));

// Decoración estándar de los campos de formulario (usada por el tema y por
// utils/formularios.dart, para que nunca diverjan).
InputDecoration decoracionCampo(String etiqueta) {
  return InputDecoration(
    labelText: etiqueta,
    filled: true,
    fillColor: colorTarjeta,
    border: OutlineInputBorder(
      borderRadius: radioTarjeta,
      borderSide: BorderSide.none,
    ),
  );
}

// ThemeData único de la app: los estilos repetidos (tarjetas, campos de
// formulario, chips, hojas inferiores) viven acá y no en cada pantalla.
final ThemeData temaApp = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: colorFondo,
  appBarTheme: const AppBarTheme(backgroundColor: colorFondo, elevation: 0),
  // Tarjetas: fondo oscuro, esquinas de 12, sin sombra (estilo plano).
  cardTheme: CardThemeData(
    color: colorTarjeta,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: radioTarjeta),
  ),
  // Campos de formulario: misma decoración que decoracionCampo().
  inputDecorationTheme: InputDecorationThemeData(
    filled: true,
    fillColor: colorTarjeta,
    border: OutlineInputBorder(
      borderRadius: radioTarjeta,
      borderSide: BorderSide.none,
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: colorTarjeta,
    selectedColor: colorAcento,
    side: BorderSide.none,
    shape: const StadiumBorder(),
  ),
  // Hojas inferiores (elegir rol, cantidad de entradas, etc.).
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: colorTarjeta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Colors.grey),
);
