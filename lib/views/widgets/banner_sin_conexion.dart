import 'package:flutter/material.dart';

import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/services/servicio_conectividad.dart';
import 'package:streamtunes_demo/theme/colores.dart';

/// Banner no invasivo de modo sin conexión: una franja arriba de todo que
/// aparece solo cuando el dispositivo se queda sin internet.
class BannerSinConexion extends StatelessWidget {
  const BannerSinConexion({super.key, required this.servicio});

  final ServicioConectividad servicio;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: servicio,
      builder: (context, _) {
        if (servicio.estaConectado) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: colorAcentoOscuro,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Text(
            politicas.avisoSinConexion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }
}
