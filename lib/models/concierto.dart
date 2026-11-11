class Concierto {
  final String nombre;
  final String lugar;
  final DateTime fecha;
  final double precio;
  int disponibles;

  Concierto({
    required this.nombre,
    required this.lugar,
    required this.fecha,
    required this.precio,
    required this.disponibles,
  });
}
