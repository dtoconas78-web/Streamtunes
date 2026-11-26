import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/models/concierto.dart';

/// Ids de los conciertos ya vistos por la verificación de novedades.
const String claveConciertosVistos = 'streamtunes.novedades.conciertosVistos';

/// Lógica de la tarea periódica de novedades, separada del
/// callbackDispatcher para poder probarla con dobles (sin workmanager, sin
/// Firebase y sin plugin de notificaciones).
///
/// Lee la colección pública `conciertos` (lectura pública: no necesita
/// sesión) y compara con los ids ya vistos guardados en [prefs]:
/// - Primera corrida (no hay nada guardado): solo guarda la línea de base y
///   no avisa, así no se anuncian como "nuevos" todos los conciertos.
/// - Siguientes: avisa con [avisar] los conciertos que no estaban y actualiza
///   lo guardado. Si [avisar] falla, no se guarda, y se reintenta la próxima.
///
/// Devuelve los conciertos nuevos avisados.
Future<List<Concierto>> verificarNovedades({
  required FuenteFirestore fuente,
  required SharedPreferencesAsync prefs,
  required Future<void> Function(List<String> nombres) avisar,
  Duration limite = const Duration(seconds: 30),
}) async {
  final docs = await fuente
      .snapshotsColeccion('conciertos')
      .first
      .timeout(limite);
  final actuales = <String, Concierto>{};
  for (final d in docs) {
    try {
      actuales[d.id] = Concierto.fromMap(d.datos, id: d.id);
    } on FormatException {
      // Documento mal formado: se ignora, no frena la verificación.
    }
  }

  final vistos = await prefs.getStringList(claveConciertosVistos);
  final nuevos = vistos == null
      ? const <Concierto>[]
      : [
          for (final e in actuales.entries)
            if (!vistos.contains(e.key)) e.value,
        ];
  if (nuevos.isNotEmpty) {
    await avisar([for (final c in nuevos) c.nombre]);
  }
  await prefs.setStringList(claveConciertosVistos, actuales.keys.toList());
  return nuevos;
}
