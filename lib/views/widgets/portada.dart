import 'package:flutter/material.dart';

// Portada cuadrada de color (la imagen real se conecta después).
// Reemplaza los Container con BoxDecoration que se repetían en cada lista.
class PortadaCuadrada extends StatelessWidget {
  final Color color;
  final double tamano;
  final IconData icono;
  final double radio;
  final double? tamanoIcono;

  const PortadaCuadrada({
    super.key,
    required this.color,
    this.tamano = 56,
    this.icono = Icons.music_note,
    this.radio = 8,
    this.tamanoIcono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radio),
      ),
      child: Icon(icono, color: Colors.black, size: tamanoIcono),
    );
  }
}
