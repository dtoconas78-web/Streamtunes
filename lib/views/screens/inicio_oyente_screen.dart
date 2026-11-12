import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.volunteer_activism),
            tooltip: 'Donar al artista',
            onPressed: () => irA(context, Rutas.donar),
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            tooltip: 'Comprar entrada',
            onPressed: () => irA(context, Rutas.comprarEntrada),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
        ],
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
            // Accesos rápidos: apoyar al artista y comprar entradas.
            Row(
              children: [
                Expanded(
                  child: _AccesoRapido(
                    icono: Icons.volunteer_activism,
                    titulo: 'Donar',
                    subtitulo: 'Al artista que seguís',
                    onTap: () => irA(context, Rutas.donar),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AccesoRapido(
                    icono: Icons.confirmation_number,
                    titulo: 'Entradas',
                    subtitulo: 'Próximos conciertos',
                    onTap: () => irA(context, Rutas.comprarEntrada),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
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

// Tarjeta chica de acceso rápido (Donar, Entradas).
class _AccesoRapido extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PortadaCuadrada(
                color: colorAcento,
                tamano: 40,
                icono: icono,
                tamanoIcono: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
