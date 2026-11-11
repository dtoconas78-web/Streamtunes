import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/artista.dart';

// Regla de StreamTunes: para donarle a un artista, primero lo seguís.
// Este viewmodel guarda a quiénes sigue el oyente de esta sesión.
class SeguimientoViewModel extends ChangeNotifier {
  final Set<String> _idsSeguidos = {};

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
}

// Instancia compartida por toda la app.
final SeguimientoViewModel seguimientoViewModel = SeguimientoViewModel();
