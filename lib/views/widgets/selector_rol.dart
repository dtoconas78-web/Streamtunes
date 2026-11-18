import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Selector de rol (Artista/Oyente) con dos ChoiceChip, usado en el
// formulario de login.
class SelectorRol extends StatelessWidget {
  const SelectorRol({super.key, required this.rol, required this.onChanged});

  final RolUsuario rol;
  final ValueChanged<RolUsuario> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Artista'),
            selected: rol == RolUsuario.artista,
            onSelected: (_) => onChanged(RolUsuario.artista),
            selectedColor: colorAcento,
            backgroundColor: colorTarjeta,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Oyente'),
            selected: rol == RolUsuario.oyente,
            onSelected: (_) => onChanged(RolUsuario.oyente),
            selectedColor: colorAcento,
            backgroundColor: colorTarjeta,
          ),
        ),
      ],
    );
  }
}
