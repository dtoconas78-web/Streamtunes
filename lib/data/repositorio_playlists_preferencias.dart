import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/models/playlist.dart';

/// Playlists guardadas en el celular con shared_preferences (JSON, una clave
/// por usuario: `streamtunes.<uid>.playlists`).
///
/// Lecturas síncronas: [SharedPreferences] ya tiene los valores en caché
/// desde `getInstance()` (ver lib/services/persistencia_local.dart). Las
/// escrituras son asíncronas y se disparan en segundo plano con sus errores
/// capturados. Sin usuario (invitado / sin sesión) no se guarda nada.
class RepositorioPlaylistsPreferencias extends RepositorioPlaylistsMemoria {
  RepositorioPlaylistsPreferencias({required this._prefs});

  final SharedPreferences _prefs;

  static String clave(String uid) => 'streamtunes.$uid.playlists';

  @override
  List<Playlist> cargar(String uid) {
    final texto = _prefs.getString(clave(uid));
    if (texto == null) return const [];
    try {
      final lista = jsonDecode(texto);
      if (lista is! List) return const [];
      return [for (final m in lista) ?Playlist.fromMap(m)];
    } catch (e) {
      // JSON corrupto: se arranca vacío en vez de romper la app.
      debugPrint('Playlists guardadas ilegibles (se ignoran): $e');
      return const [];
    }
  }

  @override
  void guardar(String uid, List<Playlist> playlists) {
    final texto = jsonEncode([for (final p in playlists) p.toMap()]);
    unawaited(_escribir(clave(uid), texto));
  }

  Future<void> _escribir(String clave, String texto) async {
    try {
      await _prefs.setString(clave, texto);
    } catch (e) {
      debugPrint('No se pudieron guardar las playlists: $e');
    }
  }
}
