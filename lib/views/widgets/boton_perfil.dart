import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';

// Círculo con la inicial del perfil en la barra superior. Al tocarlo abre
// un desplegable debajo con: Perfil, Configuración y Cerrar sesión.
class BotonPerfil extends StatelessWidget {
  const BotonPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    final nombre = authViewModel.usuario?.nombre ?? '';
    final inicial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim()[0].toUpperCase();
    return PopupMenuButton<String>(
      color: colorTarjeta,
      offset: const Offset(0, 8),
      tooltip: 'Cuenta',
      // El hijo del PopupMenuButton es el botón que abre el menú.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: CircleAvatar(
          radius: 17,
          backgroundColor: colorAcento,
          child: Text(
            inicial,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'perfil',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.person_outline),
            title: Text('Perfil'),
          ),
        ),
        PopupMenuItem(
          value: 'configuracion',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Configuración'),
          ),
        ),
        PopupMenuItem(
          value: 'cerrar',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout, color: colorAcento),
            title: Text('Cerrar sesión'),
          ),
        ),
      ],
      onSelected: (opcion) {
        switch (opcion) {
          case 'perfil':
            irA(context, Rutas.perfilOyente);
          case 'configuracion':
            irA(context, Rutas.configuracion);
          case 'cerrar':
            cerrarSesion();
        }
      },
    );
  }
}
