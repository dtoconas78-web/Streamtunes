import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Google no devuelve el rol de la cuenta: se elige antes de entrar o
// registrarse. Se usa igual desde la pantalla de acceso y desde el registro.
Future<RolUsuario?> elegirRol(BuildContext context, {required String titulo}) {
  return showModalBottomSheet<RolUsuario>(
    context: context,
    backgroundColor: colorTarjeta,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elegí el rol de esta cuenta:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            for (final r in [RolUsuario.artista, RolUsuario.oyente])
              ListTile(
                leading: Icon(
                  r == RolUsuario.artista ? Icons.mic : Icons.headphones,
                  color: colorAcento,
                ),
                title: Text(r == RolUsuario.artista ? 'Artista' : 'Oyente'),
                subtitle: Text(
                  r == RolUsuario.artista
                      ? 'Subo mi música, publico conciertos y veo mis ventas'
                      : 'Escucho gratis, compro entradas y apoyo directo al artista',
                ),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    ),
  );
}
