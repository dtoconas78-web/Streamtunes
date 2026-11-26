import 'dart:io';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/inyeccion.dart' as inyeccion;

// Portada cuadrada: la foto de portada si la canción/álbum tiene una
// guardada en este celular ([itemId], ver RepositorioPortadas); si no, el
// color de portada con el ícono. Reemplaza los Container con BoxDecoration
// que se repetían en cada lista.
class PortadaCuadrada extends StatelessWidget {
  final Color color;
  final double tamano;
  final IconData icono;
  final double radio;
  final double? tamanoIcono;

  /// Id de la canción o álbum (null = solo color, sin buscar foto).
  final String? itemId;

  const PortadaCuadrada({
    super.key,
    required this.color,
    this.tamano = 56,
    this.icono = Icons.music_note,
    this.radio = 8,
    this.tamanoIcono,
    this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id == null) return _deColor();
    final portadas = inyeccion.repositorioPortadas;
    return ListenableBuilder(
      listenable: portadas,
      builder: (context, _) {
        final ruta = portadas.rutaDe(id);
        if (ruta == null) return _deColor();
        return ClipRRect(
          borderRadius: BorderRadius.circular(radio),
          child: Image.file(
            File(ruta),
            width: tamano,
            height: tamano,
            fit: BoxFit.cover,
            // Archivo borrado o ilegible: vuelve al color.
            errorBuilder: (_, _, _) => _deColor(),
          ),
        );
      },
    );
  }

  Widget _deColor() => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radio),
    ),
    child: Icon(icono, color: Colors.black, size: tamanoIcono),
  );
}
