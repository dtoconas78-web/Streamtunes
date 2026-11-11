// Pantalla Biblioteca: tabs Playlists / Álbumes / Me gusta.

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/album_screen.dart';
import 'package:streamtunes_demo/views/screens/detalle_playlist.dart';
import 'package:streamtunes_demo/views/widgets/componentes.dart';

class PantallaBiblioteca extends StatelessWidget {
  const PantallaBiblioteca({super.key});

  // Pide el nombre, crea la playlist y la abre para poder agregarle canciones.
  Future<void> _nuevaPlaylist(BuildContext context) async {
    final nombre = await pedirNombrePlaylist(
      context,
      titulo: 'Nueva playlist',
      textoBoton: 'Crear',
    );
    if (nombre == null || !context.mounted) return;
    final playlist = gestorPlaylists.crear(nombre);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaDetallePlaylist(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tu biblioteca'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: colorAcento),
              tooltip: 'Nueva playlist',
              onPressed: () => _nuevaPlaylist(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: colorAcento,
            unselectedLabelColor: Colors.grey,
            indicatorColor: colorAcento,
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Álbumes'),
              Tab(text: 'Me gusta'),
            ],
          ),
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([reproductor, gestorPlaylists]),
          builder: (context, _) {
            return TabBarView(
              children: [
                _tabPlaylists(context),
                _tabAlbumes(context),
                _tabMeGusta(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tabPlaylists(BuildContext context) {
    final lista = gestorPlaylists.lista;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorAcento,
            side: const BorderSide(color: colorAcento),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nueva playlist'),
          onPressed: () => _nuevaPlaylist(context),
        ),
        const SizedBox(height: 16),
        if (lista.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Todavía no tenés playlists. Creá la primera con el botón de arriba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        for (final playlist in lista)
          FilaColeccion(
            color: playlist.color,
            icono: Icons.queue_music,
            titulo: playlist.nombre,
            subtitulo: etiquetaCanciones(playlist.indices.length),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaDetallePlaylist(playlist: playlist),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _tabAlbumes(BuildContext context) {
    if (albumes.isEmpty) {
      return const Center(
        child: Text('Todavía no hay álbumes', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final album in albumes)
          FilaColeccion(
            color: album.colorPortada,
            icono: Icons.album,
            titulo: album.titulo,
            subtitulo: '${etiquetaCanciones(album.indices.length)}, ${album.anio}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PantallaAlbum(album: album)),
              );
            },
          ),
      ],
    );
  }

  // Canciones marcadas con me gusta en el reproductor.
  Widget _tabMeGusta() {
    final indices = reproductor.meGustas.toList()..sort();
    if (indices.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Todavía no marcaste canciones con me gusta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [for (final indice in indices) FilaCancion(indice: indice)],
    );
  }
}
