// Playlist creada por el oyente: guarda ids de canciones del catálogo.
//
// Es mutable a propósito (nombre y cancionIds): el RepositorioPlaylists la
// modifica en el lugar y la UI/tests leen la misma instancia.
class Playlist {
  final String id;
  String nombre;
  final List<String> cancionIds;

  Playlist({required this.id, required this.nombre, List<String>? cancionIds})
    : cancionIds = cancionIds ?? [];

  int get cantidad => cancionIds.length;

  // ---- Serialización (guardado local en JSON) ----

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'cancionIds': List.of(cancionIds),
  };

  /// Tolerante a datos incompletos: devuelve null si falta el id, y descarta
  /// los ids de canción que no sean String.
  static Playlist? fromMap(Object? map) {
    if (map is! Map) return null;
    final id = map['id'];
    if (id is! String || id.isEmpty) return null;
    final nombre = map['nombre'];
    final ids = map['cancionIds'];
    return Playlist(
      id: id,
      nombre: nombre is String ? nombre : '',
      cancionIds: [
        if (ids is List)
          for (final c in ids)
            if (c is String) c,
      ],
    );
  }
}
