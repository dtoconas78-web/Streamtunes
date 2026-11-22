import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de notificaciones locales de la app.
///
/// Hoy se usa para un solo caso: avisar con una notificación fija que la
/// reproducción quedó en pausa porque la app se fue a segundo plano (así se
/// ve desde la bandeja de notificaciones). La interfaz existe para poder
/// inyectar un falso en los tests sin tocar el plugin real.
///
/// Ojo: esto NO es el mecanismo de notificaciones que el usuario activa en
/// configuración (ese sigue sin estar implementado, ver
/// Capacidades.notificacionesDisponibles en lib/plataforma/plataforma.dart).
abstract class ServicioNotificaciones {
  /// Inicializa el plugin (hay que llamarlo una vez al arrancar la app).
  Future<void> inicializar();

  /// Muestra la notificación fija de "reproduciendo en pausa".
  Future<void> mostrarReproduccionEnPausa(String tituloCancion);

  /// Oculta la notificación de reproducción.
  Future<void> ocultarReproduccion();
}

/// Implementación real con flutter_local_notifications (Android).
class ServicioNotificacionesLocal implements ServicioNotificaciones {
  ServicioNotificacionesLocal({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _idReproduccion = 1;
  static const String _canalId = 'reproduccion_segundo_plano';
  bool _inicializado = false;

  @override
  Future<void> inicializar() async {
    if (_inicializado) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _inicializado = true;
  }

  @override
  Future<void> mostrarReproduccionEnPausa(String tituloCancion) async {
    await inicializar();
    await _plugin.show(
      id: _idReproduccion,
      title: 'StreamTunes',
      body: 'En pausa: $tituloCancion',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          'Reproducción en segundo plano',
          channelDescription: 'Aviso de que la música quedó pausada al mandar la app a segundo plano',
          ongoing: true,
          autoCancel: false,
        ),
      ),
    );
  }

  @override
  Future<void> ocultarReproduccion() => _plugin.cancel(id: _idReproduccion);
}
