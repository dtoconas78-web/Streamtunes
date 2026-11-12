import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/requiere_registro.dart';

// Pantalla Reproductor: portada, controles y barra de progreso.
// No guarda estado propio: lee_todo del controlador global.
class PantallaReproductor extends StatelessWidget {
  const PantallaReproductor({super.key});

  void _avisar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final cancion = reproductor.cancion;
        if (cancion == null) return const Scaffold();
        final total = reproductor.total;
        final posicion = reproductor.posicion;
        final leGusta = reproductor.leGusta;

        return Scaffold(
          appBar: AppBar(
            // Flecha hacia abajo: cierra el reproductor y vuelve a donde estabas.
            // La música sigue sonando en el mini-player.
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 30),
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Reproduciendo'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: colorAcento),
                tooltip: 'Compartir',
                onPressed: () =>
                    _avisar(context, 'Compartiendo "${cancion.titulo}"...'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Portada grande: es lo más importante de la pantalla.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorDe(cancion.colorPortada),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            size: 96,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Título, artista y botón de "me gusta".
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cancion.titulo,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mateo Cabral',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          leGusta ? Icons.favorite : Icons.favorite_border,
                          color: colorAcento,
                          size: 28,
                        ),
                        tooltip: leGusta ? 'Quitar de guardados' : 'Guardar',
                        onPressed: () {
                          // Guardar es solo para cuentas registradas.
                          if (authViewModel.esInvitado) {
                            mostrarDialogoRegistro(
                              context,
                              'guardar canciones',
                            );
                          } else {
                            reproductor.alternarMeGusta();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de progreso: se puede arrastrar para saltar a otro momento.
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorAcento,
                      inactiveTrackColor: colorTarjeta,
                      thumbColor: colorAcento,
                      overlayColor: colorAcento.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 0,
                      max: total.toDouble(),
                      value: posicion.clamp(0, total).toDouble(),
                      onChanged: (valor) => reproductor.saltarA(valor.round()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatoTiempo(posicion),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          formatoTiempo(total),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controles: anterior, play/pausa, siguiente.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Anterior',
                        onPressed: reproductor.anterior,
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: const BoxDecoration(
                          color: colorAcento,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 44,
                          padding: const EdgeInsets.all(14),
                          color: Colors.black,
                          icon: Icon(
                            reproductor.reproduciendo
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          tooltip: reproductor.reproduciendo
                              ? 'Pausar'
                              : 'Reproducir',
                          onPressed: reproductor.alternarPausa,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Siguiente',
                        onPressed: reproductor.siguiente,
                      ),
                      const SizedBox(width: 12),
                      // Modo de reproducción de la cola: en orden o aleatoria.
                      IconButton(
                        iconSize: 26,
                        icon: Icon(reproductor.modo.icono),
                        color: reproductor.modo == ModoReproduccion.aleatorio
                            ? colorAcento
                            : Colors.grey,
                        tooltip: 'Modo: ${reproductor.modo.etiqueta}',
                        onPressed: reproductor.alternarModo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Apoyo directo al artista (el pago real se conecta en la fase 2).
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorAcento,
                        side: const BorderSide(color: colorAcento),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Apoyar a Mateo Cabral'),
                      onPressed: () {
                        // Donar es solo para cuentas registradas; además,
                        // en Donar se aplica la regla de seguir al artista.
                        if (authViewModel.esInvitado) {
                          mostrarDialogoRegistro(context, 'apoyar al artista');
                        } else {
                          irA(context, Rutas.donar);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
