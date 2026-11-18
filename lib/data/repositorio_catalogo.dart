import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

/// Contrato del repositorio del catálogo (canciones y álbumes del artista).
///
/// La implementación de demo es en memoria (semilla: datos_ejemplo.dart);
/// con backend, esta misma interfaz se implementa contra la API/Firestore.
abstract class RepositorioCatalogo {
  /// Catálogo de solo lectura.
  List<Cancion> get canciones;
  List<Album> get albumes;

  void agregarCanciones(List<Cancion> nuevas);
  void agregarAlbum(Album album);
}

/// Implementación en memoria: arranca con los datos de ejemplo y guarda todo
/// en listas privadas (sin persistencia real).
class RepositorioCatalogoMemoria implements RepositorioCatalogo {
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
  void agregarCanciones(List<Cancion> nuevas) => _canciones.addAll(nuevas);

  @override
  void agregarAlbum(Album album) => _albumes.add(album);
}
