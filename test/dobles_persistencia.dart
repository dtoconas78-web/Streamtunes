import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streamtunes_demo/data/services/base_datos_local.dart';

/// SharedPreferencesAsync respaldado en memoria (sin plugin nativo), con
/// [valores] iniciales. Cada llamada arranca de cero.
SharedPreferencesAsync preferenciasEnMemoria([
  Map<String, Object> valores = const {},
]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(valores);
  return SharedPreferencesAsync();
}

/// Base SQLite nueva en memoria con el esquema de la app (sqflite_common_ffi,
/// corre en la PC sin emulador). Cerrarla al terminar el test.
Future<Database> baseEnMemoria() {
  sqfliteFfiInit();
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: opcionesBaseDatos(unicaInstancia: false),
  );
}
