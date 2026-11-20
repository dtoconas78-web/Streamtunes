import 'package:cloud_firestore/cloud_firestore.dart';

// Concierto inmutable: para cambiar los disponibles se crea una copia nueva
// con conDisponibles() (así nadie modifica un modelo por accidente).
class Concierto {
  final String id; // id del doc en Firestore ('' = todavía sin asignar)
  final String nombre;
  final String lugar;
  final DateTime fecha;
  final double precio;
  final int disponibles;

  const Concierto({
    this.id = '',
    required this.nombre,
    required this.lugar,
    required this.fecha,
    required this.precio,
    required this.disponibles,
  });

  /// Igualdad por valor (todos los campos).
  @override
  bool operator ==(Object other) =>
      other is Concierto &&
      other.id == id &&
      other.nombre == nombre &&
      other.lugar == lugar &&
      other.fecha == fecha &&
      other.precio == precio &&
      other.disponibles == disponibles;

  @override
  int get hashCode =>
      Object.hash(id, nombre, lugar, fecha, precio, disponibles);

  Concierto conDisponibles(int nuevasDisponibles) {
    return Concierto(
      id: id,
      nombre: nombre,
      lugar: lugar,
      fecha: fecha,
      precio: precio,
      disponibles: nuevasDisponibles,
    );
  }

  /// Serializa para Firestore: fecha como [Timestamp], id fuera del doc.
  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'lugar': lugar,
    'fecha': Timestamp.fromDate(fecha),
    'precio': precio,
    'disponibles': disponibles,
  };

  /// Reconstruye desde un documento de Firestore. [id] es el id del documento;
  /// si no se pasa, se usa `map['id']`; si no hay ninguno queda '' (sin
  /// asignar). Acepta fecha como Timestamp (Firestore), DateTime o String ISO
  /// (fakes). Lanza [FormatException] ante campos inválidos.
  factory Concierto.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc != null && idDoc is! String) {
      throw FormatException(
        'Concierto.fromMap: id no es String (${idDoc.runtimeType})',
      );
    }
    return Concierto(
      id: idDoc ?? '',
      nombre: _str(map, 'nombre'),
      lugar: _str(map, 'lugar'),
      fecha: _fecha(map, 'fecha'),
      precio: _num(map, 'precio'),
      disponibles: _int(map, 'disponibles'),
    );
  }
}

String _str(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Concierto.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  return v;
}

int _int(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is int) return v;
  if (v is num && v == v.truncate()) return v.toInt();
  throw FormatException(
    'Concierto.fromMap: "$campo" falta o no es entero (${v.runtimeType})',
  );
}

double _num(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is num) return v.toDouble();
  throw FormatException(
    'Concierto.fromMap: "$campo" falta o no es num (${v.runtimeType})',
  );
}

DateTime _fecha(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is DateTime) return v; // fakes en memoria
  if (v is Timestamp) return v.toDate(); // Firestore real
  if (v is String) {
    try {
      return DateTime.parse(v); // ISO 8601 (fakes)
    } on FormatException {
      throw FormatException(
        'Concierto.fromMap: "$campo" no es una fecha ISO válida: "$v"',
      );
    }
  }
  throw FormatException(
    'Concierto.fromMap: "$campo" falta o tiene tipo inesperado (${v.runtimeType})',
  );
}
