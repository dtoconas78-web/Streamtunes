/// Abstracción del reloj: la lógica de negocio no llama a `DateTime.now()`
/// directo, sino a través de [Reloj], que se inyecta desde
/// `lib/inyeccion.dart`. En los tests se inyecta [RelojFijo] para obtener
/// fechas deterministas.
///
/// Solo se inyecta donde la fecha es parte de la lógica de negocio (p. ej.
/// la fecha de los movimientos económicos). Las fechas de presentación
/// (date pickers, valores por defecto de formularios, ids) siguen usando
/// `DateTime.now()` directo en la capa de vistas.
abstract class Reloj {
  DateTime ahora();
}

/// Reloj real: la hora del sistema.
class RelojDelSistema implements Reloj {
  const RelojDelSistema();

  @override
  DateTime ahora() => DateTime.now();
}

/// Reloj de prueba: siempre devuelve la misma fecha.
class RelojFijo implements Reloj {
  const RelojFijo(this._fecha);

  final DateTime _fecha;

  @override
  DateTime ahora() => _fecha;
}
