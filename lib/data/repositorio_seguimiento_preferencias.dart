import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';

/// Seguimientos y "me gusta" guardados en el celular con shared_preferences
/// (JSON, una clave por usuario: `streamtunes.<uid>.seguimiento`).
///
/// Mismo esquema que RepositorioPlaylistsPreferencias: lecturas síncronas
/// desde la caché de [SharedPreferences], escrituras en segundo plano con
/// errores capturados, y sin usuario no se guarda nada.
class RepositorioSeguimientoPreferencias extends RepositorioSeguimientoMemoria {
  RepositorioSeguimientoPreferencias({required this._prefs});

  final SharedPreferences _prefs;

  static String clave(String uid) => 'streamtunes.$uid.seguimiento';

  @override
  DatosSeguimiento cargar(String uid) {
    final texto = _prefs.getString(clave(uid));
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
    unawaited(_escribir(clave(uid), jsonEncode(datos.toMap())));
  }

  Future<void> _escribir(String clave, String texto) async {
    try {
      await _prefs.setString(clave, texto);
    } catch (e) {
      debugPrint('No se pudieron guardar los seguimientos: $e');
    }
  }
}
