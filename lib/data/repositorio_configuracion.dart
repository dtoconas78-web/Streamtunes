import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave de la preferencia "notificaciones activadas". Es por DISPOSITIVO
/// (como el permiso del sistema), no por usuario. La lee también la tarea en
/// segundo plano (tareas_segundo_plano_workmanager.dart).
const String claveNotificacionesActivas = 'streamtunes.config.notificaciones';

/// Preferencias de configuración que se guardan.
abstract class RepositorioConfiguracion {
  /// Lee lo guardado (una vez al arrancar, antes de crear el ViewModel).
  Future<void> cargar();

  bool get notificaciones;
  Future<void> guardarNotificaciones(bool activas);
}

/// En memoria (tests, o sin guardado local).
class RepositorioConfiguracionMemoria implements RepositorioConfiguracion {
  RepositorioConfiguracionMemoria({this._notificaciones = false});

  bool _notificaciones;

  @override
  Future<void> cargar() async {}

  @override
  bool get notificaciones => _notificaciones;

  @override
  Future<void> guardarNotificaciones(bool activas) async {
    _notificaciones = activas;
  }
}

/// Guardada en el celular con [SharedPreferencesAsync]. Como la lectura es
/// asíncrona, [cargar] deja el valor en memoria y [notificaciones] lo
/// devuelve sin esperar.
class RepositorioConfiguracionPreferencias implements RepositorioConfiguracion {
  RepositorioConfiguracionPreferencias({required this._prefs});

  final SharedPreferencesAsync _prefs;
  bool _notificaciones = false;

  @override
  Future<void> cargar() async {
    try {
      _notificaciones =
          await _prefs.getBool(claveNotificacionesActivas) ?? false;
    } catch (e) {
      debugPrint('No se pudo leer la preferencia de notificaciones: $e');
    }
  }

  @override
  bool get notificaciones => _notificaciones;

  @override
  Future<void> guardarNotificaciones(bool activas) async {
    _notificaciones = activas;
    try {
      await _prefs.setBool(claveNotificacionesActivas, activas);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia de notificaciones: $e');
    }
  }
}
