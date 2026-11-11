import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';

// Pantalla Detalle de álbum: portada, datos y lista de canciones.
class PantallaAlbum extends StatelessWidget {
  final Album album;

  const PantallaAlbum({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.titulo)),
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
                '${album.anio}, ${album.indices.length} canciones',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Botón que reproduce el álbum desde la primera canción.
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
                  onPressed: () => reproductor.reproducir(album.indices.first),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < album.indices.length; i++)
                _FilaCancionAlbum(numero: i + 1, indice: album.indices[i]),
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
  final int indice; // posición en la lista `canciones`

  const _FilaCancionAlbum({required this.numero, required this.indice});

  @override
  Widget build(BuildContext context) {
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
          : Text(cancion.duracion, style: const TextStyle(color: Colors.grey)),
      // Reproduce y se queda en la pantalla: aparece el mini-player abajo.
      onTap: () => reproductor.reproducir(indice),
    );
  }
}
