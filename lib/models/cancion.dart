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

  /// Igualdad por valor (todos los campos): permite comparar listas de
  /// modelos (p. ej. para no notificar cuando un snapshot no cambió nada).
  @override
  bool operator ==(Object other) =>
      other is Cancion &&
      other.id == id &&
      other.titulo == titulo &&
      other.duracionSegundos == duracionSegundos &&
      other.reproducciones == reproducciones &&
      other.tendencia == tendencia &&
      other.lugar == lugar &&
      other.horarioPico == horarioPico &&
      other.colorPortada == colorPortada &&
      other.genero == genero &&
      other.descripcion == descripcion &&
      other.publica == publica;

  @override
  int get hashCode => Object.hash(
    id,
    titulo,
    duracionSegundos,
    reproducciones,
    tendencia,
    lugar,
    horarioPico,
    colorPortada,
    genero,
    descripcion,
    publica,
  );

  /// Serializa para Firestore. El [id] NO va dentro del documento: es la
  /// clave del doc y en fromMap llega por parámetro.
  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'duracionSegundos': duracionSegundos,
    'reproducciones': reproducciones,
    'tendencia': tendencia,
    'lugar': lugar,
    'horarioPico': horarioPico,
    'colorPortada': colorPortada,
    'genero': genero,
    'descripcion': descripcion,
    'publica': publica,
  };

  /// Reconstruye desde un documento de Firestore. [id] es el id del documento
  /// (fuente real del id); si no se pasa, se toma de `map['id']`. Lanza
  /// [FormatException] ante campos obligatorios faltantes o de tipo
  /// inesperado: nunca inventa valores ni hace conversiones silenciosas.
  factory Cancion.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc is! String || idDoc.isEmpty) {
      throw FormatException(
        "Cancion.fromMap: falta el id (ni parámetro ni map['id'])",
      );
    }
    return Cancion(
      id: idDoc,
      titulo: _str(map, 'titulo'),
      duracionSegundos: _int(map, 'duracionSegundos'),
      reproducciones: _int(map, 'reproducciones'),
      tendencia: _str(map, 'tendencia'),
      lugar: _str(map, 'lugar'),
      horarioPico: _str(map, 'horarioPico'),
      colorPortada: _int(map, 'colorPortada'),
      genero: _strOpcional(map, 'genero', ''),
      descripcion: _strOpcional(map, 'descripcion', ''),
      publica: _boolOpcional(map, 'publica', true),
    );
  }
}

String _str(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Cancion.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  return v;
}

String _strOpcional(Map<String, dynamic> map, String campo, String defecto) {
  final v = map[campo];
  if (v == null) return defecto;
  if (v is! String) {
    throw FormatException(
      'Cancion.fromMap: "$campo" no es String (${v.runtimeType})',
    );
  }
  return v;
}

int _int(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is int) return v;
  if (v is num && v == v.truncate()) return v.toInt();
  throw FormatException(
    'Cancion.fromMap: "$campo" falta o no es entero (${v.runtimeType})',
  );
}

bool _boolOpcional(Map<String, dynamic> map, String campo, bool defecto) {
  final v = map[campo];
  if (v == null) return defecto;
  if (v is! bool) {
    throw FormatException(
      'Cancion.fromMap: "$campo" no es bool (${v.runtimeType})',
    );
  }
  return v;
}
