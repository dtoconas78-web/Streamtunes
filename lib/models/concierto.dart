// Concierto inmutable: para cambiar los disponibles se crea una copia nueva
// con conDisponibles() (así nadie modifica un modelo por accidente).
class Concierto {
  final String nombre;
  final String lugar;
  final DateTime fecha;
  final double precio;
  final int disponibles;

  const Concierto({
    required this.nombre,
    required this.lugar,
    required this.fecha,
    required this.precio,
    required this.disponibles,
  });

  Concierto conDisponibles(int nuevasDisponibles) {
    return Concierto(
      nombre: nombre,
      lugar: lugar,
      fecha: fecha,
      precio: precio,
      disponibles: nuevasDisponibles,
    );
  }
}
