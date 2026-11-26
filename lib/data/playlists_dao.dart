import 'package:sqflite/sqflite.dart';
import 'package:streamtunes_demo/models/playlist.dart';

/// Acceso a las tablas `playlists` y `playlist_canciones` (ver
/// data/services/base_datos_local.dart). Todas las consultas usan
/// `whereArgs` / parámetros `?`: nunca se arma SQL concatenando datos.
class PlaylistsDao {
  PlaylistsDao(this._db);

  final DatabaseExecutor _db;

  /// Playlists del usuario [uid], en el orden en que las creó, con sus
  /// canciones en orden.
  Future<List<Playlist>> deUsuario(String uid) async {
    final filas = await _db.query(
      'playlists',
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'orden',
    );
    final canciones = await _db.rawQuery(
      'SELECT pc.playlist_id, pc.cancion_id FROM playlist_canciones pc '
      'JOIN playlists p ON p.id = pc.playlist_id '
      'WHERE p.uid = ? ORDER BY pc.posicion',
      [uid],
    );
    final porPlaylist = <String, List<String>>{};
    for (final c in canciones) {
      porPlaylist
          .putIfAbsent(c['playlist_id']! as String, () => [])
          .add(c['cancion_id']! as String);
    }
    return [
      for (final f in filas)
        Playlist(
          id: f['id']! as String,
          nombre: f['nombre']! as String,
          cancionIds: porPlaylist[f['id']] ?? [],
        ),
    ];
  }

  /// Reemplaza TODAS las playlists de [uid] por [playlists], en una sola
  /// transacción: o se guarda todo o no se guarda nada.
  Future<void> reemplazarDeUsuario(String uid, List<Playlist> playlists) {
    final db = _db;
    Future<void> escribir(DatabaseExecutor txn) async {
      // ON DELETE CASCADE borra también sus canciones.
      await txn.delete('playlists', where: 'uid = ?', whereArgs: [uid]);
      final batch = txn.batch();
      for (final (orden, p) in playlists.indexed) {
        batch.insert('playlists', {
          'id': p.id,
          'uid': uid,
          'nombre': p.nombre,
          'orden': orden,
        });
        for (final (posicion, cancionId) in p.cancionIds.indexed) {
          batch.insert('playlist_canciones', {
            'playlist_id': p.id,
            'cancion_id': cancionId,
            'posicion': posicion,
          });
        }
      }
      await batch.commit(noResult: true);
    }

    return db is Database ? db.transaction(escribir) : escribir(db);
  }
}
