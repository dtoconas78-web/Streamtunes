// Capacidades y políticas de la app: un único módulo liviano (sin
// dependencias externas ni canales nativos) que concentra dos preguntas
// distintas: QUÉ está implementado (Capacidades) y QUÉ se le explica al
// usuario (Politicas).

/// Disponibilidad objetiva de funcionalidades IMPLEMENTADAS en la aplicación.
///
/// Ojo: esto NO es el permiso que el usuario le concede al sistema operativo
/// (p. ej. POST_NOTIFICATIONS en Android). Son conceptos distintos: la
/// capacidad dice si la app tiene el mecanismo funcionando; el permiso es la
/// autorización del SO, que se pide al activar las notificaciones.
///
/// Por defecto todo es false: lib/inyeccion.dart las activa solo si en
/// main() se inicializaron de verdad el plugin de notificaciones y
/// workmanager (mismo criterio que `firebaseInicializado`). En los tests
/// main() no corre, así que quedan en false.
class Capacidades {
  const Capacidades({
    this.notificacionesDisponibles = false,
    this.notificacionesProgramadas = false,
    this.tareasSegundoPlano = false,
  });

  /// Hay mecanismo de notificaciones locales (plugin inicializado): habilita
  /// el switch de Configuración.
  final bool notificacionesDisponibles;

  /// Se pueden programar recordatorios (p. ej. del concierto de una entrada
  /// comprada).
  final bool notificacionesProgramadas;

  /// Hay tareas periódicas en segundo plano (workmanager inicializado).
  final bool tareasSegundoPlano;
}

/// Mensajes explicativos destinados al usuario (políticas de la app): textos
/// que dicen por qué algo no está disponible o qué significa una opción.
class Politicas {
  /// Aviso mostrado en la configuración cuando las notificaciones todavía no
  /// tienen un mecanismo implementado detrás.
  String get avisoNotificacionesNoDisponibles =>
      'Las notificaciones todavía no están disponibles en esta versión';

  /// Aviso mostrado en la configuración cuando el usuario rechazó el
  /// permiso de notificaciones del sistema.
  String get avisoPermisoNotificacionesDenegado =>
      'Sin permiso de notificaciones: activalo en los ajustes del celular';

  /// Aviso mostrado en el banner global cuando el dispositivo no tiene
  /// conexión a internet.
  String get avisoSinConexion =>
      'Sin conexión: algunas funciones necesitan internet';
}
