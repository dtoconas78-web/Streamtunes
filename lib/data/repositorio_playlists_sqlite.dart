import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/playlists_dao.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/models/playlist.dart';

/// Playlists guardadas en el celular en SQLite (tablas `playlists` y
/// `playlist_canciones`, ver data/services/base_datos_local.dart).
///
/// La lectura es asíncrona (llega después de [usarUsuario], ver la clase
/// base). Las escrituras se encadenan en orden y corren en segundo plano con
/// sus errores capturados. Sin usuario (invitado / sin sesión) no se guarda
/// nada.
///
/// Migración: antes las playlists iban como JSON en shared_preferences
/// ([claveVieja]). La primera vez que un usuario entra, si en SQLite no tiene
/// nada y existe esa clave, se importan y se borra la clave.
class RepositorioPlaylistsSqlite extends RepositorioPlaylistsMemoria {
  RepositorioPlaylistsSqlite({required this._dao, this._prefsViejas});

  final PlaylistsDao _dao;
  final SharedPreferencesAsync? _prefsViejas;
  Future<void> _escrituras = Future.value();

  /// Clave del guardado anterior (JSON en shared_preferences).
  static String claveVieja(String uid) => 'streamtunes.$uid.playlists';

  @override
  Future<List<Playlist>> cargar(String uid) async {
    await _escrituras; // no leer por delante de una escritura pendiente
    final guardadas = await _dao.deUsuario(uid);
    if (guardadas.isNotEmpty) return guardadas;
    return _importarVieja(uid);
  }

  Future<List<Playlist>> _importarVieja(String uid) async {
    final prefs = _prefsViejas;
    if (prefs == null) return const [];
    final texto = await prefs.getString(claveVieja(uid));
    if (texto == null) return const [];
    final importadas = _decodificar(texto);
    await _dao.reemplazarDeUsuario(uid, importadas);
    await prefs.remove(claveVieja(uid));
    return importadas;
  }

  static List<Playlist> _decodificar(String texto) {
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
    // Copia: las playlists son mutables y pueden cambiar antes de escribirse.
    final copia = [
      for (final p in playlists)
        Playlist(id: p.id, nombre: p.nombre, cancionIds: List.of(p.cancionIds)),
    ];
    _escrituras = _escrituras.then((_) => _escribir(uid, copia));
  }

  /// Se completa cuando terminaron las escrituras pedidas hasta ahora.
  @visibleForTesting
  Future<void> get escrituras => _escrituras;

  Future<void> _escribir(String uid, List<Playlist> playlists) async {
    try {
      await _dao.reemplazarDeUsuario(uid, playlists);
    } catch (e) {
      debugPrint('No se pudieron guardar las playlists: $e');
    }
  }
}
