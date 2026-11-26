import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/models/playlist.dart';

/// Contrato del repositorio de playlists del oyente.
///
/// Es observable (ChangeNotifier, como los demás repositorios). Los datos son
/// POR USUARIO: [usarUsuario] cambia de dueño (login/logout) y descarta lo
/// del usuario anterior, así nadie ve las playlists de otra cuenta.
/// Implementaciones: en memoria (tests/demo) y guardado local en el celular
/// en SQLite (RepositorioPlaylistsSqlite); con backend, esta misma interfaz se
/// implementa contra Firestore.
abstract class RepositorioPlaylists extends ChangeNotifier {
  /// Playlists de solo lectura (las instancias son las del repositorio).
  List<Playlist> get playlists;

  Playlist? porId(String id);

  Playlist crear(String nombre);
  void renombrar(String id, String nuevoNombre);
  void agregarCancion(String playlistId, String cancionId);
  void quitarCancion(String playlistId, String cancionId);
  void eliminar(String playlistId);

  /// Cambia el usuario dueño de los datos (null = sin sesión o invitado).
  /// Lo del usuario anterior se descarta en el acto; lo guardado del nuevo
  /// llega en segundo plano (notifica al terminar, ver [listo]).
  void usarUsuario(String? uid);

  /// true mientras se leen las playlists guardadas del usuario actual.
  bool get cargando;

  /// Se completa cuando terminó la última carga pedida por [usarUsuario].
  Future<void> get listo;
}

/// Implementación en memoria: sin persistencia real. Las subclases persisten
/// sobreescribiendo [cargar] y [guardar].
class RepositorioPlaylistsMemoria extends RepositorioPlaylists {
  final List<Playlist> _playlists = [];
  String? _uid;
  int _contador = 0;

  @override
  List<Playlist> get playlists => List.unmodifiable(_playlists);

  @override
  Playlist? porId(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  // Id único también entre arranques (el timestamp no se repite al reabrir
  // la app); el contador evita choques dentro del mismo microsegundo.
  String _nuevoId() {
    String id;
    do {
      _contador++;
      id = 'playlist-${DateTime.now().microsecondsSinceEpoch}-$_contador';
    } while (porId(id) != null);
    return id;
  }

  @override
  Playlist crear(String nombre) {
    final playlist = Playlist(id: _nuevoId(), nombre: nombre.trim());
    _playlists.add(playlist);
    _cambio();
    return playlist;
  }

  @override
  void renombrar(String id, String nuevoNombre) {
    final p = porId(id);
    if (p == null || p.nombre == nuevoNombre.trim()) return;
    p.nombre = nuevoNombre.trim();
    _cambio();
  }

  @override
  void agregarCancion(String playlistId, String cancionId) {
    final p = porId(playlistId);
    if (p == null || p.cancionIds.contains(cancionId)) return;
    p.cancionIds.add(cancionId);
    _cambio();
  }

  @override
  void quitarCancion(String playlistId, String cancionId) {
    final p = porId(playlistId);
    if (p == null || !p.cancionIds.remove(cancionId)) return;
    _cambio();
  }

  @override
  void eliminar(String playlistId) {
    final antes = _playlists.length;
    _playlists.removeWhere((p) => p.id == playlistId);
    if (_playlists.length != antes) _cambio();
  }

  bool _cargando = false;
  Future<void> _listo = Future.value();

  @override
  bool get cargando => _cargando;

  @override
  Future<void> get listo => _listo;

  @override
  void usarUsuario(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    final previas = _playlists.isNotEmpty;
    _playlists.clear();
    _cargando = uid != null;
    if (previas || _cargando) notifyListeners();
    _listo = uid == null ? Future.value() : _cargarDe(uid);
  }

  // Lee lo guardado de [uid]. Si mientras tanto cambió el usuario, el
  // resultado se descarta (no se mezclan cuentas). Si el usuario creó o
  // cambió playlists durante la carga, se conservan y se guarda la unión.
  Future<void> _cargarDe(String uid) async {
    List<Playlist> guardadas;
    try {
      guardadas = await cargar(uid);
    } catch (e) {
      debugPrint('No se pudieron leer las playlists guardadas: $e');
      guardadas = const [];
    }
    if (_uid != uid) return;
    final cambiosDuranteCarga = _playlists.isNotEmpty;
    final ids = {for (final p in _playlists) p.id};
    _playlists.insertAll(0, [
      for (final p in guardadas)
        if (!ids.contains(p.id)) p,
    ]);
    _cargando = false;
    if (cambiosDuranteCarga) guardar(uid, playlists);
    notifyListeners();
  }

  void _cambio() {
    final u = _uid;
    if (u != null) guardar(u, playlists);
    notifyListeners();
  }

  /// Playlists guardadas del usuario [uid] (en memoria no hay nada).
  @protected
  Future<List<Playlist>> cargar(String uid) async => const [];

  /// Persiste las playlists del usuario [uid] (en memoria no hace nada).
  @protected
  void guardar(String uid, List<Playlist> playlists) {}
}
