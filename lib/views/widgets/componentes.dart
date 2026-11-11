// Widgets reutilizados por Inicio, Buscar, Biblioteca y Detalle de playlist.

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

// Título de sección ("Tendencias", "Tus playlists", etc.).
class TituloSeccion extends StatelessWidget {
  final String texto;

  const TituloSeccion(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Lista horizontal para los carruseles de portadas.
class Carrusel extends StatelessWidget {
  final int cantidad;
  final Widget Function(int posicion) item;

  const Carrusel({super.key, required this.cantidad, required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 204,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cantidad,
        separatorBuilder: (context, posicion) => const SizedBox(width: 12),
        itemBuilder: (context, posicion) => item(posicion),
      ),
    );
  }
}

// Portada cuadrada con título y subtítulo debajo (para los carruseles).
class PortadaCuadrada extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const PortadaCuadrada({
    super.key,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 48, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    );
  }
}

// Card con la misma forma que usa la lista de canciones del perfil.
class _TarjetaBase extends StatelessWidget {
  final Widget child;

  const _TarjetaBase({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorTarjeta,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

// Fila de una canción. `indice` es la posición en la lista `canciones`.
// Por defecto, al tocarla suena; se puede cambiar con `onTap`.
class FilaCancion extends StatelessWidget {
  final int indice;
  final Widget? trailing;
  final VoidCallback? onTap;

  const FilaCancion({super.key, required this.indice, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cancion = canciones[indice];
    // Escucha al reproductor para resaltar la canción que está sonando.
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final sonando = reproductor.indiceActual == indice;
        return _TarjetaBase(
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cancion.colorPortada,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.black),
            ),
            title: Text(
              cancion.titulo,
              style: TextStyle(
                color: sonando ? colorAcento : Colors.white,
                fontWeight: sonando ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              cancion.publica
                  ? '${perfil.nombre}, ${cancion.duracion}'
                  : '${perfil.nombre}, ${cancion.duracion}, privada',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: trailing ??
                (sonando ? const Icon(Icons.graphic_eq, color: colorAcento) : null),
            onTap: onTap ?? () => reproductor.reproducir(indice),
          ),
        );
      },
    );
  }
}

// Fila de una colección (álbum o playlist) con chevron.
class FilaColeccion extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const FilaColeccion({
    super.key,
    required this.color,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TarjetaBase(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.black),
        ),
        title: Text(titulo),
        subtitle: Text(subtitulo, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// Diálogo para pedir el nombre de una playlist (crear o renombrar).
// Devuelve el nombre, o null si se cancela.
Future<String?> pedirNombrePlaylist(
  BuildContext context, {
  required String titulo,
  required String textoBoton,
  String inicial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _DialogoNombre(
      titulo: titulo,
      textoBoton: textoBoton,
      inicial: inicial,
    ),
  );
}

// Es Stateful para que el TextEditingController se cree y se libere con el diálogo.
class _DialogoNombre extends StatefulWidget {
  final String titulo;
  final String textoBoton;
  final String inicial;

  const _DialogoNombre({
    required this.titulo,
    required this.textoBoton,
    required this.inicial,
  });

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late final TextEditingController _controlador =
      TextEditingController(text: widget.inicial);

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final nombre = _controlador.text.trim();
    if (nombre.isEmpty) return;
    Navigator.pop(context, nombre);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorTarjeta,
      title: Text(widget.titulo),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
        onSubmitted: (_) => _confirmar(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: _confirmar,
          child: Text(widget.textoBoton, style: const TextStyle(color: colorAcento)),
        ),
      ],
    );
  }
}
