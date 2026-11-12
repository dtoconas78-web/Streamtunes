import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';

// Pantalla Detalle de álbum: portada, datos, lista de canciones y el
// corazón para seguirlo (al seguirlo aparece en la Biblioteca).
class PantallaAlbum extends StatelessWidget {
  final Album album;

  const PantallaAlbum({super.key, required this.album});

  // Ids del álbum -> posiciones actuales en el catálogo.
  List<int> _indicesDelAlbum() => [
    for (final id in album.cancionIds)
      catalogo.canciones.indexWhere((c) => c.id == id),
  ].where((i) => i >= 0).toList();

  @override
  Widget build(BuildContext context) {
    final indices = _indicesDelAlbum();
    return Scaffold(
      appBar: AppBar(
        title: Text(album.titulo),
        actions: [
          // Corazón: seguir/dejar de seguir el álbum. Al seguirlo, aparece
          // en "Álbumes que sigo" de la Biblioteca.
          ListenableBuilder(
            listenable: seguimientoViewModel,
            builder: (context, _) {
              final sigo = seguimientoViewModel.sigoAlbum(album.id);
              return IconButton(
                icon: Icon(
                  sigo ? Icons.favorite : Icons.favorite_border,
                  color: sigo ? colorAcento : Colors.grey,
                ),
                tooltip: sigo ? 'Dejar de seguir álbum' : 'Seguir álbum',
                onPressed: () {
                  seguimientoViewModel.alternarAlbum(album.id);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        seguimientoViewModel.sigoAlbum(album.id)
                            ? 'Álbum "${album.titulo}" agregado a tu Biblioteca'
                            : 'Dejaste de seguir "${album.titulo}"',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      // ListenableBuilder: resalta la canción que está sonando.
      body: ListenableBuilder(
        listenable: reproductor,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: PortadaCuadrada(
                  color: colorDe(album.colorPortada),
                  tamano: 180,
                  radio: 16,
                  icono: Icons.album,
                  tamanoIcono: 72,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                album.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mateo Cabral',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                '${album.anio}, ${album.cancionIds.length} canciones',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Botón que reproduce el álbum completo como cola.
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorAcento,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproducir'),
                  onPressed: indices.isEmpty
                      ? null
                      : () => reproductor.reproducirCola(indices),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < album.cancionIds.length; i++)
                _FilaCancionAlbum(
                  numero: i + 1,
                  id: album.cancionIds[i],
                  onTap: indices.isEmpty
                      ? null
                      : () => reproductor.reproducirCola(indices, inicio: i),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Una fila de la lista de canciones del álbum.
class _FilaCancionAlbum extends StatelessWidget {
  final int numero;
  final String id; // id de la canción en el catálogo
  final VoidCallback? onTap;

  const _FilaCancionAlbum({required this.numero, required this.id, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Resolvemos el id a la posición actual del catálogo.
    final indice = catalogo.canciones.indexWhere((c) => c.id == id);
    if (indice < 0) return const SizedBox.shrink();
    final cancion = catalogo.canciones[indice];
    final sonando = reproductor.indiceActual == indice;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 28,
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(color: sonando ? colorAcento : Colors.grey),
          ),
        ),
      ),
      title: Text(
        cancion.titulo,
        style: TextStyle(
          color: sonando ? colorAcento : Colors.white,
          fontWeight: sonando ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: sonando
          ? const Icon(Icons.graphic_eq, color: colorAcento)
          : Text(
              formatoTiempo(cancion.duracionSegundos),
              style: const TextStyle(color: Colors.grey),
            ),
      // Reproduce el álbum desde esta canción (cola del álbum).
      onTap: onTap,
    );
  }
}
