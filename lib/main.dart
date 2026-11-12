import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/theme/tema.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/perfil_artista_screen.dart';
import 'package:streamtunes_demo/views/screens/explorar_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/oyente_shell.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

// Arranque: se inicializa Firebase primero (si está configurado); si no,
// la app arranca en modo demo con el auth simulado (ver services/firebase_inicial.dart).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarFirebase();
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navegadorKey,
      navigatorObservers: [ObservadorReproductor()],
      onGenerateRoute: generarRuta,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            reproductor,
            authViewModel,
            estadoNavegacion,
          ]),
          builder: (context, _) {
            final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
            final miniVisible =
                reproductor.hayCancion &&
                !reproductor.pantallaCompletaAbierta &&
                !tecladoAbierto;
            // El oyente ve el mini-reproductor dentro del shell (encima de la
            // barra inferior) cuando está en el home; si hay una ruta apilada
            // (álbum, playlist...) va acá, abajo de todo, por encima de ella.
            // Invitado/artista siempre lo ven abajo de todo.
            final miniAqui =
                miniVisible &&
                (!authViewModel.esOyente ||
                    estadoNavegacion.hayRutaSuperpuesta);
            return Column(
              children: [
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: miniAqui,
                    child: child!,
                  ),
                ),
                if (miniAqui) const MiniReproductor(),
              ],
            );
          },
        );
      },
      theme: temaApp,
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
          // Oyente registrado: arranca en Inicio con la barra inferior.
          return const OyenteShell();
        },
      ),
    );
  }
}
