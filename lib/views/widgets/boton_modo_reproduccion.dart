import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

// Botón del modo de reproducción: muestra el modo actual (en orden, aleatoria
// o solo esta canción) con ícono, texto y color distintos, y al tocarlo cicla
// al siguiente modo. Vive aparte para usar el mismo en álbum, playlist y
// reproductor grande.
class BotonModoReproduccion extends StatelessWidget {
  const BotonModoReproduccion({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final modo = reproductor.modo;
        // "En orden" es el modo neutro (gris); los otros se resaltan.
        final activo = modo != ModoReproduccion.enOrden;
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: activo ? colorAcento : Colors.grey,
            side: BorderSide(color: activo ? colorAcento : Colors.grey),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: const StadiumBorder(),
          ),
          onPressed: () {
            final nuevo = reproductor.alternarModo();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Modo de reproducción: ${nuevo.etiqueta}'),
              ),
            );
          },
          icon: Icon(modo.icono),
          label: Text(modo.etiqueta),
        );
      },
    );
  }
}
