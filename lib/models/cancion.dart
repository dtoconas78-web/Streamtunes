// Modelo simple para representar una canción.
// No depende de Flutter: el color de portada se guarda como int ARGB
// (conviertelo con colorDe() de theme/colores.dart para mostrarlo).
class Cancion {
  final String id; // identificador único (los álbumes referencian por id)
  final String titulo;
  final int duracionSegundos; // duración en segundos (la UI la formatea)
  final int reproducciones;
  final String tendencia;
  final String lugar;
  final String horarioPico;
  final int colorPortada;
  final String genero;
  final String descripcion;
  final bool publica;

  const Cancion({
    required this.id,
    required this.titulo,
    required this.duracionSegundos,
    required this.reproducciones,
    required this.tendencia,
    required this.lugar,
    required this.horarioPico,
    required this.colorPortada,
    this.genero = '',
    this.descripcion = '',
    this.publica = true,
  });
}
