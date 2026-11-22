import 'package:flutter/widgets.dart';

/// Abstracción mínima del listener de ciclo de vida: permite inyectar un
/// falso en los tests sin necesidad del WidgetsBinding real.
abstract class CicloVidaListener {
  void dispose();
}

/// Envoltura real sobre AppLifecycleListener de Flutter.
class _AppLifecycleListenerReal implements CicloVidaListener {
  _AppLifecycleListenerReal(void Function(AppLifecycleState) alCambiar)
    : _interno = AppLifecycleListener(onStateChange: alCambiar);

  final AppLifecycleListener _interno;

  @override
  void dispose() => _interno.dispose();
}

/// Gestor del ciclo de vida de la app.
///
/// Envuelve un listener de ciclo de vida y deja registrar callbacks de
/// "pausar" y "reanudar" que se ejecutan cuando la app pasa a segundo plano
/// (paused/hidden/detached) y cuando vuelve al frente (resumed). Así las
/// tareas activas (timers, refrescos, reproducción) se frenan y reanudan sin
/// que cada pantalla se acople al ciclo de vida del sistema operativo.
class GestorCicloVida {
  GestorCicloVida({CicloVidaListener? listener}) {
    _listener = listener ?? _AppLifecycleListenerReal(manejarEstado);
  }

  CicloVidaListener? _listener;
  final List<VoidCallback> _alPausar = <VoidCallback>[];
  final List<VoidCallback> _alReanudar = <VoidCallback>[];
  bool _enSegundoPlano = false;

  /// true mientras la app está en segundo plano.
  bool get enSegundoPlano => _enSegundoPlano;

  /// Cantidad de callbacks registrados (sirve para verificar el registro).
  int get cantidadSuscriptos => _alPausar.length + _alReanudar.length;

  /// Registra un par de callbacks de ciclo de vida. Se pueden registrar varios.
  void registrar({VoidCallback? alPausar, VoidCallback? alReanudar}) {
    if (alPausar != null) _alPausar.add(alPausar);
    if (alReanudar != null) _alReanudar.add(alReanudar);
  }

  /// Punto de entrada del listener. Queda expuesto para poder disparar
  /// estados a mano en los tests sin binding real.
  @visibleForTesting
  void manejarEstado(AppLifecycleState estado) {
    switch (estado) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      // Al desconectarse (app cerrándose) también conviene frenar tareas.
      case AppLifecycleState.detached:
        _enSegundoPlano = true;
        for (final callback in List.of(_alPausar)) {
          callback();
        }
      case AppLifecycleState.resumed:
        // Un "resumed" sin pausa previa no dispara nada.
        if (!_enSegundoPlano) return;
        _enSegundoPlano = false;
        for (final callback in List.of(_alReanudar)) {
          callback();
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Libera el listener y limpia los callbacks registrados.
  void dispose() {
    _listener?.dispose();
    _listener = null;
    _alPausar.clear();
    _alReanudar.clear();
  }
}
