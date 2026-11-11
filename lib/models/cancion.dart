// Modelo simple para representar una canción.
// No depende de Flutter: el color de portada se guarda como int ARGB
// (conviertelo con colorDe() de theme/colores.dart para mostrarlo).
class Cancion {
  final String titulo;
  final String duracion;
  final String reproducciones;
  final String tendencia;
  final String lugar;
  final String horarioPico;
  final int colorPortada;
  final String genero;
  final String descripcion;
  final bool publica;

  const Cancion({
    required this.titulo,
    required this.duracion,
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
