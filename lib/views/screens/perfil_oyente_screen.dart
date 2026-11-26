import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/inyeccion.dart';
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
          perfilOyenteViewModel,
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
              // Ciudad declarada: se usa en las estadísticas de los artistas.
              if (perfilOyenteViewModel.puedeDeclarar)
                Tarjeta(
                  child: ListTile(
                    leading: const Icon(Icons.place, color: colorAcento),
                    title: const Text('Mi ciudad'),
                    subtitle: Text(
                      perfilOyenteViewModel.ciudad.isEmpty
                          ? 'Sin declarar · ayudá a los artistas a saber dónde los escuchan'
                          : '${perfilOyenteViewModel.ciudad} · la ven los artistas en sus estadísticas (sin tu nombre)',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.edit, size: 18),
                    onTap: () => _editarCiudad(context),
                  ),
                ),
              if (perfilOyenteViewModel.puedeDeclarar)
                const SizedBox(height: 12),
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

Future<void> _editarCiudad(BuildContext context) async {
  final nueva = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoCiudad(inicial: perfilOyenteViewModel.ciudad),
  );
  if (nueva == null || !context.mounted) return;
  await perfilOyenteViewModel.guardarCiudad(nueva);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          perfilOyenteViewModel.ultimoError != null
              ? 'No se pudo guardar la ciudad. Probá de nuevo.'
              : 'Ciudad guardada',
        ),
      ),
    );
}

// Diálogo con su propio controlador (vive y muere con el diálogo).
class _DialogoCiudad extends StatefulWidget {
  const _DialogoCiudad({required this.inicial});

  final String inicial;

  @override
  State<_DialogoCiudad> createState() => _DialogoCiudadState();
}

class _DialogoCiudadState extends State<_DialogoCiudad> {
  late final _controlador = TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Desde qué ciudad escuchás?'),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Ej.: Mendoza',
          helperText: 'Para las estadísticas de los artistas. No usamos GPS.',
          helperMaxLines: 2,
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controlador.text),
          child: const Text('Guardar'),
        ),
      ],
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
