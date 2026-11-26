import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:timezone/timezone.dart' as tz;

/// Servicio de notificaciones locales de la app.
///
/// Caso fijo: avisar con una notificación fija que la reproducción quedó en
/// pausa porque la app se fue a segundo plano (así se ve desde la bandeja de
/// notificaciones). La interfaz existe para poder inyectar un falso en los
/// tests sin tocar el plugin real.
///
/// Las notificaciones que el usuario activa en Configuración (permiso,
/// recordatorios de conciertos y novedades) están en el contrato
/// [ServicioRecordatorios], que la implementación real también cumple.
abstract class ServicioNotificaciones {
  /// Inicializa el plugin (hay que llamarlo una vez al arrancar la app).
  Future<void> inicializar();

  /// Muestra la notificación fija de "reproduciendo en pausa".
  Future<void> mostrarReproduccionEnPausa(String tituloCancion);

  /// Oculta la notificación de reproducción.
  Future<void> ocultarReproduccion();
}

/// Implementación real con flutter_local_notifications (Android).
class ServicioNotificacionesLocal
    implements ServicioNotificaciones, ServicioRecordatorios {
  ServicioNotificacionesLocal({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const int _idReproduccion = 1;
  static const int _idNovedades = 2;
  static const String _canalId = 'reproduccion_segundo_plano';
  bool _inicializado = false;

  static const AndroidNotificationDetails
  _canalRecordatorios = AndroidNotificationDetails(
    'recordatorios_conciertos',
    'Recordatorios de conciertos',
    channelDescription:
        'Aviso el día anterior a un concierto para el que compraste entrada',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _canalNovedades =
      AndroidNotificationDetails(
        'novedades_conciertos',
        'Nuevos conciertos',
        channelDescription: 'Aviso cuando se publican conciertos nuevos',
      );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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

  // ---- ServicioRecordatorios ----

  /// En Android 13+ muestra el diálogo del sistema; en versiones anteriores
  /// el permiso se concede al instalar y se informa si están habilitadas.
  @override
  Future<bool> solicitarPermisos() async {
    await inicializar();
    final android = _android;
    if (android == null) return false; // plataforma sin soporte
    final concedido = await android.requestNotificationsPermission();
    return concedido ?? await android.areNotificationsEnabled() ?? false;
  }

  /// Usa el modo INEXACTO (inexactAllowWhileIdle): para un recordatorio del
  /// día anterior alcanza, y no hace falta el permiso SCHEDULE_EXACT_ALARM.
  /// La fecha se pasa como instante UTC (TZDateTime.from), así no hace falta
  /// conocer la zona horaria del dispositivo.
  @override
  Future<void> programarRecordatorioConcierto(Concierto concierto) async {
    final momento = momentoRecordatorio(concierto.fecha, DateTime.now());
    if (momento == null) return;
    await inicializar();
    await _plugin.zonedSchedule(
      id: idRecordatorio(concierto),
      title: 'Mañana: ${concierto.nombre}',
      body: 'Tenés entrada para ${concierto.lugar}',
      scheduledDate: tz.TZDateTime.from(momento, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: _canalRecordatorios,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    debugPrint('Recordatorio programado para "${concierto.nombre}": $momento');
  }

  @override
  Future<void> cancelarRecordatorios() async {
    await inicializar();
    await _plugin.cancelAllPendingNotifications();
  }

  @override
  Future<void> mostrarNuevosConciertos(List<String> nombres) async {
    if (nombres.isEmpty) return;
    await inicializar();
    await _plugin.show(
      id: _idNovedades,
      title: nombres.length == 1
          ? 'Nuevo concierto'
          : '${nombres.length} conciertos nuevos',
      body: nombres.join(', '),
      notificationDetails: const NotificationDetails(android: _canalNovedades),
    );
  }
}
