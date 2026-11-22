// Capacidades y políticas de la app: un único módulo liviano (sin
// dependencias externas ni canales nativos) que concentra dos preguntas
// distintas: QUÉ está implementado (Capacidades) y QUÉ se le explica al
// usuario (Politicas).

/// Disponibilidad objetiva de funcionalidades IMPLEMENTADAS en la aplicación.
///
/// Ojo: esto NO es el permiso que el usuario le concede al sistema operativo
/// (p. ej. POST_NOTIFICATIONS en Android). Son conceptos distintos: la
/// capacidad dice si la app tiene el mecanismo; el permiso es la autorización
/// del SO, que recién existirá cuando haya un mecanismo real que la pida.
class Capacidades {
  /// Hoy no hay ningún mecanismo de notificaciones implementado (ni local ni
  /// push: sin plugin, sin permiso en el manifest, sin backend). Cuando se
  /// incorpore uno real, este getter pasa a true.
  bool get notificacionesDisponibles => false;
}

/// Mensajes explicativos destinados al usuario (políticas de la app): textos
/// que dicen por qué algo no está disponible o qué significa una opción.
class Politicas {
  /// Aviso mostrado en la configuración cuando las notificaciones todavía no
  /// tienen un mecanismo implementado detrás.
  String get avisoNotificacionesNoDisponibles =>
      'Las notificaciones todavía no están disponibles en esta versión';

  /// Aviso mostrado en el banner global cuando el dispositivo no tiene
  /// conexión a internet.
  String get avisoSinConexion =>
      'Sin conexión: algunas funciones necesitan internet';
}
