import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ciudad que declara el oyente en su perfil (para las estadísticas de los
/// artistas; no se usa GPS). Se guarda por usuario, en el celular.
abstract class RepositorioCiudad {
  Future<String?> leer(String uid);
  Future<void> guardar(String uid, String ciudad);
}

class RepositorioCiudadMemoria implements RepositorioCiudad {
  final Map<String, String> _ciudades = {};

  @override
  Future<String?> leer(String uid) async => _ciudades[uid];

  @override
  Future<void> guardar(String uid, String ciudad) async =>
      _ciudades[uid] = ciudad;
}

/// En SharedPreferencesAsync, clave `streamtunes.<uid>.ciudad`.
class RepositorioCiudadPreferencias implements RepositorioCiudad {
  RepositorioCiudadPreferencias({required this._prefs});

  final SharedPreferencesAsync _prefs;

  static String clave(String uid) => 'streamtunes.$uid.ciudad';

  @override
  Future<String?> leer(String uid) async {
    try {
      return await _prefs.getString(clave(uid));
    } catch (e) {
      debugPrint('No se pudo leer la ciudad: $e');
      return null;
    }
  }

  @override
  Future<void> guardar(String uid, String ciudad) =>
      _prefs.setString(clave(uid), ciudad);
}
