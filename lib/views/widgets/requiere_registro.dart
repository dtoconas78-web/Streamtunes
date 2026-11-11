import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Diálogo para invitados: cuando toca una función de cuenta, se explica
// qué falta y se ofrece crear la cuenta gratis (o seguir como invitado).
Future<void> mostrarDialogoRegistro(BuildContext context, String accion) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorTarjeta,
      title: const Text('Necesitás una cuenta'),
      content: Text(
        'Para $accion necesitás una cuenta. Es gratis: además de escuchar, vas a poder $accion.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Ahora no', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorAcento,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            irA(context, Rutas.registro);
          },
          child: const Text('Crear cuenta gratis'),
        ),
      ],
    ),
  );
}
