import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/services/audio/motor_audio.dart';
import 'package:streamtunes_demo/services/audio/sincronizador_audio.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

/// Motor que anota las órdenes en vez de hacer sonar algo.
class _MotorFalso implements MotorAudio {
  final ordenes = <String>[];
  ComandosAudio? comandosRecibidos;
  Duration? ultimaPosicionInformada;

  @override
  set comandos(ComandosAudio comandos) => comandosRecibidos = comandos;

  @override
  Future<void> cargar(
    PistaAudio pista, {
    required Duration desde,
    required bool sonando,
  }) async => ordenes.add(
    'cargar ${pista.id} ${pista.asset} ${desde.inSeconds} '
    '${sonando ? 'sonando' : 'pausa'} ${pista.artista}',
  );

  @override
  Future<void> reanudar() async => ordenes.add('reanudar');

  @override
  Future<void> pausar() async => ordenes.add('pausar');

  @override
  Future<void> irA(Duration posicion) async =>
      ordenes.add('irA ${posicion.inSeconds}');

  @override
  void informarPosicion(Duration posicion, {required bool sonando}) =>
      ultimaPosicionInformada = posicion;

  @override
  Future<void> detener() async => ordenes.add('detener');
}

void main() {
  group('assetAudioDe', () {
    test(
      'siempre el mismo audio para la misma canción, dentro de los demo',
      () {
        for (final id in ['luces-de-la-ciudad', 'ruta-7', 'pista-123-0', '']) {
          final a = assetAudioDe(id);
          expect(a, assetAudioDe(id));
          expect(
            RegExp(r'^assets/audio/demo_([1-6])\.mp3$').hasMatch(a),
            isTrue,
            reason: a,
          );
        }
      },
    );

    test('las canciones del catálogo de ejemplo no suenan todas igual', () {
      final assets = {
        for (final c in RepositorioCatalogoMemoria().canciones)
          assetAudioDe(c.id),
      };
      expect(assets.length, greaterThan(1));
    });
  });

  group('SincronizadorAudio', () {
    late RepositorioCatalogoMemoria catalogo;
    late ControladorReproduccion reproductor;
    late _MotorFalso motor;
    late SincronizadorAudio sincronizador;

    setUp(() {
      catalogo = RepositorioCatalogoMemoria();
      reproductor = ControladorReproduccion(repositorioCatalogo: catalogo);
      motor = _MotorFalso();
      sincronizador = SincronizadorAudio(
        reproductor: reproductor,
        motor: motor,
        nombreArtista: () => 'Mateo Cabral',
      );
    });

    tearDown(() {
      sincronizador.dispose();
      reproductor.detener(); // cancela el timer
    });

    test('al reproducir carga el audio de esa canción y suena', () {
      reproductor.reproducir(1);
      final c = catalogo.canciones[1];
      expect(motor.ordenes, [
        'cargar ${c.id} ${assetAudioDe(c.id)} 0 sonando Mateo Cabral',
      ]);
    });

    test('reproducir una playlist (cola) carga la primera de la cola', () {
      reproductor.reproducirCola([2, 0]);
      expect(
        motor.ordenes.single,
        startsWith('cargar ${catalogo.canciones[2].id} '),
      );

      reproductor.siguiente();
      expect(
        motor.ordenes.last,
        startsWith('cargar ${catalogo.canciones[0].id} '),
      );
    });

    test('pausa y reanuda', () {
      reproductor.reproducir(0);
      reproductor.alternarPausa();
      reproductor.alternarPausa();
      expect(motor.ordenes.skip(1), ['pausar', 'reanudar']);
    });

    test('mover la barra salta a esa posición', () {
      reproductor.reproducir(0);
      reproductor.saltarA(90);
      expect(motor.ordenes.last, 'irA 90');
      expect(motor.ultimaPosicionInformada, const Duration(seconds: 90));
    });

    test('un avance normal de un segundo no es un salto', () {
      reproductor.reproducir(0);
      reproductor.saltarA(10);
      motor.ordenes.clear();
      reproductor.saltarA(11);
      expect(motor.ordenes, isEmpty);
      expect(motor.ultimaPosicionInformada, const Duration(seconds: 11));
    });

    test('"anterior" pasados 3 s vuelve al inicio de la misma canción', () {
      reproductor.reproducir(0);
      reproductor.saltarA(20);
      reproductor.anterior();
      expect(motor.ordenes.last, 'irA 0');
    });

    test('al detener (cerrar sesión) se detiene el audio', () {
      reproductor.reproducir(0);
      reproductor.detener();
      expect(motor.ordenes.last, 'detener');
    });

    test('las órdenes de la notificación llegan al reproductor', () {
      reproductor.reproducirCola([0, 1, 2]);
      final comandos = motor.comandosRecibidos!;

      comandos.pausar();
      expect(reproductor.reproduciendo, isFalse);
      comandos.reanudar();
      expect(reproductor.reproduciendo, isTrue);

      comandos.siguiente();
      expect(reproductor.cancion!.id, catalogo.canciones[1].id);

      comandos.irA(const Duration(seconds: 42));
      expect(reproductor.posicion, 42);
    });

    test('reanudar desde la notificación sin canción no hace nada', () {
      motor.comandosRecibidos!.reanudar();
      expect(reproductor.reproduciendo, isFalse);
      expect(motor.ordenes, isEmpty);
    });
  });
}
