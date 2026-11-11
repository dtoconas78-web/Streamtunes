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

final _regexEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

// Validadores reutilizables en login y registro.
// Los mensajes están pensados para que cualquier persona entienda qué falta.
String? validarNombre(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Escribí tu nombre';
  if (texto.length < 2) return 'El nombre tiene al menos 2 letras';
  return null;
}

String? validarEmail(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Ingresá tu email';
  if (!_regexEmail.hasMatch(texto)) return 'Ese email no parece válido';
  return null;
}

String? validarPassword(String? valor) {
  if ((valor ?? '').isEmpty) return 'Escribí una contraseña';
  if (valor!.length < 6) return 'La contraseña tiene al menos 6 caracteres';
  return null;
}

String? validarRepeticion(String? valor, String password) {
  if (valor != password) return 'Las contraseñas no coinciden';
  return null;
}
