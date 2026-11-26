import 'package:streamtunes_demo/data/services/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/data/fuente_firestore.dart';

/// Resultado de poblar la semilla: cuántos documentos se escribieron por
/// colección (vacío = ya había datos y no se tocó nada).
class ResultadoSemilla {
  const ResultadoSemilla(this.escritosPorColeccion);

  final Map<String, int> escritosPorColeccion;

  int get total => escritosPorColeccion.values.fold(0, (a, b) => a + b);

  @override
  String toString() =>
      'escritos por colección: $escritosPorColeccion (total: $total)';
}

/// Puebla de forma IDEMPOTENTE las colecciones vacías con los datos de
/// ejemplo (data/services/datos_ejemplo.dart). Colecciones y cantidad prevista de docs:
///
/// - `canciones`: 4    (id = id del modelo)
/// - `albumes`: 2      (id = id del modelo)
/// - `artistas`: 1     (id = id del modelo)
/// - `conciertos`: 4   (id = 'concierto-N', N desde 1)
/// - `entradas`: 3     (id = 'entrada-N')
/// - `movimientos`: 3  (id = 'movimiento-N')
///
/// Idempotencia y concurrencia: se comprueba `contar == 0` por colección y se
/// escribe con ids DETERMINÍSTICOS vía setDocumento (nunca add). Si dos
/// procesos siembran a la vez, ambos escriben los mismos ids con el mismo
/// contenido: el resultado converge sin duplicados y sin sobrescribir datos
/// distintos (set con el mismo id y mismo contenido es una no-operación).
///
/// Límite de lotes: la colección semilla más grande tiene 4 documentos, muy
/// por debajo del máximo de 500 escrituras por batch de Firestore, así que se
/// usan escrituras individuales (sin WriteBatch). No se cargan imágenes, audio
/// ni binarios: sólo metadatos.
Future<ResultadoSemilla> poblarSemillaSiVacia(FuenteFirestore fuente) async {
  final escritos = <String, int>{};

  await _sembrar(fuente, 'canciones', [
    for (final c in datos.canciones) MapEntry(c.id, c.toMap()),
  ], escritos);
  await _sembrar(fuente, 'albumes', [
    for (final a in datos.albumes) MapEntry(a.id, a.toMap()),
  ], escritos);
  await _sembrar(fuente, 'artistas', [
    for (final a in datos.artistas) MapEntry(a.id, a.toMap()),
  ], escritos);
  // Los modelos sin id propio reciben un id determinístico por posición en la
  // semilla (datos_ejemplo es estático, así que el id es estable entre corridas).
  await _sembrar(fuente, 'conciertos', [
    for (var i = 0; i < datos.conciertos.length; i++)
      MapEntry('concierto-${i + 1}', datos.conciertos[i].toMap()),
  ], escritos);
  await _sembrar(fuente, 'entradas', [
    for (var i = 0; i < datos.entradas.length; i++)
      MapEntry('entrada-${i + 1}', datos.entradas[i].toMap()),
  ], escritos);
  await _sembrar(fuente, 'movimientos', [
    for (var i = 0; i < datos.movimientos.length; i++)
      MapEntry('movimiento-${i + 1}', datos.movimientos[i].toMap()),
  ], escritos);

  return ResultadoSemilla(escritos);
}

/// Si la colección ya tiene documentos, no se toca nada; si está vacía, se
/// escriben todos los documentos recibidos con sus ids determinísticos.
Future<void> _sembrar(
  FuenteFirestore fuente,
  String coleccion,
  List<MapEntry<String, Map<String, dynamic>>> documentos,
  Map<String, int> escritos,
) async {
  if (await fuente.contar(coleccion) != 0) return; // ya tiene datos: intacta
  for (final doc in documentos) {
    await fuente.setDocumento(coleccion, doc.key, doc.value);
  }
  escritos[coleccion] = documentos.length;
}
