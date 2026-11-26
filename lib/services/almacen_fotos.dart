import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Dónde se guardan las fotos elegidas. Se guarda el ARCHIVO en el celular y
/// en la base/preferencias solo su ruta (nunca la imagen).
abstract class AlmacenFotos {
  /// Copia [origen] (archivo temporal de la cámara/galería) y devuelve la
  /// ruta de la copia. [temporal]: en la carpeta temporal (p. ej. la foto del
  /// documento, que se borra al enviar); si no, en la de documentos de la app.
  Future<String> guardar(
    String origen, {
    required String prefijo,
    bool temporal = false,
  });

  /// Borra una foto guardada (no falla si ya no existe).
  Future<void> borrar(String ruta);

  /// ¿Sigue existiendo el archivo? (el usuario puede haber borrado datos).
  bool existe(String ruta);
}

/// Implementación con path_provider. Las carpetas se pueden inyectar (tests).
class AlmacenFotosLocal implements AlmacenFotos {
  AlmacenFotosLocal({
    Future<Directory> Function()? documentos,
    Future<Directory> Function()? temporales,
  }) : _documentos = documentos ?? getApplicationDocumentsDirectory,
       _temporales = temporales ?? getTemporaryDirectory;

  final Future<Directory> Function() _documentos;
  final Future<Directory> Function() _temporales;
  int _contador = 0;

  @override
  Future<String> guardar(
    String origen, {
    required String prefijo,
    bool temporal = false,
  }) async {
    final base = await (temporal ? _temporales() : _documentos());
    final carpeta = Directory(p.join(base.path, 'fotos'));
    await carpeta.create(recursive: true);
    final extension = p.extension(origen).isEmpty
        ? '.jpg'
        : p.extension(origen).toLowerCase();
    final destino = p.join(
      carpeta.path,
      '$prefijo-${DateTime.now().microsecondsSinceEpoch}-${_contador++}'
      '$extension',
    );
    await File(origen).copy(destino);
    return destino;
  }

  @override
  Future<void> borrar(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } catch (e) {
      debugPrint('No se pudo borrar la foto $ruta: $e');
    }
  }

  @override
  bool existe(String ruta) => File(ruta).existsSync();
}
