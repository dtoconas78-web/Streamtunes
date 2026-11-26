import 'package:shared_preferences/shared_preferences.dart';

/// Ruta de la foto de perfil de cada usuario (la imagen queda en la carpeta
/// de documentos de la app), y la marca de "cámara abierta" para recuperar
/// la foto si Android cerró la app en el medio.
abstract class RepositorioFotoPerfil {
  Future<String?> leer(String uid);
  Future<void> guardar(String uid, String? ruta);
  Future<bool> pendiente();
  Future<void> marcarPendiente(bool pendiente);
}

class RepositorioFotoPerfilMemoria implements RepositorioFotoPerfil {
  final Map<String, String> _rutas = {};
  bool _pendiente = false;

  @override
  Future<String?> leer(String uid) async => _rutas[uid];

  @override
  Future<void> guardar(String uid, String? ruta) async {
    if (ruta == null) {
      _rutas.remove(uid);
    } else {
      _rutas[uid] = ruta;
    }
  }

  @override
  Future<bool> pendiente() async => _pendiente;

  @override
  Future<void> marcarPendiente(bool pendiente) async => _pendiente = pendiente;
}

/// En SharedPreferencesAsync: `streamtunes.<uid>.fotoPerfil` y
/// `streamtunes.foto.pendiente`.
class RepositorioFotoPerfilPreferencias implements RepositorioFotoPerfil {
  RepositorioFotoPerfilPreferencias({required this._prefs});

  final SharedPreferencesAsync _prefs;

  static String clave(String uid) => 'streamtunes.$uid.fotoPerfil';
  static const String clavePendiente = 'streamtunes.foto.pendiente';

  @override
  Future<String?> leer(String uid) => _prefs.getString(clave(uid));

  @override
  Future<void> guardar(String uid, String? ruta) => ruta == null
      ? _prefs.remove(clave(uid))
      : _prefs.setString(clave(uid), ruta);

  @override
  Future<bool> pendiente() async =>
      await _prefs.getBool(clavePendiente) ?? false;

  @override
  Future<void> marcarPendiente(bool pendiente) =>
      _prefs.setBool(clavePendiente, pendiente);
}
