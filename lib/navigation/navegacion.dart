import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/reproductor_screen.dart';

// Llave del Navigator: permite abrir pantallas desde el mini-player,
// que está por encima del Navigator y no tiene su propio contexto de navegación.
final GlobalKey<NavigatorState> navegadorKey = GlobalKey<NavigatorState>();

// Abre el reproductor grande.
void abrirReproductor() {
  navegadorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/reproductor'),
      builder: (context) => const PantallaReproductor(),
    ),
  );
}

// Cierra la sesión: corta la música y deja el login como única pantalla,
// para que el botón "atrás" no vuelva a pantallas de la sesión anterior.
void cerrarSesion() {
  authViewModel.logout();
  reproductor.detener();
  navegadorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (route) => false,
  );
}

// Avisa al controlador cuando el reproductor grande se abre o se cierra.
class ObservadorReproductor extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(route.settings.name == '/reproductor');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(
      previousRoute?.settings.name == '/reproductor',
    );
  }
}
