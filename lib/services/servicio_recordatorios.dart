import 'package:streamtunes_demo/models/concierto.dart';

/// Notificaciones que el USUARIO activa desde Configuración: pedir el permiso
/// del sistema, recordatorios programados de conciertos y avisos de
/// novedades.
///
/// Es un contrato aparte de ServicioNotificaciones (que sigue igual) para no
/// romper los dobles existentes que hacen `implements ServicioNotificaciones`:
/// con `implements` no se heredan métodos por defecto. La implementación real
/// (ServicioNotificacionesLocal) implementa los dos contratos.
///
/// No importa ningún plugin: los ViewModels dependen de esta interfaz y los
/// tests inyectan un falso.
abstract class ServicioRecordatorios {
  /// Pide el permiso de notificaciones al sistema (Android 13+). Devuelve
  /// true si quedó concedido.
  Future<bool> solicitarPermisos();

  /// Programa el recordatorio del concierto (ver [momentoRecordatorio]). Si
  /// el momento ya pasó, no hace nada.
  Future<void> programarRecordatorioConcierto(Concierto concierto);

  /// Cancela todos los recordatorios programados pendientes.
  Future<void> cancelarRecordatorios();

  /// Avisa que hay conciertos nuevos publicados (tarea en segundo plano).
  Future<void> mostrarNuevosConciertos(List<String> nombres);

  /// Avisa al artista que recibió una donación ([donante] '' = anónima).
  Future<void> mostrarDonacionRecibida({
    required double monto,
    required String donante,
  });
}

/// Texto del aviso de donación recibida (función pura: se prueba sin
/// plugin). [precio] es el monto ya formateado.
({String titulo, String cuerpo}) textoDonacionRecibida(
  String precio,
  String donante,
) => (
  titulo: 'Recibiste una donación',
  cuerpo: donante.isEmpty
      ? 'Alguien te donó $precio de forma anónima'
      : '$donante te donó $precio',
);

/// Hora del día en que sale el recordatorio (el día ANTERIOR al concierto).
const int horaRecordatorio = 10;

/// Cuándo recordar un concierto: el día anterior a las [horaRecordatorio].
/// Devuelve null si ese momento ya pasó respecto de [ahora] (no se programan
/// recordatorios en el pasado). Función pura: se prueba sin plugin.
DateTime? momentoRecordatorio(DateTime fechaConcierto, DateTime ahora) {
  final momento = DateTime(
    fechaConcierto.year,
    fechaConcierto.month,
    fechaConcierto.day - 1,
    horaRecordatorio,
  );
  return momento.isAfter(ahora) ? momento : null;
}

/// Id estable de la notificación de recordatorio de un concierto (así
/// comprar dos veces el mismo concierto no duplica el recordatorio). Se
/// reserva el rango >= 1000 para no chocar con los ids fijos (1, 2).
int idRecordatorio(Concierto concierto) {
  final clave = concierto.id.isNotEmpty
      ? concierto.id
      : '${concierto.nombre}|${concierto.fecha.toIso8601String()}';
  var hash = 0;
  for (final unidad in clave.codeUnits) {
    hash = (hash * 31 + unidad) & 0x3fffffff; // estable entre ejecuciones
  }
  return 1000 + hash % 1000000000;
}
