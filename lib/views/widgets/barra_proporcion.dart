import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';

/// Fila con etiqueta, cantidad y una barra con la proporción (0..1).
class BarraProporcion extends StatelessWidget {
  const BarraProporcion({
    super.key,
    required this.etiqueta,
    required this.cantidad,
    required this.proporcion,
    this.destacada = false,
  });

  final String etiqueta;
  final int cantidad;
  final double proporcion;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: destacada ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                formatearMiles(cantidad),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: proporcion,
              backgroundColor: colorTarjeta,
              color: destacada
                  ? colorAcento
                  : colorAcento.withValues(alpha: 0.5),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
