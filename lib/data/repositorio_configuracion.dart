import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave de la preferencia "notificaciones activadas". Es por DISPOSITIVO
/// (como el permiso del sistema), no por usuario. La lee también la tarea en
/// segundo plano (tareas_segundo_plano_workmanager.dart).
const String claveNotificacionesActivas = 'streamtunes.config.notificaciones';

/// Preferencias de configuración que se guardan.
abstract class RepositorioConfiguracion {
  bool get notificaciones;
  Future<void> guardarNotificaciones(bool activas);
}

/// En memoria (tests, o sin guardado local).
class RepositorioConfiguracionMemoria implements RepositorioConfiguracion {
  RepositorioConfiguracionMemoria({this._notificaciones = false});

  bool _notificaciones;

  @override
  bool get notificaciones => _notificaciones;

  @override
  Future<void> guardarNotificaciones(bool activas) async {
    _notificaciones = activas;
  }
}

/// Guardada en el celular con shared_preferences.
class RepositorioConfiguracionPreferencias implements RepositorioConfiguracion {
  RepositorioConfiguracionPreferencias({required this._prefs});

  final SharedPreferences _prefs;

  @override
  bool get notificaciones =>
      _prefs.getBool(claveNotificacionesActivas) ?? false;

  @override
  Future<void> guardarNotificaciones(bool activas) async {
    try {
      await _prefs.setBool(claveNotificacionesActivas, activas);
    } catch (e) {
      debugPrint('No se pudo guardar la preferencia de notificaciones: $e');
    }
  }
}
