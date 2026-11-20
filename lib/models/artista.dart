// Artista que se puede seguir y apoyar. La regla de la app es que solo
// se le puede donar a un artista al que se sigue.
class Artista {
  final String id;
  final String nombre;

  const Artista({required this.id, required this.nombre});

  /// Igualdad por valor.
  @override
  bool operator ==(Object other) =>
      other is Artista && other.id == id && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, nombre);

  /// Serializa para Firestore. El [id] NO va dentro del documento (es la
  /// clave del doc; en fromMap llega por parámetro).
  Map<String, dynamic> toMap() => {'nombre': nombre};

  /// Reconstruye desde un documento de Firestore. [id] es el id del documento
  /// (fuente real del id); si no se pasa, se toma de `map['id']`. Lanza
  /// [FormatException] si falta el id o algún campo obligatorio.
  factory Artista.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc is! String || idDoc.isEmpty) {
      throw FormatException(
        "Artista.fromMap: falta el id (ni parámetro ni map['id'])",
      );
    }
    final nombre = map['nombre'];
    if (nombre is! String) {
      throw FormatException(
        'Artista.fromMap: "nombre" falta o no es String (${nombre.runtimeType})',
      );
    }
    return Artista(id: idDoc, nombre: nombre);
  }
}
