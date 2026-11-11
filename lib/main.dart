// StreamTunes - Demo de navegación (solo front, sin lógica real).

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

void main() => runApp(const MiApp());

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegadorKey,
      navigatorObservers: [ObservadorReproductor()],
      // builder envuelve TODAS las pantallas: el mini-player queda abajo siempre.
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: reproductor,
                builder: (context, _) {
                  final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
                  final miniVisible = reproductor.hayCancion &&
                      !reproductor.pantallaCompletaAbierta &&
                      !tecladoAbierto;
                  // Si el mini-player está visible, las pantallas no deben
                  // dejar margen inferior (ya lo ocupa el mini-player).
                  return MediaQuery.removePadding(
                    context: context,
                    removeBottom: miniVisible,
                    child: child!,
                  );
                },
              ),
            ),
            const MiniReproductor(),
          ],
        );
      },
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: colorFondo,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
