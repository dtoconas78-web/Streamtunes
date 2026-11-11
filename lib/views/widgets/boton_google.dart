import 'package:flutter/material.dart';

// Botón "Continuar/Registrarse con Google". Por ahora el login con Google es
// simulado (ver services/auth_service.dart); con backend real se conecta en
// AuthService y este botón no cambia (ver docs/AUTH_GOOGLE.md).
class BotonGoogle extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const BotonGoogle({super.key, required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const CircleAvatar(
          radius: 11,
          backgroundColor: Colors.white,
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        label: Text(texto),
        onPressed: onPressed,
      ),
    );
  }
}
