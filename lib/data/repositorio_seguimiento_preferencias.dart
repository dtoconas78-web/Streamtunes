import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';

/// Seguimientos y "me gusta" guardados en el celular con
/// [SharedPreferencesAsync] (JSON, una clave por usuario:
/// `streamtunes.<uid>.seguimiento`).
///
/// La lectura es asíncrona (llega después de [usarUsuario], ver la clase
/// base). Las escrituras se encadenan en orden y corren en segundo plano con
/// sus errores capturados. Sin usuario no se guarda nada.
class RepositorioSeguimientoPreferencias extends RepositorioSeguimientoMemoria {
  RepositorioSeguimientoPreferencias({required this._prefs});

  final SharedPreferencesAsync _prefs;
  Future<void> _escrituras = Future.value();

  static String clave(String uid) => 'streamtunes.$uid.seguimiento';

  @override
  Future<DatosSeguimiento> cargar(String uid) async {
    await _escrituras; // no leer por delante de una escritura pendiente
    final texto = await _prefs.getString(clave(uid));
    if (texto == null) return DatosSeguimiento();
    try {
      return DatosSeguimiento.fromMap(jsonDecode(texto));
    } catch (e) {
      // JSON corrupto: se arranca vacío en vez de romper la app.
      debugPrint('Seguimientos guardados ilegibles (se ignoran): $e');
      return DatosSeguimiento();
    }
  }

  @override
  void guardar(String uid, DatosSeguimiento datos) {
    // Se serializa YA: los sets pueden cambiar antes de escribirse.
    final texto = jsonEncode(datos.toMap());
    _escrituras = _escrituras.then((_) => _escribir(clave(uid), texto));
  }

  /// Se completa cuando terminaron las escrituras pedidas hasta ahora.
  @visibleForTesting
  Future<void> get escrituras => _escrituras;

  Future<void> _escribir(String clave, String texto) async {
    try {
      await _prefs.setString(clave, texto);
    } catch (e) {
      debugPrint('No se pudieron guardar los seguimientos: $e');
    }
  }
}
