import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Perfil del oyente: datos de la cuenta y resumen de su actividad
// (playlists, artistas y álbumes seguidos, entradas).
class PantallaPerfilOyente extends StatelessWidget {
  const PantallaPerfilOyente({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          authViewModel,
          seguimientoViewModel,
          playlistsViewModel,
          entradasViewModel,
        ]),
        builder: (context, _) {
          final usuario = authViewModel.usuario;
          final nombre = usuario?.nombre ?? 'Oyente';
          final inicial = nombre.trim().isEmpty
              ? '?'
              : nombre.trim()[0].toUpperCase();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: colorAcento,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 36,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                usuario?.email ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Center(
                child: Chip(
                  label: Text(
                    usuario?.rol == RolUsuario.artista
                        ? 'Artista'
                        : usuario?.rol == RolUsuario.oyente
                        ? 'Oyente'
                        : 'Invitado',
                  ),
                  backgroundColor: colorTarjeta,
                  labelStyle: const TextStyle(color: colorAcento),
                ),
              ),
              const SizedBox(height: 24),
              Tarjeta(
                child: Column(
                  children: [
                    _FilaResumen(
                      icono: Icons.queue_music,
                      titulo: 'Mis playlists',
                      valor: '${playlistsViewModel.playlists.length}',
                    ),
                    const Divider(height: 1),
                    _FilaResumen(
                      icono: Icons.person,
                      titulo: 'Artistas que sigo',
                      valor: '${seguimientoViewModel.seguidos.length}',
                    ),
                    const Divider(height: 1),
                    _FilaResumen(
                      icono: Icons.favorite,
                      titulo: 'Álbumes que sigo',
                      valor: '${seguimientoViewModel.albumesSeguidos.length}',
                    ),
                    const Divider(height: 1),
                    _FilaResumen(
                      icono: Icons.confirmation_number,
                      titulo: 'Entradas compradas',
                      valor: '${entradasViewModel.entradasCompradas.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorAcento,
                    side: const BorderSide(color: colorAcento),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Configuración'),
                  onPressed: () => irA(context, Rutas.configuracion),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _FilaResumen({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: colorAcento),
      title: Text(titulo),
      trailing: Text(
        valor,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
