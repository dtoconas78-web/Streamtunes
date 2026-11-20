import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

/// Contrato del repositorio del catálogo (canciones y álbumes del artista).
///
/// Es observable (ChangeNotifier, como RepositorioMovimientos): las altas
/// locales notifican y, con backend, los cambios remotos (snapshots) también.
/// La implementación de demo es en memoria (semilla: datos_ejemplo.dart);
/// con backend, esta misma interfaz se implementa contra Firestore.
abstract class RepositorioCatalogo extends ChangeNotifier {
  /// Catálogo de solo lectura.
  List<Cancion> get canciones;
  List<Album> get albumes;

  void agregarCanciones(List<Cancion> nuevas);
  void agregarAlbum(Album album);
}

/// Implementación en memoria: arranca con los datos de ejemplo y guarda todo
/// en listas privadas (sin persistencia real).
class RepositorioCatalogoMemoria extends RepositorioCatalogo {
  RepositorioCatalogoMemoria({List<Cancion>? canciones, List<Album>? albumes})
    : _canciones = List.of(canciones ?? datos.canciones),
      _albumes = List.of(albumes ?? datos.albumes);

  final List<Cancion> _canciones;
  final List<Album> _albumes;

  @override
  List<Cancion> get canciones => List.unmodifiable(_canciones);

  @override
  List<Album> get albumes => List.unmodifiable(_albumes);

  @override
  void agregarCanciones(List<Cancion> nuevas) {
    if (nuevas.isEmpty) return; // sin cambios reales, no se notifica
    _canciones.addAll(nuevas);
    notifyListeners();
  }

  @override
  void agregarAlbum(Album album) {
    _albumes.add(album);
    notifyListeners();
  }
}
