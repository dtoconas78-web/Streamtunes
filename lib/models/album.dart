// Modelo simple para representar un álbum.
// No depende de Flutter: el color de portada se guarda como int ARGB.
// "cancionIds" son los ids de sus canciones (más robusto que posiciones:
// si el catálogo cambia de orden, el álbum sigue apuntando bien).
class Album {
  final String id;
  final String titulo;
  final String anio;
  final int colorPortada;
  final List<String> cancionIds;

  const Album({
    required this.id,
    required this.titulo,
    required this.anio,
    required this.colorPortada,
    required this.cancionIds,
  });
}
