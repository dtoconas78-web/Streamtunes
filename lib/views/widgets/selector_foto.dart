import 'dart:io';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/inyeccion.dart' as inyeccion;
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/services/fuente_de_fotos.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/foto_viewmodel.dart';

/// Pregunta de dónde sacar la foto (cámara o galería, y "Quitar" si ya hay
/// una) y se la pide a [vm]. Avisa con un SnackBar si no está disponible o
/// si falló; si el usuario cancela, no pasa nada.
Future<void> cambiarFoto(
  BuildContext context,
  FotoViewModel vm, {
  required String titulo,
  bool permitirQuitar = true,
  Capacidades? capacidades,
  Politicas? politicas,
}) async {
  final caps = capacidades ?? inyeccion.capacidades;
  final pols = politicas ?? inyeccion.politicas;
  void avisar(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));

  if (!caps.camara) {
    avisar(pols.avisoCamaraNoDisponible);
    return;
  }
  final opcion = await showModalBottomSheet<_OpcionFoto>(
    context: context,
    builder: (hoja) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: colorAcento),
            title: const Text('Sacar una foto'),
            onTap: () => Navigator.pop(hoja, _OpcionFoto.camara),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: colorAcento),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(hoja, _OpcionFoto.galeria),
          ),
          if (permitirQuitar && vm.tieneFoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.grey),
              title: const Text('Quitar foto'),
              onTap: () => Navigator.pop(hoja, _OpcionFoto.quitar),
            ),
        ],
      ),
    ),
  );
  switch (opcion) {
    case null:
      return;
    case _OpcionFoto.quitar:
      await vm.quitar();
    case _OpcionFoto.camara || _OpcionFoto.galeria:
      final resultado = await vm.elegir(
        opcion == _OpcionFoto.camara ? OrigenFoto.camara : OrigenFoto.galeria,
      );
      if (!context.mounted) return;
      if (resultado is FotoFallida || vm.ultimoError != null) {
        avisar(pols.avisoFotoFallida);
      }
  }
}

enum _OpcionFoto { camara, galeria, quitar }

/// Avatar redondo: la foto si hay [ruta] (y el archivo existe), si no el
/// ícono de persona.
class AvatarFoto extends StatelessWidget {
  const AvatarFoto({super.key, required this.ruta, this.radio = 45});

  final String? ruta;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final r = ruta;
    return CircleAvatar(
      radius: radio,
      backgroundColor: colorTarjeta,
      foregroundImage: r == null ? null : FileImage(File(r)),
      // Si la imagen no se puede leer, queda el ícono de fondo.
      onForegroundImageError: r == null ? null : (_, _) {},
      child: Icon(Icons.person, size: radio, color: colorAcento),
    );
  }
}
