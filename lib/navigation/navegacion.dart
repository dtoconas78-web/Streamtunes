import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

// Llave del Navigator: permite abrir pantallas desde el mini-player,
// que está por encima del Navigator y no tiene su propio contexto de navegación.
final GlobalKey<NavigatorState> navegadorKey = GlobalKey<NavigatorState>();

// Cierra sesión y limpia el stack: el home de main.dart reacciona solo al
// cambio de authViewModel y muestra la pantalla de acceso.
void cerrarSesion() {
  authViewModel.logout();
  reproductor.detener();
  navegadorKey.currentState?.popUntil((route) => route.isFirst);
}

// Abre el reproductor grande (ruta nombrada: el observador la reconoce igual).
void abrirReproductor() {
  navegadorKey.currentState?.pushNamed(Rutas.reproductor);
}

// Estado de navegación compartido: sabe si hay una ruta apilada encima del
// home (álbum, playlist, perfil...). Sirve para mostrar el mini-reproductor
// por encima de esa ruta (en el builder de main.dart) en vez de solo dentro
// del shell del oyente.
class EstadoNavegacion extends ChangeNotifier {
  bool _hayRutaSuperpuesta = false;
  bool get hayRutaSuperpuesta => _hayRutaSuperpuesta;

  void actualizar() {
    final valor = navegadorKey.currentState?.canPop() ?? false;
    if (valor == _hayRutaSuperpuesta) return;
    _hayRutaSuperpuesta = valor;
    // didPush/didPop también se llaman durante el build inicial del Navigator:
    // notificar ahí rompe el build, así que se difiere al próximo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });
  }
}

final EstadoNavegacion estadoNavegacion = EstadoNavegacion();

// Avisa al controlador cuando el reproductor grande se abre o se cierra.
class ObservadorReproductor extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(route.settings.name == '/reproductor');
    estadoNavegacion.actualizar();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(
      previousRoute?.settings.name == '/reproductor',
    );
    estadoNavegacion.actualizar();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    reproductor.marcarPantallaCompleta(
      newRoute?.settings.name == '/reproductor',
    );
    estadoNavegacion.actualizar();
  }
}
