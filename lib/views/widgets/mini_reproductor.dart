import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

// Barra chica que acompaña en todas las pantallas mientras haya una canción
// elegida. Tocarla abre el reproductor grande.
class MiniReproductor extends StatelessWidget {
  const MiniReproductor({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final cancion = reproductor.cancion;
        // Se oculta si no hay canción o si ya está abierto el reproductor grande.
        final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
        if (cancion == null ||
            reproductor.pantallaCompletaAbierta ||
            tecladoAbierto) {
          return const SizedBox.shrink();
        }
        final progreso = reproductor.total == 0
            ? 0.0
            : reproductor.posicion / reproductor.total;

        return Material(
          color: colorTarjeta,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Línea fina de progreso arriba del mini-player.
                LinearProgressIndicator(
                  value: progreso.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: colorFondo,
                  color: colorAcento,
                ),
                InkWell(
                  onTap: abrirReproductor,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cancion.colorPortada,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cancion.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Mateo Cabral',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            reproductor.reproduciendo
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: colorAcento,
                            size: 30,
                          ),
                          tooltip: reproductor.reproduciendo
                              ? 'Pausar'
                              : 'Reproducir',
                          onPressed: reproductor.alternarPausa,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 28),
                          tooltip: 'Siguiente',
                          onPressed: reproductor.siguiente,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
