import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Tarjeta estándar de la app: usa el cardTheme del tema (fondo tarjeta,
// sin sombra) y opcionalmente lleva el borde de acento.
class Tarjeta extends StatelessWidget {
  final Widget child;
  final bool bordeAcento;
  final EdgeInsetsGeometry? margin;
  final double radio;

  const Tarjeta({
    super.key,
    required this.child,
    this.bordeAcento = false,
    this.margin,
    this.radio = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radio),
        side: bordeAcento
            ? BorderSide(color: colorAcento.withValues(alpha: 0.35))
            : BorderSide.none,
      ),
      child: child,
    );
  }
}
