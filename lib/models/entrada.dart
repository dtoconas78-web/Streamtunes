import 'package:cloud_firestore/cloud_firestore.dart';

class Entrada {
  final String id; // id del doc en Firestore ('' = todavía sin asignar)
  final String concierto; // nombre del concierto (se muestra en la UI)
  final String conciertoId; // id del doc en `conciertos` ('' = doc antiguo)
  final String lugar;
  final DateTime fecha;
  final double precio;
  final int cantidad;
  final String usuarioId; // uid del comprador ('' = sin asignar / doc antiguo)

  Entrada({
    this.id = '',
    required this.concierto,
    this.conciertoId = '',
    required this.lugar,
    required this.fecha,
    required this.precio,
    required this.cantidad,
    this.usuarioId = '',
  });

  /// Igualdad por valor (todos los campos).
  @override
  bool operator ==(Object other) =>
      other is Entrada &&
      other.id == id &&
      other.concierto == concierto &&
      other.conciertoId == conciertoId &&
      other.lugar == lugar &&
      other.fecha == fecha &&
      other.precio == precio &&
      other.cantidad == cantidad &&
      other.usuarioId == usuarioId;

  @override
  int get hashCode => Object.hash(
    id,
    concierto,
    conciertoId,
    lugar,
    fecha,
    precio,
    cantidad,
    usuarioId,
  );

  /// Serializa para Firestore: fecha como [Timestamp], id fuera del doc.
  Map<String, dynamic> toMap() => {
    'concierto': concierto,
    'conciertoId': conciertoId,
    'lugar': lugar,
    'fecha': Timestamp.fromDate(fecha),
    'precio': precio,
    'cantidad': cantidad,
    'usuarioId': usuarioId,
  };

  /// Reconstruye desde un documento de Firestore. [id] es el id del documento
  /// (si no se pasa ni está en el mapa, queda ''). Acepta fecha como
  /// Timestamp / DateTime / String ISO. Los campos `conciertoId` y
  /// `usuarioId` son opcionales para tolerar documentos antiguos (quedan '').
  /// Lanza [FormatException] si hay campos obligatorios faltantes o de tipo
  /// inesperado.
  factory Entrada.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc != null && idDoc is! String) {
      throw FormatException(
        'Entrada.fromMap: id no es String (${idDoc.runtimeType})',
      );
    }
    return Entrada(
      id: idDoc ?? '',
      concierto: _str(map, 'concierto'),
      conciertoId: _strOpcional(map, 'conciertoId', ''),
      lugar: _str(map, 'lugar'),
      fecha: _fecha(map, 'fecha'),
      precio: _num(map, 'precio'),
      cantidad: _int(map, 'cantidad'),
      usuarioId: _strOpcional(map, 'usuarioId', ''),
    );
  }
}

String _str(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Entrada.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  return v;
}

String _strOpcional(Map<String, dynamic> map, String campo, String defecto) {
  final v = map[campo];
  if (v == null) return defecto; // documento antiguo sin el campo
  if (v is! String) {
    throw FormatException(
      'Entrada.fromMap: "$campo" no es String (${v.runtimeType})',
    );
  }
  return v;
}

int _int(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is int) return v;
  if (v is num && v == v.truncate()) return v.toInt();
  throw FormatException(
    'Entrada.fromMap: "$campo" falta o no es entero (${v.runtimeType})',
  );
}

double _num(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is num) return v.toDouble();
  throw FormatException(
    'Entrada.fromMap: "$campo" falta o no es num (${v.runtimeType})',
  );
}

DateTime _fecha(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  if (v is String) {
    try {
      return DateTime.parse(v);
    } on FormatException {
      throw FormatException(
        'Entrada.fromMap: "$campo" no es una fecha ISO válida: "$v"',
      );
    }
  }
  throw FormatException(
    'Entrada.fromMap: "$campo" falta o tiene tipo inesperado (${v.runtimeType})',
  );
}
