import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/playlist.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_modo_reproduccion.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Pantalla de una playlist del oyente: reproducirla (en orden, aleatorio o
// solo la elegida), agregar canciones del catálogo, sacar canciones y
// renombrar/eliminar.
class PantallaPlaylist extends StatelessWidget {
  final Playlist playlist;

  const PantallaPlaylist({super.key, required this.playlist});

  // Ids de la playlist -> índices en el catálogo (para reproducir la cola).
  List<int> _indicesDe(Playlist p) => [
    for (final id in p.cancionIds)
      catalogo.canciones.indexWhere((c) => c.id == id),
  ].where((i) => i >= 0).toList();

  void _reproducirDesde(Playlist p, int posicion) {
    final indices = _indicesDe(p);
    if (indices.isEmpty) return;
    reproductor.reproducirCola(indices, inicio: posicion);
  }

  Future<void> _dialogoRenombrar(BuildContext context, Playlist p) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => _DialogoRenombrarPlaylist(
        nombreInicial: p.nombre,
        alAceptar: (v) => Navigator.pop(ctx, v),
        alCancelar: () => Navigator.pop(ctx),
      ),
    );
    if (nombre != null && nombre.trim().isNotEmpty && context.mounted) {
      playlistsViewModel.renombrar(p.id, nombre);
    }
  }

  Future<void> _confirmarEliminar(BuildContext context, Playlist p) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorTarjeta,
        title: const Text('Eliminar playlist'),
        content: Text('¿Seguro que querés eliminar "${p.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado == true && context.mounted) {
      playlistsViewModel.eliminar(p.id);
      Navigator.pop(context);
    }
  }

  // Hoja con todas las canciones del catálogo para agregar/quitar.
  void _hojaAgregarCanciones(BuildContext context, Playlist p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => ListenableBuilder(
          listenable: playlistsViewModel,
          builder: (ctx, _) {
            final actual = playlistsViewModel.porId(p.id);
            if (actual == null) {
              return const Center(child: Text('La playlist ya no existe'));
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Agregar canciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: catalogo.canciones.length,
                    itemBuilder: (ctx, i) {
                      final c = catalogo.canciones[i];
                      final enPlaylist = actual.cancionIds.contains(c.id);
                      return CheckboxListTile(
                        value: enPlaylist,
                        activeColor: colorAcento,
                        title: Text(c.titulo),
                        subtitle: Text(
                          formatoTiempo(c.duracionSegundos),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (_) {
                          if (enPlaylist) {
                            playlistsViewModel.quitarCancion(p.id, c.id);
                          } else {
                            playlistsViewModel.agregarCancion(p.id, c.id);
                          }
                        },
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playlistsViewModel,
      builder: (context, _) {
        final p = playlistsViewModel.porId(playlist.id) ?? playlist;
        final indices = _indicesDe(p);
        return Scaffold(
          appBar: AppBar(
            title: Text(p.nombre),
            actions: [
              PopupMenuButton<String>(
                color: colorTarjeta,
                onSelected: (opcion) {
                  if (opcion == 'renombrar') {
                    _dialogoRenombrar(context, p);
                  } else if (opcion == 'eliminar') {
                    _confirmarEliminar(context, p);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'renombrar', child: Text('Renombrar')),
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Text(
                      'Eliminar playlist',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Encabezado: portada, nombre, cantidad y acciones.
              Row(
                children: [
                  PortadaCuadrada(
                    color: colorAcento,
                    tamano: 110,
                    radio: 14,
                    icono: Icons.queue_music,
                    tamanoIcono: 56,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${p.cantidad} ${p.cantidad == 1 ? 'canción' : 'canciones'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Reproducir la playlist completa con el modo actual.
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorAcento,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: indices.isEmpty
                          ? null
                          : () => _reproducirDesde(p, 0),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text(
                        'Reproducir',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Modo de reproducción: en orden / aleatoria / solo esta.
                  const BotonModoReproduccion(),
                ],
              ),
              const SizedBox(height: 12),
              Tarjeta(
                child: ListTile(
                  leading: const PortadaCuadrada(
                    color: colorTarjeta,
                    icono: Icons.add,
                  ),
                  title: const Text('Agregar canciones'),
                  subtitle: const Text(
                    'Elegí del catálogo',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => _hojaAgregarCanciones(context, p),
                ),
              ),
              const SizedBox(height: 20),
              if (indices.isEmpty)
                const Text(
                  'Todavía no tiene canciones. Agregá algunas arriba.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                for (var i = 0; i < p.cancionIds.length; i++) ...[
                  Builder(
                    builder: (ctx) {
                      final indice = catalogo.canciones.indexWhere(
                        (c) => c.id == p.cancionIds[i],
                      );
                      if (indice < 0) return const SizedBox.shrink();
                      final c = catalogo.canciones[indice];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: PortadaCuadrada(
                          color: colorDe(c.colorPortada),
                          tamano: 48,
                        ),
                        title: Text(c.titulo),
                        subtitle: Text(
                          formatoTiempo(c.duracionSegundos),
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              playlistsViewModel.quitarCancion(p.id, c.id),
                        ),
                        onTap: () => _reproducirDesde(p, i),
                      );
                    },
                  ),
                ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// Diálogo "Renombrar playlist": el controller vive acá para no romper el
// árbol de widgets al cerrar el diálogo (ver _DialogoNuevaPlaylist en
// biblioteca_screen.dart).
class _DialogoRenombrarPlaylist extends StatefulWidget {
  final String nombreInicial;
  final void Function(String nombre) alAceptar;
  final VoidCallback alCancelar;

  const _DialogoRenombrarPlaylist({
    required this.nombreInicial,
    required this.alAceptar,
    required this.alCancelar,
  });

  @override
  State<_DialogoRenombrarPlaylist> createState() =>
      _DialogoRenombrarPlaylistState();
}

class _DialogoRenombrarPlaylistState extends State<_DialogoRenombrarPlaylist> {
  late final TextEditingController _controlador = TextEditingController(
    text: widget.nombreInicial,
  );

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorTarjeta,
      title: const Text('Renombrar playlist'),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        maxLength: 40,
        decoration: decoracionFormulario('Nombre de la playlist'),
        onSubmitted: widget.alAceptar,
      ),
      actions: [
        TextButton(
          onPressed: widget.alCancelar,
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorAcento,
            foregroundColor: Colors.black,
          ),
          onPressed: () => widget.alAceptar(_controlador.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
