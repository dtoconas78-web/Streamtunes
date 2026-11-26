import 'package:flutter/foundation.dart';

/// Lo que el oyente sigue o guarda: artistas seguidos (para donar), álbumes
/// seguidos (aparecen en la Biblioteca) y canciones con "me gusta".
///
/// Todo se referencia por ID (nunca por posición en el catálogo: con
/// Firestore el orden cambia al publicar canciones nuevas). Es observable y
/// POR USUARIO: [usarUsuario] cambia de dueño y descarta lo del anterior.
/// Implementaciones: en memoria y guardado local en el celular
/// (RepositorioSeguimientoPreferencias).
abstract class RepositorioSeguimiento extends ChangeNotifier {
  Set<String> get artistasSeguidos;
  Set<String> get albumesSeguidos;
  Set<String> get cancionesMeGusta;

  bool sigueArtista(String id);
  bool sigueAlbum(String id);
  bool meGusta(String cancionId);

  void seguirArtista(String id);
  void dejarDeSeguirArtista(String id);
  void alternarAlbum(String id);
  void alternarMeGusta(String cancionId);

  /// Cambia el usuario dueño de los datos (null = sin sesión o invitado).
  void usarUsuario(String? uid);
}

/// Datos de seguimiento de un usuario (lo que se guarda y se carga).
class DatosSeguimiento {
  DatosSeguimiento({
    Set<String>? artistas,
    Set<String>? albumes,
    Set<String>? meGusta,
  }) : artistas = artistas ?? {},
       albumes = albumes ?? {},
       meGusta = meGusta ?? {};

  final Set<String> artistas;
  final Set<String> albumes;
  final Set<String> meGusta;

  bool get vacio => artistas.isEmpty && albumes.isEmpty && meGusta.isEmpty;

  Map<String, dynamic> toMap() => {
    'artistas': artistas.toList(),
    'albumes': albumes.toList(),
    'meGusta': meGusta.toList(),
  };

  /// Tolerante: campos faltantes o con otro tipo quedan vacíos.
  factory DatosSeguimiento.fromMap(Object? map) {
    Set<String> ids(Object? v) => {
      if (v is List)
        for (final e in v)
          if (e is String) e,
    };
    if (map is! Map) return DatosSeguimiento();
    return DatosSeguimiento(
      artistas: ids(map['artistas']),
      albumes: ids(map['albumes']),
      meGusta: ids(map['meGusta']),
    );
  }
}

/// Implementación en memoria: sin persistencia real. Las subclases persisten
/// sobreescribiendo [cargar] y [guardar].
class RepositorioSeguimientoMemoria extends RepositorioSeguimiento {
  DatosSeguimiento _datos = DatosSeguimiento();
  String? _uid;

  @override
  Set<String> get artistasSeguidos => Set.unmodifiable(_datos.artistas);

  @override
  Set<String> get albumesSeguidos => Set.unmodifiable(_datos.albumes);

  @override
  Set<String> get cancionesMeGusta => Set.unmodifiable(_datos.meGusta);

  @override
  bool sigueArtista(String id) => _datos.artistas.contains(id);

  @override
  bool sigueAlbum(String id) => _datos.albumes.contains(id);

  @override
  bool meGusta(String cancionId) => _datos.meGusta.contains(cancionId);

  @override
  void seguirArtista(String id) {
    if (_datos.artistas.add(id)) _cambio();
  }

  @override
  void dejarDeSeguirArtista(String id) {
    if (_datos.artistas.remove(id)) _cambio();
  }

  @override
  void alternarAlbum(String id) {
    if (!_datos.albumes.remove(id)) _datos.albumes.add(id);
    _cambio();
  }

  @override
  void alternarMeGusta(String cancionId) {
    if (!_datos.meGusta.remove(cancionId)) _datos.meGusta.add(cancionId);
    _cambio();
  }

  @override
  void usarUsuario(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    final previos = !_datos.vacio;
    _datos = uid == null ? DatosSeguimiento() : cargar(uid);
    if (previos || !_datos.vacio) notifyListeners();
  }

  void _cambio() {
    final u = _uid;
    if (u != null) guardar(u, _datos);
    notifyListeners();
  }

  /// Datos guardados del usuario [uid] (en memoria no hay nada).
  @protected
  DatosSeguimiento cargar(String uid) => DatosSeguimiento();

  /// Persiste los datos del usuario [uid] (en memoria no hace nada).
  @protected
  void guardar(String uid, DatosSeguimiento datos) {}
}
