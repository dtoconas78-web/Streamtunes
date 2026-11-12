import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Configuración del oyente: notificaciones, reproducción automática y
// si el modo aleatorio queda activo por defecto al reproducir una cola.
class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListenableBuilder(
        listenable: configuracionViewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Tarjeta(
              child: Column(
                children: [
                  SwitchListTile(
                    value: configuracionViewModel.notificaciones,
                    activeThumbColor: colorAcento,
                    title: const Text('Notificaciones'),
                    subtitle: const Text(
                      'Nuevos conciertos de los artistas que seguís',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged: configuracionViewModel.setNotificaciones,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: configuracionViewModel.reproduccionAutomatica,
                    activeThumbColor: colorAcento,
                    title: const Text('Reproducción automática'),
                    subtitle: const Text(
                      'Al terminar una cola, seguir con más música',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged: configuracionViewModel.setReproduccionAutomatica,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: configuracionViewModel.modoAleatorioPorDefecto,
                    activeThumbColor: colorAcento,
                    title: const Text('Aleatoria por defecto'),
                    subtitle: const Text(
                      'Las playlists y álbumes arrancan en modo aleatorio',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged:
                        configuracionViewModel.setModoAleatorioPorDefecto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'La app es 100% gratuita: no hay suscripciones ni pagos para escuchar.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
