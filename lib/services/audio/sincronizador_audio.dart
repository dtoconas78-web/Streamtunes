import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/services/audio/motor_audio.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

/// Hace que el [MotorAudio] siga al [ControladorReproduccion]: cuando cambia
/// la canción la carga, sigue las pausas y los saltos de posición, y le pasa
/// la posición a la notificación. Las órdenes de la notificación (play,
/// pausa, siguiente...) vuelven al reproductor, así el estado vive en un
/// solo lugar.
class SincronizadorAudio {
  SincronizadorAudio({
    required this._reproductor,
    required this._motor,
    required this._nombreArtista,
  }) {
    _motor.comandos = ComandosAudio(
      reanudar: () {
        if (_reproductor.hayCancion && !_reproductor.reproduciendo) {
          _reproductor.alternarPausa();
        }
      },
      pausar: () {
        if (_reproductor.reproduciendo) _reproductor.alternarPausa();
      },
      siguiente: _reproductor.siguiente,
      anterior: _reproductor.anterior,
      irA: (p) => _reproductor.saltarA(p.inSeconds),
    );
    _reproductor.addListener(_alCambiar);
    _alCambiar();
  }

  final ControladorReproduccion _reproductor;
  final MotorAudio _motor;
  final String Function() _nombreArtista;

  // Lo último que se le mandó al motor.
  String? _cancionId;
  int _ultimaPosicion = 0;
  bool _sonando = false;

  void _alCambiar() {
    final cancion = _reproductor.cancion;
    final posicion = _reproductor.posicion;
    final sonando = _reproductor.reproduciendo;

    if (cancion == null) {
      if (_cancionId != null) {
        _cancionId = null;
        _sonando = false;
        _enviar(_motor.detener());
      }
      return;
    }

    if (cancion.id != _cancionId) {
      _cancionId = cancion.id;
      _ultimaPosicion = posicion;
      _sonando = sonando;
      _enviar(
        _motor.cargar(
          PistaAudio(
            id: cancion.id,
            titulo: cancion.titulo,
            artista: _nombreArtista(),
            duracion: Duration(seconds: cancion.duracionSegundos),
            asset: assetAudioDe(cancion.id),
          ),
          desde: Duration(seconds: posicion),
          sonando: sonando,
        ),
      );
      return;
    }

    // Misma canción: un avance normal es +1 por segundo (o 0 si solo cambió
    // otra cosa). Cualquier otro salto es la barra, "anterior" que vuelve al
    // inicio o "repetir" que la empieza de nuevo.
    if (posicion != _ultimaPosicion && posicion != _ultimaPosicion + 1) {
      _enviar(_motor.irA(Duration(seconds: posicion)));
    }
    _ultimaPosicion = posicion;

    if (sonando != _sonando) {
      _sonando = sonando;
      _enviar(sonando ? _motor.reanudar() : _motor.pausar());
    }
    _motor.informarPosicion(Duration(seconds: posicion), sonando: sonando);
  }

  // Un error del motor (archivo, plugin) nunca rompe el reproductor: la app
  // sigue funcionando como antes, sin sonido.
  void _enviar(Future<void> orden) {
    unawaited(
      orden.catchError((Object e) {
        debugPrint('Audio: no se pudo ejecutar la orden: $e');
      }),
    );
  }

  void dispose() => _reproductor.removeListener(_alCambiar);
}
