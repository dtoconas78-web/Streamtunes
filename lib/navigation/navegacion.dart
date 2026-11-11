import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/reproductor_screen.dart';

// Llave del Navigator: permite abrir pantallas desde el mini-player,
// que está por encima del Navigator y no tiene su propio contexto de navegación.
final GlobalKey<NavigatorState> navegadorKey = GlobalKey<NavigatorState>();

// Cierra sesión y limpia el stack: el home de main.dart reacciona solo al
// cambio de authViewModel y muestra la pantalla de acceso.
void cerrarSesion() {
  authViewModel.logout();
  navegadorKey.currentState?.popUntil((route) => route.isFirst);
}

// Abre el reproductor grande.
void abrirReproductor() {
  navegadorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/reproductor'),
      builder: (context) => const PantallaReproductor(),
    ),
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

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    reproductor.marcarPantallaCompleta(
      newRoute?.settings.name == '/reproductor',
    );
  }
}
