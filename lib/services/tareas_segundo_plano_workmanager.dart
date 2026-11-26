import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/firebase_options.dart';
import 'package:streamtunes_demo/services/servicio_notificaciones.dart';
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
