// Pantalla Detalle de playlist: portada, datos, reproducir / aleatorio,
// lista de canciones (quitar con Deshacer) y agregar canciones.

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/models/playlist.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/componentes.dart';

class PantallaDetallePlaylist extends StatelessWidget {
  final Playlist playlist;

  const PantallaDetallePlaylist({super.key, required this.playlist});

  Future<void> _renombrar(BuildContext context) async {
    final nuevo = await pedirNombrePlaylist(
      context,
      titulo: 'Renombrar playlist',
      textoBoton: 'Guardar',
      inicial: playlist.nombre,
    );
    if (nuevo != null) gestorPlaylists.renombrar(playlist, nuevo);
  }

  Future<void> _eliminar(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorTarjeta,
        title: const Text('Eliminar playlist'),
        content: Text('¿Eliminar “${playlist.nombre}”? Las canciones no se borran.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: colorAcento)),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final mensajero = ScaffoldMessenger.of(context);
    final nombre = playlist.nombre;
    gestorPlaylists.eliminar(playlist);
    Navigator.pop(context);
    mensajero.showSnackBar(SnackBar(content: Text('Eliminaste “$nombre”')));
  }

  void _quitar(BuildContext context, int posicion) {
    final indice = playlist.indices[posicion];
    gestorPlaylists.quitarCancion(playlist, posicion);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Quitaste “${canciones[indice].titulo}”'),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: colorAcento,
            onPressed: () => gestorPlaylists.insertarCancion(playlist, posicion, indice),
          ),
        ),
      );
  }

  void _aleatorio() {
    if (playlist.indices.isEmpty) return;
    final elegida = playlist.indices[Random().nextInt(playlist.indices.length)];
    reproductor.reproducir(elegida);
  }

  void _agregar(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorTarjeta,
      isScrollControlled: true,
      builder: (context) => _HojaAgregar(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se redibuja si cambia la playlist o lo que está sonando.
    return ListenableBuilder(
      listenable: Listenable.merge([gestorPlaylists, reproductor]),
      builder: (context, _) {
        final indices = playlist.indices;
        final totalSegundos = indices.fold<int>(
          0,
          (suma, i) => suma + aSegundos(canciones[i].duracion),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(playlist.nombre),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Más opciones',
                onSelected: (opcion) {
                  if (opcion == 'renombrar') _renombrar(context);
                  if (opcion == 'eliminar') _eliminar(context);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'renombrar', child: Text('Renombrar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar playlist')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: playlist.color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.queue_music, size: 72, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                playlist.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (playlist.descripcion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  playlist.descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                '${etiquetaCanciones(indices.length)}, ${formatearTotal(totalSegundos)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Reproducir (desde la primera) y Aleatorio.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAcento,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reproducir'),
                    onPressed: indices.isEmpty
                        ? null
                        : () => reproductor.reproducir(indices.first),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorAcento,
                      side: const BorderSide(color: colorAcento),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Aleatorio'),
                    onPressed: indices.isEmpty ? null : _aleatorio,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => _agregar(context),
                  icon: const Icon(Icons.add, size: 18, color: colorAcento),
                  label: const Text(
                    'Agregar canciones',
                    style: TextStyle(color: colorAcento),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (indices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Esta playlist está vacía. Agregale canciones con el botón de arriba.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              for (int posicion = 0; posicion < indices.length; posicion++)
                FilaCancion(
                  indice: indices[posicion],
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                    tooltip: 'Quitar de la playlist',
                    onPressed: () => _quitar(context, posicion),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Hoja inferior con las canciones que todavía no están en la playlist.
class _HojaAgregar extends StatelessWidget {
  final Playlist playlist;

  const _HojaAgregar({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: ListenableBuilder(
          listenable: gestorPlaylists,
          builder: (context, _) {
            final disponibles = [
              for (int i = 0; i < canciones.length; i++)
                if (!gestorPlaylists.contiene(playlist, i)) i,
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Agregar canciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (disponibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Ya agregaste todas las canciones.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: disponibles.length,
                      itemBuilder: (context, posicion) {
                        final indice = disponibles[posicion];
                        final cancion = canciones[indice];
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cancion.colorPortada,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.black),
                          ),
                          title: Text(cancion.titulo),
                          subtitle: Text(
                            cancion.duracion,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: colorAcento),
                            tooltip: 'Agregar',
                            onPressed: () => gestorPlaylists.agregarCancion(playlist, indice),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
