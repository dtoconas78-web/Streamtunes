import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Mi biblioteca del oyente: artistas que sigo, entradas compradas,
// donaciones y álbumes. Todo se actualiza solo con los viewmodels.
class BibliotecaScreen extends StatelessWidget {
  const BibliotecaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          seguimientoViewModel,
          entradasViewModel,
          catalogo,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
              'Álbumes',
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
