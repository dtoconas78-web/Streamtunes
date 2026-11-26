import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';
import 'package:sqflite/sqflite.dart';
import 'package:streamtunes_demo/data/services/base_datos_local.dart';

/// Guardado local en el celular, con el mismo criterio que
/// `firebaseInicializado`: si main() logró abrirlo, inyeccion.dart usa los
/// repositorios persistentes; si no (tests, o falla el plugin), quedan los
/// *Memoria y la app sigue funcionando sin guardar.
///
/// - [preferenciasLocales]: valores chicos (seguidos, "me gusta",
///   configuración, ciudad). Es [SharedPreferencesAsync]: no tiene caché
///   por isolate, así la app y la tarea de workmanager (que corre en otro
///   isolate) leen siempre lo mismo.
/// - [baseDatosLocal]: datos estructurados en SQLite (playlists).
SharedPreferencesAsync? preferenciasLocales;
Database? baseDatosLocal;

/// Marca (en las preferencias nuevas) de que ya se copiaron los valores de
/// la API vieja de shared_preferences. En Android la API vieja y la nueva
/// guardan en lugares distintos: sin esta copia se perderían los datos.
const String claveMigracionPreferencias = 'streamtunes.migracion.prefsAsync';

/// Abre el guardado local UNA vez al arrancar (antes de runApp). Nunca
/// lanza: ante un error, esa parte queda en memoria.
Future<void> inicializarPersistenciaLocal() async {
  try {
    final prefs = SharedPreferencesAsync();
    await _migrarPreferenciasViejas();
    preferenciasLocales = prefs;
  } catch (e) {
    debugPrint('Sin preferencias locales (se usa memoria): $e');
  }
  try {
    baseDatosLocal = await abrirBaseDatosLocal();
  } catch (e) {
    debugPrint('Sin base de datos local (se usa memoria): $e');
  }
}

// Copia una sola vez lo guardado con la API vieja. Si falla, se reintenta
// en el próximo arranque (la marca recién se escribe al terminar bien).
Future<void> _migrarPreferenciasViejas() async {
  try {
    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: await SharedPreferences.getInstance(),
      sharedPreferencesAsyncOptions: const SharedPreferencesOptions(),
      migrationCompletedKey: claveMigracionPreferencias,
    );
  } catch (e) {
    debugPrint('No se pudieron migrar las preferencias viejas: $e');
  }
}
