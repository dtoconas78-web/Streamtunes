import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';

// Dueño del catálogo (canciones y álbumes). Los datos viven en el
// [RepositorioCatalogo] inyectado (ver lib/inyeccion.dart): la UI no toca
// datos_ejemplo ni las listas del repo a mano, pasa por acá y las pantallas
// se actualizan solas con ListenableBuilder.
class CatalogoViewModel extends ChangeNotifier {
  CatalogoViewModel({required this._repositorio}) {
    // Reactividad: se reemiten los cambios del repositorio (altas locales en
    // memoria o snapshots remotos de Firestore), una sola suscripción.
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioCatalogo _repositorio;
  int _contadorAlbumes = 0;

  // Vistas de solo lectura: para publicar se usa [publicar].
  List<Cancion> get canciones => _repositorio.canciones;
  List<Album> get albumes => _repositorio.albumes;

  // Publica canciones nuevas (sueltas o como álbum). No se notifica acá: el
  // repo ya notificó y este VM reemite por la suscripción (una notificación
  // por cambio real del repo).
  void publicar({
    required List<Cancion> nuevas,
    String? tituloAlbum,
    String? anioAlbum,
    required int colorPortada,
  }) {
    _repositorio.agregarCanciones(nuevas);
    if (tituloAlbum != null) {
      _contadorAlbumes++;
      _repositorio.agregarAlbum(
        Album(
          id: 'album-publicado-$_contadorAlbumes',
          titulo: tituloAlbum,
          anio: anioAlbum ?? '',
          colorPortada: colorPortada,
          cancionIds: [for (final c in nuevas) c.id],
        ),
      );
    }
  }

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
