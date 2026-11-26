import 'package:cloud_firestore/cloud_firestore.dart';

// Tipo de movimiento del artista: lo que entra por entradas o por donaciones.
enum TipoMovimiento {
  venta,
  donacion;

  // Texto para mostrar en la UI (los enums van en código, no en pantalla).
  String get etiqueta => this == venta ? 'Venta' : 'Donación';
}

class Movimiento {
  final String id; // id del doc en Firestore ('' = todavía sin asignar)
  final TipoMovimiento tipo;
  final String detalle;
  final double monto;
  final DateTime fecha;
  final String
  usuarioId; // uid del usuario que originó el movimiento ('' = doc antiguo)

  /// Comisión de StreamTunes incluida en [monto] (solo en ventas de
  /// entradas; 0 en donaciones y en documentos antiguos).
  final double comision;

  /// Nombre de quien donó ('' = donación anónima, o un movimiento que no es
  /// donación).
  final String donante;

  /// Artista que recibe la donación ('' = documento antiguo o venta).
  final String artistaId;

  const Movimiento({
    this.id = '',
    required this.tipo,
    required this.detalle,
    required this.monto,
    required this.fecha,
    this.usuarioId = '',
    this.comision = 0,
    this.donante = '',
    this.artistaId = '',
  });

  /// Donación sin nombre de donante.
  bool get esAnonima => tipo == TipoMovimiento.donacion && donante.isEmpty;

  /// Lo que recibe el artista: lo que pagó el fan menos la comisión.
  double get neto => monto - comision;

  /// Igualdad por valor (todos los campos).
  @override
  bool operator ==(Object other) =>
      other is Movimiento &&
      other.id == id &&
      other.tipo == tipo &&
      other.detalle == detalle &&
      other.monto == monto &&
      other.fecha == fecha &&
      other.usuarioId == usuarioId &&
      other.comision == comision &&
      other.donante == donante &&
      other.artistaId == artistaId;

  @override
  int get hashCode => Object.hash(
    id,
    tipo,
    detalle,
    monto,
    fecha,
    usuarioId,
    comision,
    donante,
    artistaId,
  );

  /// Serializa para Firestore: enum como String (name), fecha como
  /// [Timestamp], id fuera del doc.
  Map<String, dynamic> toMap() => {
    'tipo': tipo.name,
    'detalle': detalle,
    'monto': monto,
    'fecha': Timestamp.fromDate(fecha),
    'usuarioId': usuarioId,
    'comision': comision,
    'donante': donante,
    'artistaId': artistaId,
  };

  /// Reconstruye desde un documento de Firestore. [id] es el id del documento
  /// (si no se pasa ni está en el mapa, queda ''). Acepta fecha como
  /// Timestamp / DateTime / String ISO. `usuarioId` es opcional para tolerar
  /// documentos antiguos (queda ''), igual que `donante` y `artistaId`; `comision`
  /// queda en 0. Lanza [FormatException] ante campos
  /// faltantes, tipos inesperados o un `tipo` desconocido.
  factory Movimiento.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc != null && idDoc is! String) {
      throw FormatException(
        'Movimiento.fromMap: id no es String (${idDoc.runtimeType})',
      );
    }
    return Movimiento(
      id: idDoc ?? '',
      tipo: _tipo(map, 'tipo'),
      detalle: _str(map, 'detalle'),
      monto: _num(map, 'monto'),
      fecha: _fecha(map, 'fecha'),
      usuarioId: _strOpcional(map, 'usuarioId', ''),
      comision: map['comision'] == null ? 0 : _num(map, 'comision'),
      donante: _strOpcional(map, 'donante', ''),
      artistaId: _strOpcional(map, 'artistaId', ''),
    );
  }
}

String _strOpcional(Map<String, dynamic> map, String campo, String defecto) {
  final v = map[campo];
  if (v == null) return defecto; // documento antiguo sin el campo
  if (v is! String) {
    throw FormatException(
      'Movimiento.fromMap: "$campo" no es String (${v.runtimeType})',
    );
  }
  return v;
}

TipoMovimiento _tipo(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Movimiento.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  try {
    return TipoMovimiento.values.byName(v);
  } on ArgumentError {
    throw FormatException('Movimiento.fromMap: "$campo" desconocido: "$v"');
  }
}

String _str(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Movimiento.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  return v;
}

double _num(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is num) return v.toDouble();
  throw FormatException(
    'Movimiento.fromMap: "$campo" falta o no es num (${v.runtimeType})',
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
        'Movimiento.fromMap: "$campo" no es una fecha ISO válida: "$v"',
      );
    }
  }
  throw FormatException(
    'Movimiento.fromMap: "$campo" falta o tiene tipo inesperado (${v.runtimeType})',
  );
}
