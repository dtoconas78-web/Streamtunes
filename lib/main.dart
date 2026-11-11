import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/perfil_artista_screen.dart';
import 'package:streamtunes_demo/views/screens/explorar_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/comprar_entrada_screen.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

void main() => runApp(const MiApp());

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegadorKey,
      navigatorObservers: [ObservadorReproductor()],
      onGenerateRoute: generarRuta,
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: reproductor,
                builder: (context, _) {
                  final tecladoAbierto =
                      MediaQuery.of(context).viewInsets.bottom > 0;
                  final miniVisible =
                      reproductor.hayCancion &&
                      !reproductor.pantallaCompletaAbierta &&
                      !tecladoAbierto;
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
      home: ListenableBuilder(
        listenable: authViewModel,
        builder: (context, _) {
          if (!authViewModel.estaLogueado) {
            return const LoginScreen();
          }
          // Invitado: solo puede escuchar.
          if (authViewModel.esInvitado) {
            return const ExplorarScreen();
          }
          if (authViewModel.esArtista) {
            return const PantallaA();
          }
          return const ComprarEntradaScreen();
        },
      ),
    );
  }
}
