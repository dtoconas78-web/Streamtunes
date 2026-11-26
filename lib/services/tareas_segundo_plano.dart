/// Tareas periódicas en segundo plano (corren aunque la app esté cerrada).
///
/// Contrato sin dependencias de plugins: ConfiguracionViewModel depende de
/// esta interfaz y los tests inyectan un falso. La implementación real con
/// workmanager está en tareas_segundo_plano_workmanager.dart y se elige en
/// lib/inyeccion.dart.
abstract class ServicioTareasSegundoPlano {
  /// Registra (o actualiza) la verificación periódica de novedades.
  Future<void> registrarVerificacionPeriodica();

  /// Cancela la verificación periódica.
  Future<void> cancelar();
}

/// Implementación vacía: se usa cuando workmanager no está disponible
/// (tests, escritorio) para que la app funcione igual sin tareas.
class ServicioTareasNulo implements ServicioTareasSegundoPlano {
  const ServicioTareasNulo();

  @override
  Future<void> registrarVerificacionPeriodica() async {}

  @override
  Future<void> cancelar() async {}
}
