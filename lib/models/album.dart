// Modelo simple para representar un álbum.
// No depende de Flutter: el color de portada se guarda como int ARGB.
// "indices" son las posiciones de sus canciones en la lista `canciones`.
class Album {
  final String titulo;
  final String anio;
  final int colorPortada;
  final List<int> indices;

  const Album({
    required this.titulo,
    required this.anio,
    required this.colorPortada,
    required this.indices,
  });
}
