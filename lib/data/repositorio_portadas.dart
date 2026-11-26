import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// Fotos de portada de canciones y álbumes (ruta del archivo por id). Las
/// portadas con foto son locales de este celular (no hay Cloud Storage): en
/// otro celular se ve el color de portada de siempre.
abstract class RepositorioPortadas extends ChangeNotifier {
  /// Ruta de la foto de portada de [itemId] (null = usar el color).
  String? rutaDe(String itemId);

  /// Asigna la foto [ruta] a todos los [itemIds] (p. ej. un álbum y sus
  /// canciones).
  Future<void> asignar(List<String> itemIds, String ruta);
}

class RepositorioPortadasMemoria extends RepositorioPortadas {
  final Map<String, String> _rutas = {};

  @override
  String? rutaDe(String itemId) => _rutas[itemId];

  @override
  Future<void> asignar(List<String> itemIds, String ruta) async {
    for (final id in itemIds) {
      _rutas[id] = ruta;
    }
    notifyListeners();
  }
}

/// En SQLite (tabla `portadas`). Se carga todo una vez al arrancar
/// ([cargar]); [rutaDe] responde de memoria.
class RepositorioPortadasSqlite extends RepositorioPortadasMemoria {
  RepositorioPortadasSqlite(this._db);

  final Database _db;

  Future<void> cargar() async {
    try {
      final filas = await _db.query('portadas');
      for (final f in filas) {
        _rutas[f['item_id']! as String] = f['ruta']! as String;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudieron leer las portadas: $e');
    }
  }

  @override
  Future<void> asignar(List<String> itemIds, String ruta) async {
    await super.asignar(itemIds, ruta); // se ve en el acto
    try {
      final batch = _db.batch();
      for (final id in itemIds) {
        batch.insert('portadas', {
          'item_id': id,
          'ruta': ruta,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('No se pudo guardar la portada: $e');
    }
  }
}
