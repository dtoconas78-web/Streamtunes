import 'dart:collection';

// Modelo simple para representar un álbum.
// No depende de Flutter: el color de portada se guarda como int ARGB.
// "cancionIds" son los ids de sus canciones (más robusto que posiciones:
// si el catálogo cambia de orden, el álbum sigue apuntando bien).
//
// Inmutable también por dentro: la lista de ids es privada y se expone como
// vista de solo lectura, así nadie puede cambiar un álbum del catálogo sin
// pasar por el repositorio. El constructor sigue siendo const (lo usan los
// tests), por eso no copia la lista: quien construye pasa una lista propia.
class Album {
  final String id;
  final String titulo;
  final String anio;
  final int colorPortada;
  final List<String> _cancionIds;

  const Album({
    required this.id,
    required this.titulo,
    required this.anio,
    required this.colorPortada,
    required this._cancionIds,
  });

  /// Ids de las canciones, de solo lectura (agregar o quitar lanza
  /// UnsupportedError).
  List<String> get cancionIds => UnmodifiableListView(_cancionIds);

  /// Igualdad por valor (incluye la lista de ids, comparada elemento a
  /// elemento para no depender de Flutter).
  @override
  bool operator ==(Object other) =>
      other is Album &&
      other.id == id &&
      other.titulo == titulo &&
      other.anio == anio &&
      other.colorPortada == colorPortada &&
      _mismasIds(other.cancionIds, cancionIds);

  @override
  int get hashCode =>
      Object.hash(id, titulo, anio, colorPortada, Object.hashAll(cancionIds));

  /// Serializa para Firestore. El [id] NO va dentro del documento (es la
  /// clave del doc; en fromMap llega por parámetro).
  Map<String, dynamic> toMap() => {
    'titulo': titulo,
    'anio': anio,
    'colorPortada': colorPortada,
    'cancionIds': List.of(_cancionIds),
  };

  /// Reconstruye desde un documento de Firestore. Lanza [FormatException]
  /// ante campos faltantes o de tipo inesperado.
  factory Album.fromMap(Map<String, dynamic> map, {String? id}) {
    final idDoc = id ?? map['id'];
    if (idDoc is! String || idDoc.isEmpty) {
      throw FormatException(
        "Album.fromMap: falta el id (ni parámetro ni map['id'])",
      );
    }
    return Album(
      id: idDoc,
      titulo: _str(map, 'titulo'),
      anio: _str(map, 'anio'),
      colorPortada: _int(map, 'colorPortada'),
      cancionIds: _listaStr(map, 'cancionIds'),
    );
  }
}

String _str(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! String) {
    throw FormatException(
      'Album.fromMap: "$campo" falta o no es String (${v.runtimeType})',
    );
  }
  return v;
}

int _int(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is int) return v;
  if (v is num && v == v.truncate()) return v.toInt();
  throw FormatException(
    'Album.fromMap: "$campo" falta o no es entero (${v.runtimeType})',
  );
}

bool _mismasIds(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<String> _listaStr(Map<String, dynamic> map, String campo) {
  final v = map[campo];
  if (v is! List) {
    throw FormatException(
      'Album.fromMap: "$campo" falta o no es List (${v.runtimeType})',
    );
  }
  return [
    for (final e in v)
      if (e is String)
        e
      else
        throw FormatException(
          'Album.fromMap: "$campo" tiene un elemento no-String (${e.runtimeType})',
        ),
  ];
}
