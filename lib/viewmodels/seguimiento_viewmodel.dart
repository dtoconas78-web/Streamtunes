import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

// Regla de StreamTunes: para donarle a un artista, primero lo seguís.
// Este viewmodel guarda a quiénes sigue el oyente de esta sesión:
// artistas (para donar) y álbumes (aparecen en la Biblioteca al seguirlos).
class SeguimientoViewModel extends ChangeNotifier {
  final Set<String> _idsSeguidos = {};
  final Set<String> _albumesSeguidos = {};

  bool sigo(String id) => _idsSeguidos.contains(id);

  Artista? porId(String id) {
    for (final a in datos.artistas) {
      if (a.id == id) return a;
    }
    return null;
  }

  List<Artista> get seguidos =>
      datos.artistas.where((a) => sigo(a.id)).toList();

  List<Artista> get noSeguidos =>
      datos.artistas.where((a) => !sigo(a.id)).toList();

  void seguir(String id) {
    if (_idsSeguidos.add(id)) notifyListeners();
  }

  void dejarDeSeguir(String id) {
    if (_idsSeguidos.remove(id)) notifyListeners();
  }

  void alternar(String id) {
    if (sigo(id)) {
      dejarDeSeguir(id);
    } else {
      seguir(id);
    }
  }

  // ---- Álbumes seguidos (corazón en la pantalla del álbum) ----

  bool sigoAlbum(String id) => _albumesSeguidos.contains(id);

  // Solo los álbumes seguidos aparecen en la Biblioteca.
  List<Album> get albumesSeguidos => [
    for (final a in catalogo.albumes)
      if (_albumesSeguidos.contains(a.id)) a,
  ];

  void alternarAlbum(String id) {
    if (_albumesSeguidos.contains(id)) {
      _albumesSeguidos.remove(id);
    } else {
      _albumesSeguidos.add(id);
    }
    notifyListeners();
  }
}

// Instancia compartida por toda la app.
final SeguimientoViewModel seguimientoViewModel = SeguimientoViewModel();
