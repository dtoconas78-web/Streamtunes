import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_perfil.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Mi biblioteca del oyente: playlists propias, artistas que sigo, entradas
// compradas, donaciones y álbumes. Todo se actualiza solo con los viewmodels.
class BibliotecaScreen extends StatelessWidget {
  const BibliotecaScreen({super.key});

  // Diálogo para crear una playlist nueva y abrirla enseguida.
  Future<void> _crearPlaylist(BuildContext context) async {
    final controlador = TextEditingController();
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorTarjeta,
        title: const Text('Nueva playlist'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.sentences,
          decoration: decoracionFormulario('Nombre de la playlist'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorAcento,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, controlador.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    controlador.dispose();
    if (nombre == null || nombre.trim().isEmpty || !context.mounted) return;
    final playlist = playlistsViewModel.crear(nombre);
    irA(context, Rutas.playlist, argumentos: playlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [const BotonPerfil()],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          playlistsViewModel,
          seguimientoViewModel,
          entradasViewModel,
          catalogo,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mis playlists',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorAcento,
                    side: const BorderSide(color: colorAcento),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => _crearPlaylist(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear playlist'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (playlistsViewModel.playlists.isEmpty)
              const Text(
                'Todavía no creaste ninguna playlist. Tocá "Crear playlist" para armar la tuya.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              for (final playlist in playlistsViewModel.playlists)
                Tarjeta(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const PortadaCuadrada(
                      color: colorAcento,
                      icono: Icons.queue_music,
                    ),
                    title: Text(playlist.nombre),
                    subtitle: Text(
                      '${playlist.cantidad} ${playlist.cantidad == 1 ? 'canción' : 'canciones'}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: () =>
                        irA(context, Rutas.playlist, argumentos: playlist),
                  ),
                ),
            const SizedBox(height: 20),
            const Text(
              'Artistas que sigo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (seguimientoViewModel.seguidos.isEmpty)
              const Text(
                'Todavía no seguís a nadie. Seguí a un artista para poder donarle (pantalla Donar).',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              for (final artista in seguimientoViewModel.seguidos)
                Tarjeta(
                  child: ListTile(
                    leading: PortadaCuadrada(
                      color: colorAcento,
                      icono: Icons.person,
                    ),
                    title: Text(artista.nombre),
                    subtitle: const Text(
                      'Le podés donar directo',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.volunteer_activism,
                      color: colorAcento,
                    ),
                    onTap: () => irA(context, Rutas.donar),
                  ),
                ),
            const SizedBox(height: 20),
            Tarjeta(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const PortadaCuadrada(
                  color: colorAcento,
                  icono: Icons.confirmation_number,
                ),
                title: const Text('Mis entradas'),
                subtitle: Text(
                  '${entradasViewModel.entradasCompradas.length} comprada(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => irA(context, Rutas.entradas),
              ),
            ),
            Tarjeta(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const PortadaCuadrada(
                  color: colorAcento,
                  icono: Icons.volunteer_activism,
                ),
                title: const Text('Donar al artista'),
                subtitle: const Text(
                  '100% va directo al artista que seguís',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => irA(context, Rutas.donar),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Álbumes que sigo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (seguimientoViewModel.albumesSeguidos.isEmpty)
              const Text(
                'Tocá el corazón en un álbum para seguirlo y verlo acá.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              )
            else
              for (final album in seguimientoViewModel.albumesSeguidos)
                Tarjeta(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: PortadaCuadrada(
                      color: colorDe(album.colorPortada),
                      icono: Icons.album,
                    ),
                    title: Text(album.titulo),
                    subtitle: Text(
                      '${album.cancionIds.length} canciones · ${album.anio}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.favorite,
                      color: colorAcento,
                      size: 20,
                    ),
                    onTap: () => irA(context, Rutas.album, argumentos: album),
                  ),
                ),
            const SizedBox(height: 20),
            const Text(
              'Todos los álbumes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final album in catalogo.albumes)
              Tarjeta(
                child: ListTile(
                  leading: PortadaCuadrada(
                    color: colorDe(album.colorPortada),
                    icono: Icons.album,
                  ),
                  title: Text(album.titulo),
                  subtitle: Text(
                    '${album.cancionIds.length} canciones · ${album.anio}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () => irA(context, Rutas.album, argumentos: album),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
