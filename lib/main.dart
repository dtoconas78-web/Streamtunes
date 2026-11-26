import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/services/persistencia_local.dart';
import 'package:streamtunes_demo/theme/tema.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/views/screens/perfil_artista_screen.dart';
import 'package:streamtunes_demo/views/screens/explorar_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/oyente_shell.dart';
import 'package:streamtunes_demo/views/widgets/banner_sin_conexion.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

// Arranque: se inicializa Firebase primero (si está configurado); si no,
// la app arranca en modo demo con el auth simulado (ver services/firebase_inicial.dart).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await inicializarFirebase();
  // Abre el guardado local (playlists, seguidos y "me gusta"); si falla, la
  // app sigue en memoria (ver services/persistencia_local.dart).
  await inicializarPersistenciaLocal();
  // Activa el gestor de ciclo de vida (necesita el binding ya inicializado).
  inicializarCicloVida();
  // Inicializa las notificaciones locales (aviso de reproducción en pausa).
  await inicializarNotificaciones();
  // Inicializa workmanager (tareas periódicas en segundo plano, ver
  // services/tareas_segundo_plano_workmanager.dart).
  await inicializarTareasSegundoPlano();
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
            servicioConectividad,
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
                // Franja no invasiva cuando el dispositivo se queda sin red.
                BannerSinConexion(servicio: servicioConectividad),
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
