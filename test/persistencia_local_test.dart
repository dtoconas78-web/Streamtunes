import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/services/persistencia_local.dart';

import 'dobles_persistencia.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'al arrancar copia lo guardado con la API vieja a SharedPreferencesAsync',
    () async {
      // Lo que tenía un celular con la versión anterior de la app.
      SharedPreferences.setMockInitialValues({
        'streamtunes.u1.seguimiento': '{"meGusta":["ruta-7"]}',
        claveNotificacionesActivas: true,
      });
      preferenciasEnMemoria(); // destino vacío

      await inicializarPersistenciaLocal();

      final prefs = preferenciasLocales!;
      expect(
        await prefs.getString('streamtunes.u1.seguimiento'),
        '{"meGusta":["ruta-7"]}',
      );
      expect(await prefs.getBool(claveNotificacionesActivas), isTrue);
      expect(await prefs.getBool(claveMigracionPreferencias), isTrue);
    },
  );

  test('la migración corre una sola vez: no pisa datos nuevos', () async {
    SharedPreferences.setMockInitialValues({claveNotificacionesActivas: true});
    preferenciasEnMemoria({
      claveMigracionPreferencias: true,
      claveNotificacionesActivas: false, // el usuario las apagó después
    });

    await inicializarPersistenciaLocal();

    expect(
      await preferenciasLocales!.getBool(claveNotificacionesActivas),
      isFalse,
    );
  });
}
