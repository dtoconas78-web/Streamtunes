import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:streamtunes_demo/services/audio/motor_audio.dart';

/// Motor de audio real: just_audio hace sonar el audio de demo (en loop) y
/// audio_service lo mantiene sonando en segundo plano, con la notificación
/// de reproducción y los controles de la pantalla bloqueada.
///
/// Las órdenes del sistema (play, pausa, siguiente, anterior, mover la
/// barra) no tocan el reproductor de audio directamente: van a
/// [ComandosAudio] (el ControladorReproduccion), que vuelve a llamar al
/// motor a través del SincronizadorAudio. Así nunca quedan desfasados.
class MotorAudioService extends BaseAudioHandler
    with SeekHandler
    implements MotorAudio {
  MotorAudioService({AudioPlayer? reproductor, AudioSession? sesion})
    // Las interrupciones se manejan acá (no en just_audio) para que el
    // ControladorReproduccion se entere y su estado coincida con el audio.
    : _audio = reproductor ?? AudioPlayer(handleInterruptions: false) {
    unawaited(_audio.setLoopMode(LoopMode.one));
    if (sesion != null) {
      _suscripciones.addAll([
        sesion.interruptionEventStream.listen(_alInterrumpir),
        // Se desconectaron los auriculares: se pausa (no sale por el parlante).
        sesion.becomingNoisyEventStream.listen((_) => _comandos?.pausar()),
      ]);
    }
  }

  final AudioPlayer _audio;
  final List<StreamSubscription<Object?>> _suscripciones = [];
  ComandosAudio? _comandos;

  String? _assetActual;
  Duration _largoLoop = Duration.zero;

  // Lo que pidió el reproductor.
  bool _debeSonar = false;

  // Se pausó por una llamada u otra app: al terminar se reanuda sola.
  bool _pausadoPorInterrupcion = false;

  @override
  set comandos(ComandosAudio comandos) => _comandos = comandos;

  @override
  Future<void> cargar(
    PistaAudio pista, {
    required Duration desde,
    required bool sonando,
  }) async {
    mediaItem.add(
      MediaItem(
        id: pista.id,
        title: pista.titulo,
        artist: pista.artista,
        album: 'StreamTunes',
        duration: pista.duracion,
      ),
    );
    _debeSonar = sonando;
    _publicar(desde, sonando);
    if (pista.asset != _assetActual) {
      _largoLoop = await _audio.setAsset(pista.asset) ?? Duration.zero;
      _assetActual = pista.asset;
    }
    await _audio.seek(_enLoop(desde));
    if (_debeSonar) {
      // play() se completa recién cuando se pausa: no se espera.
      unawaited(_audio.play());
    } else {
      await _audio.pause();
    }
  }

  @override
  Future<void> reanudar() async {
    _debeSonar = true;
    _pausadoPorInterrupcion = false;
    _publicar(_posicionLogica, true);
    unawaited(_audio.play());
  }

  @override
  Future<void> pausar() async {
    _debeSonar = false;
    _publicar(_posicionLogica, false);
    await _audio.pause();
  }

  @override
  Future<void> irA(Duration posicion) async {
    _publicar(posicion, _debeSonar);
    await _audio.seek(_enLoop(posicion));
  }

  @override
  void informarPosicion(Duration posicion, {required bool sonando}) =>
      _publicar(posicion, sonando);

  @override
  Future<void> detener() async {
    _debeSonar = false;
    _assetActual = null;
    await _audio.stop();
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
  }

  // --- Órdenes que llegan del sistema (notificación, auriculares) ---

  @override
  Future<void> play() async => _comandos?.reanudar();

  @override
  Future<void> pause() async => _comandos?.pausar();

  @override
  Future<void> stop() async => _comandos?.pausar();

  @override
  Future<void> skipToNext() async => _comandos?.siguiente();

  @override
  Future<void> skipToPrevious() async => _comandos?.anterior();

  @override
  Future<void> seek(Duration position) async => _comandos?.irA(position);

  // --- Interno ---

  Duration _posicionLogica = Duration.zero;

  // El audio de demo dura menos que la canción y se repite: la posición del
  // audio es la de la canción "dentro del loop".
  Duration _enLoop(Duration posicion) {
    final largo = _largoLoop.inMilliseconds;
    if (largo <= 0) return posicion;
    return Duration(milliseconds: posicion.inMilliseconds % largo);
  }

  void _publicar(Duration posicion, bool sonando) {
    _posicionLogica = posicion;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          sonando ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: sonando,
        updatePosition: posicion,
        speed: 1.0,
      ),
    );
  }

  void _alInterrumpir(AudioInterruptionEvent evento) {
    if (evento.begin) {
      switch (evento.type) {
        case AudioInterruptionType.duck:
          unawaited(_audio.setVolume(0.4)); // otra app habla un momento
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_debeSonar) {
            _pausadoPorInterrupcion = true;
            _comandos?.pausar();
          }
      }
    } else {
      switch (evento.type) {
        case AudioInterruptionType.duck:
          unawaited(_audio.setVolume(1));
        case AudioInterruptionType.pause:
          if (_pausadoPorInterrupcion) _comandos?.reanudar();
          _pausadoPorInterrupcion = false;
        case AudioInterruptionType.unknown:
          _pausadoPorInterrupcion = false; // no se sabe: queda en pausa
      }
    }
  }

  Future<void> liberar() async {
    for (final s in _suscripciones) {
      await s.cancel();
    }
    await _audio.dispose();
  }
}

/// Configura la sesión de audio (música) y arranca el servicio de
/// reproducción en segundo plano. Puede lanzar: quien lo llama decide qué
/// hacer si falla (ver inicializarAudio en inyeccion.dart).
Future<MotorAudioService> crearMotorAudioService() async {
  final sesion = await AudioSession.instance;
  await sesion.configure(const AudioSessionConfiguration.music());
  return AudioService.init(
    builder: () => MotorAudioService(sesion: sesion),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.streamtunes_demo.reproduccion',
      androidNotificationChannelName: 'Reproducción de música',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
