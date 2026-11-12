import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_perfil.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';

// Inicio del oyente (estilo Spotify/Apple Music): saludo, accesos rápidos,
// álbumes en grilla y canciones. Todo el catálogo se actualiza solo.
class InicioOyenteScreen extends StatelessWidget {
  const InicioOyenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nombre = authViewModel.usuario?.nombre ?? 'oyente';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [const BotonPerfil()],
      ),
      body: ListenableBuilder(
        listenable: catalogo,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Hola, $nombre',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Qué querés escuchar hoy?',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'Álbumes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
              children: [
                for (final album in catalogo.albumes)
                  GestureDetector(
                    onTap: () => irA(context, Rutas.album, argumentos: album),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: PortadaCuadrada(
                            color: colorDe(album.colorPortada),
                            tamano: double.infinity,
                            radio: 12,
                            icono: Icons.album,
                            tamanoIcono: 56,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          album.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${album.cancionIds.length} canciones · ${album.anio}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Canciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < catalogo.canciones.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PortadaCuadrada(
                  color: colorDe(catalogo.canciones[i].colorPortada),
                  tamano: 48,
                ),
                title: Text(catalogo.canciones[i].titulo),
                subtitle: Text(
                  formatoTiempo(catalogo.canciones[i].duracionSegundos),
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.play_circle, color: colorAcento),
                onTap: () => reproductor.reproducir(i),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
