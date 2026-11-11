// Pantalla Inicio: saludo, "seguir escuchando", tendencias, playlists, álbumes
// y lo último que se subió.

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/album_screen.dart';
import 'package:streamtunes_demo/views/screens/comprar_entrada_screen.dart';
import 'package:streamtunes_demo/views/screens/detalle_playlist.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/widgets/componentes.dart';

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // "+12% esta semana" -> 12
  int _porcentaje(Cancion cancion) =>
      int.tryParse(RegExp(r'\d+').firstMatch(cancion.tendencia)?.group(0) ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'StreamTunes',
          style: TextStyle(fontWeight: FontWeight.bold, color: colorAcento),
        ),
        actions: [
          // Conciertos y entradas (la pantalla que ya existía para el oyente).
          IconButton(
            icon: const Icon(Icons.confirmation_number, color: colorAcento),
            tooltip: 'Conciertos y entradas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComprarEntradaScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              authViewModel.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([reproductor, gestorPlaylists]),
        builder: (context, _) {
          // Solo canciones públicas; las privadas no se muestran en el descubrimiento.
          final publicas = [
            for (int i = 0; i < canciones.length; i++)
              if (canciones[i].publica) i,
          ];
          final tendencias = [...publicas]
            ..sort((a, b) => _porcentaje(canciones[b]).compareTo(_porcentaje(canciones[a])));
          final recientes = publicas.reversed.take(3).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  authViewModel.usuario == null
                      ? _saludo()
                      : '${_saludo()}, ${authViewModel.usuario!.nombre}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              // Seguir escuchando: la canción actual, con pausa/play.
              const TituloSeccion('Seguir escuchando'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: reproductor.hayCancion
                    ? FilaCancion(
                        indice: reproductor.indiceActual!,
                        onTap: abrirReproductor,
                        trailing: IconButton(
                          icon: Icon(
                            reproductor.reproduciendo ? Icons.pause : Icons.play_arrow,
                            color: colorAcento,
                          ),
                          tooltip: reproductor.reproduciendo ? 'Pausar' : 'Reproducir',
                          onPressed: reproductor.alternarPausa,
                        ),
                      )
                    : const Text(
                        'Elegí una canción para empezar a escuchar.',
                        style: TextStyle(color: Colors.grey),
                      ),
              ),

              // Tendencias: ordenadas por el crecimiento de la semana.
              if (tendencias.isNotEmpty) ...[
                const TituloSeccion('Tendencias'),
                Carrusel(
                  cantidad: tendencias.length,
                  item: (posicion) {
                    final indice = tendencias[posicion];
                    final cancion = canciones[indice];
                    return PortadaCuadrada(
                      color: cancion.colorPortada,
                      icono: Icons.music_note,
                      titulo: cancion.titulo,
                      subtitulo: cancion.tendencia,
                      onTap: () => reproductor.reproducir(indice),
                    );
                  },
                ),
              ],

              if (gestorPlaylists.lista.isNotEmpty) ...[
                const TituloSeccion('Tus playlists'),
                Carrusel(
                  cantidad: gestorPlaylists.lista.length,
                  item: (posicion) {
                    final playlist = gestorPlaylists.lista[posicion];
                    return PortadaCuadrada(
                      color: playlist.color,
                      icono: Icons.queue_music,
                      titulo: playlist.nombre,
                      subtitulo: etiquetaCanciones(playlist.indices.length),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PantallaDetallePlaylist(playlist: playlist),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

              if (albumes.isNotEmpty) ...[
                const TituloSeccion('Álbumes'),
                Carrusel(
                  cantidad: albumes.length,
                  item: (posicion) {
                    final album = albumes[posicion];
                    return PortadaCuadrada(
                      color: album.colorPortada,
                      icono: Icons.album,
                      titulo: album.titulo,
                      subtitulo: album.anio,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PantallaAlbum(album: album),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],

              // Últimas canciones públicas de la lista (las nuevas se agregan al final).
              if (recientes.isNotEmpty) ...[
                const TituloSeccion('Recién subidas'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [for (final indice in recientes) FilaCancion(indice: indice)],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
