import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano_workmanager.dart';
import 'package:workmanager/workmanager.dart';

/// Doble de la plataforma de workmanager: registra lo que el servicio le
/// pide, sin tocar Android. Extiende WorkmanagerPlatform (no `implements`)
/// para pasar la verificación de token de la interfaz de plataforma.
class _PlataformaFalsa extends WorkmanagerPlatform {
  Function? dispatcherInicializado;
  final List<Map<String, Object?>> periodicas = [];
  final List<String> canceladas = [];

  @override
  Future<void> initialize(
    Function callbackDispatcher, {
    bool isInDebugMode = false,
  }) async {
    dispatcherInicializado = callbackDispatcher;
  }

  @override
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    Duration? flexInterval,
    Map<String, dynamic>? inputData,
    Duration? initialDelay,
    Constraints? constraints,
    ExistingPeriodicWorkPolicy? existingWorkPolicy,
    BackoffPolicy? backoffPolicy,
    Duration? backoffPolicyDelay,
    String? tag,
    ForegroundServiceConfig? foregroundServiceConfig,
  }) async {
    periodicas.add({
      'uniqueName': uniqueName,
      'taskName': taskName,
      'frequency': frequency,
      'policy': existingWorkPolicy,
      'network': constraints?.networkType,
    });
  }

  @override
  Future<void> cancelByUniqueName(String uniqueName) async {
    canceladas.add(uniqueName);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorkmanagerPlatform original;
  late _PlataformaFalsa plataforma;

  // El singleton Workmanager(), al crearse por primera vez, instala su
  // implementación nativa como plataforma. Se lo crea antes de instalar el
  // doble para que no lo pise en el primer test.
  setUpAll(Workmanager.new);

  setUp(() {
    original = WorkmanagerPlatform.instance;
    plataforma = _PlataformaFalsa();
    WorkmanagerPlatform.instance = plataforma;
  });

  tearDown(() => WorkmanagerPlatform.instance = original);

  test('inicializar registra el callbackDispatcher top-level', () async {
    await ServicioTareasWorkmanager().inicializar();
    expect(plataforma.dispatcherInicializado, same(callbackDispatcher));
  });

  test(
    'registra la verificación periódica con los parámetros esperados',
    () async {
      await ServicioTareasWorkmanager().registrarVerificacionPeriodica();

      expect(plataforma.periodicas, [
        {
          'uniqueName': nombreUnicoNovedades,
          'taskName': tareaVerificarNovedades,
          'frequency': frecuenciaNovedades,
          // update: si ya existe no se duplica (Android recomienda update).
          'policy': ExistingPeriodicWorkPolicy.update,
          'network': NetworkType.connected,
        },
      ]);
      // Android exige al menos 15 minutos entre corridas periódicas.
      expect(
        frecuenciaNovedades,
        greaterThanOrEqualTo(const Duration(minutes: 15)),
      );
    },
  );

  test('registrar dos veces usa el mismo nombre único (no duplica)', () async {
    final servicio = ServicioTareasWorkmanager();
    await servicio.registrarVerificacionPeriodica();
    await servicio.registrarVerificacionPeriodica();
    expect(plataforma.periodicas.map((p) => p['uniqueName']).toSet(), {
      nombreUnicoNovedades,
    });
  });

  test('registra la subida periódica de métricas con red', () async {
    await ServicioTareasWorkmanager().registrarSincronizacionMetricas();
    expect(plataforma.periodicas, [
      {
        'uniqueName': nombreUnicoMetricas,
        'taskName': tareaSincronizarMetricas,
        'frequency': frecuenciaMetricas,
        'policy': ExistingPeriodicWorkPolicy.update,
        'network': NetworkType.connected,
      },
    ]);
  });

  test('cancelar cancela la tarea por su nombre único', () async {
    await ServicioTareasWorkmanager().cancelar();
    expect(plataforma.canceladas, [nombreUnicoNovedades]);
  });
}
