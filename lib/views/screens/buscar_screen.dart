import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_perfil.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';

// Buscar: filtra en vivo canciones y álbumes del catálogo por texto.
class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});

  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final consulta = _query.trim().toLowerCase();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar'),
        actions: [const BotonPerfil()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Canciones, álbumes...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: colorTarjeta,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (texto) => setState(() => _query = texto),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: catalogo,
              builder: (context, _) {
                final canciones = catalogo.canciones
                    .where(
                      (c) =>
                          consulta.isEmpty ||
                          c.titulo.toLowerCase().contains(consulta),
                    )
                    .toList();
                final albumes = catalogo.albumes
                    .where(
                      (a) =>
                          consulta.isEmpty ||
                          a.titulo.toLowerCase().contains(consulta),
                    )
                    .toList();
                if (canciones.isEmpty && albumes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sin resultados',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (albumes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
                        child: Text(
                          'Álbumes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (final album in albumes)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PortadaCuadrada(
                            color: colorDe(album.colorPortada),
                            tamano: 48,
                            icono: Icons.album,
                          ),
                          title: Text(album.titulo),
                          subtitle: Text(
                            '${album.cancionIds.length} canciones · ${album.anio}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () =>
                              irA(context, Rutas.album, argumentos: album),
                        ),
                    ],
                    if (canciones.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(0, 12, 0, 4),
                        child: Text(
                          'Canciones',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      for (final cancion in canciones)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: PortadaCuadrada(
                            color: colorDe(cancion.colorPortada),
                            tamano: 48,
                          ),
                          title: Text(cancion.titulo),
                          subtitle: Text(
                            formatoTiempo(cancion.duracionSegundos),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(
                            Icons.play_circle,
                            color: colorAcento,
                          ),
                          onTap: () {
                            final indice = catalogo.canciones.indexWhere(
                              (c) => c.id == cancion.id,
                            );
                            if (indice >= 0) reproductor.reproducir(indice);
                          },
                        ),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
