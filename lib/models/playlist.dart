// Playlist creada por el oyente: guarda ids de canciones del catálogo.
class Playlist {
  final String id;
  String nombre;
  final List<String> cancionIds;

  Playlist({required this.id, required this.nombre, List<String>? cancionIds})
    : cancionIds = cancionIds ?? [];

  int get cantidad => cancionIds.length;
}
