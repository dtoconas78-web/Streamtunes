import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/data/repositorio_metricas.dart';
import 'package:streamtunes_demo/data/reproducciones_dao.dart';
import 'package:streamtunes_demo/data/services/base_datos_local.dart';
import 'package:streamtunes_demo/firebase_options.dart';
import 'package:streamtunes_demo/services/servicio_notificaciones.dart';
import 'package:streamtunes_demo/services/sincronizacion_metricas.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano.dart';
import 'package:streamtunes_demo/services/verificacion_novedades.dart';
import 'package:workmanager/workmanager.dart';

/// Nombre único de la tarea periódica (sirve para actualizarla/cancelarla).
const String nombreUnicoNovedades = 'streamtunes.verificar-novedades';

/// Nombre de la tarea que recibe el callbackDispatcher.
const String tareaVerificarNovedades = 'verificarNovedades';

/// Cada cuánto se verifica (Android exige un mínimo de 15 minutos y puede
/// demorarla según batería/red).
const Duration frecuenciaNovedades = Duration(hours: 6);

/// Tarea periódica que sube las reproducciones contadas a las métricas.
const String nombreUnicoMetricas = 'streamtunes.sincronizar-metricas';
const String tareaSincronizarMetricas = 'sincronizarMetricas';
const Duration frecuenciaMetricas = Duration(hours: 6);

/// Implementación real con workmanager.
class ServicioTareasWorkmanager implements ServicioTareasSegundoPlano {
  ServicioTareasWorkmanager({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  /// Hay que llamarlo UNA vez al arrancar (antes de registrar tareas).
  Future<void> inicializar() => _workmanager.initialize(callbackDispatcher);

  /// Política `update`: si ya existe, se actualiza sin duplicarla (Android
  /// recomienda update en vez de replace).
  @override
  Future<void> registrarVerificacionPeriodica() =>
      _workmanager.registerPeriodicTask(
        nombreUnicoNovedades,
        tareaVerificarNovedades,
        frequency: frecuenciaNovedades,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );

  /// Registra (o actualiza) la subida periódica de métricas, con red.
  Future<void> registrarSincronizacionMetricas() =>
      _workmanager.registerPeriodicTask(
        nombreUnicoMetricas,
        tareaSincronizarMetricas,
        frequency: frecuenciaMetricas,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );

  @override
  Future<void> cancelar() =>
      _workmanager.cancelByUniqueName(nombreUnicoNovedades);
}

/// Punto de entrada de las tareas en segundo plano.
///
/// Android lo ejecuta en un ISOLATE APARTE, aunque la app esté cerrada, así
/// que NO puede usar nada de lib/inyeccion.dart (ViewModels, repositorios,
/// listeners): todo se inicializa acá mismo. El pragma evita que el
/// compilador lo elimine por no estar referenciado desde main().
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((tarea, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (tarea == tareaSincronizarMetricas) return _sincronizarMetricas();
    if (tarea != tareaVerificarNovedades) return true; // tarea desconocida
    try {
      // SharedPreferencesAsync no tiene caché por isolate: lee siempre lo
      // último que guardó la app (no hace falta reload()).
      final prefs = SharedPreferencesAsync();
      final configuracion = RepositorioConfiguracionPreferencias(prefs: prefs);
      await configuracion.cargar();
      // Si el usuario desactivó las notificaciones, no se hace nada.
      if (!configuracion.notificaciones) return true;
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final notificaciones = ServicioNotificacionesLocal();
      await notificaciones.inicializar();
      final nuevos = await verificarNovedades(
        fuente: FuenteFirestoreFirebase(),
        prefs: prefs,
        avisar: notificaciones.mostrarNuevosConciertos,
      );
      debugPrint('Verificación de novedades: ${nuevos.length} nuevos');
      return true;
    } catch (e) {
      // false = workmanager la reintenta más tarde con backoff.
      debugPrint('Falló la verificación de novedades: $e');
      return false;
    }
  });
}

// Sube la cola local de reproducciones a Firestore desde el isolate de
// workmanager. Las reglas piden sesión: si no hay usuario guardado, no hace
// nada (lo sube la app la próxima vez que se inicie sesión).
Future<bool> _sincronizarMetricas() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (FirebaseAuth.instance.currentUser == null) return true;
    // Ojo: NO se cierra la base al terminar. sqflite comparte la conexión
    // entre isolates del mismo proceso (singleInstance), y si la app está
    // abierta, cerrarla acá le cierra la base a la app.
    final db = await abrirBaseDatosLocal();
    {
      final fuente = FuenteFirestoreFirebase();
      final subidas = await sincronizarMetricas(
        dao: ReproduccionesDao(db),
        sumar: (id, incremento) => fuente.incrementar(
          RepositorioMetricasFirestore.coleccionMetricas,
          id,
          incremento.toMap(),
        ),
        ahora: DateTime.now(),
      );
      debugPrint('Métricas en segundo plano: $subidas reproducciones subidas');
    }
    return true;
  } catch (e) {
    debugPrint('Falló la subida de métricas en segundo plano: $e');
    return false; // workmanager la reintenta con backoff
  }
}
