// Contrato del motor de audio (sin dependencias de plugins: testeable).
//
// El ControladorReproduccion sigue siendo la fuente de verdad de QUÉ suena,
// en qué segundo, la cola y los modos. El motor solo hace sonar el audio que
// corresponde y lo muestra en la notificación / pantalla bloqueada. Ver
// sincronizador_audio.dart (quién le da las órdenes) y
// motor_audio_service.dart (la implementación con just_audio + audio_service).

/// Cantidad de audios de demo incluidos en la app (assets/audio/demo_N.mp3).
/// Son melodías originales generadas con tool/generar_audios_demo.py.
const int cantidadAudiosDemo = 6;

/// Audio de demo que le toca a la canción [cancionId]: siempre el mismo para
/// la misma canción (también para las que sube el artista).
String assetAudioDe(String cancionId) {
  var h = 0;
  for (final c in cancionId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return 'assets/audio/demo_${h % cantidadAudiosDemo + 1}.mp3';
}

/// Lo que se muestra y se hace sonar de una canción.
class PistaAudio {
  const PistaAudio({
    required this.id,
    required this.titulo,
    required this.artista,
    required this.duracion,
    required this.asset,
  });

  final String id;
  final String titulo;
  final String artista;

  /// Duración de la canción en el catálogo (la del audio de demo puede ser
  /// menor: se repite en loop).
  final Duration duracion;
  final String asset;
}

/// Órdenes que llegan desde afuera de la app (notificación, pantalla
/// bloqueada, auriculares). El motor las reenvía al reproductor.
class ComandosAudio {
  const ComandosAudio({
    required this.reanudar,
    required this.pausar,
    required this.siguiente,
    required this.anterior,
    required this.irA,
  });

  final void Function() reanudar;
  final void Function() pausar;
  final void Function() siguiente;
  final void Function() anterior;
  final void Function(Duration posicion) irA;
}

abstract class MotorAudio {
  /// Conecta las órdenes externas (se llama una vez, al armar el
  /// sincronizador).
  set comandos(ComandosAudio comandos);

  /// Carga [pista] y la ubica en [desde]; suena si [sonando].
  Future<void> cargar(
    PistaAudio pista, {
    required Duration desde,
    required bool sonando,
  });

  Future<void> reanudar();
  Future<void> pausar();

  /// Salta a [posicion] de la canción (posición lógica, no la del loop).
  Future<void> irA(Duration posicion);

  /// Informa la posición lógica para la notificación (cada segundo).
  void informarPosicion(Duration posicion, {required bool sonando});

  /// Deja de sonar y saca la notificación.
  Future<void> detener();
}
