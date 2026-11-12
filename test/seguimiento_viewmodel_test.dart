import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';

void main() {
  test('seguir y dejar de seguir notifican y actualizan las listas', () {
    final s = SeguimientoViewModel();
    var notificaciones = 0;
    s.addListener(() => notificaciones++);

    expect(s.seguidos, isEmpty);
    expect(s.noSeguidos, isNotEmpty);

    s.seguir('mateo-cabral');
    expect(s.sigo('mateo-cabral'), isTrue);
    expect(s.seguidos.length, 1);
    expect(s.noSeguidos, isEmpty);
    expect(notificaciones, 1);

    // Seguir de nuevo no vuelve a notificar.
    s.seguir('mateo-cabral');
    expect(notificaciones, 1);

    s.dejarDeSeguir('mateo-cabral');
    expect(s.sigo('mateo-cabral'), isFalse);
    expect(notificaciones, 2);
  });

  test('alternar cambia el estado de seguimiento', () {
    final s = SeguimientoViewModel();
    expect(s.sigo('mateo-cabral'), isFalse);
    s.alternar('mateo-cabral');
    expect(s.sigo('mateo-cabral'), isTrue);
    s.alternar('mateo-cabral');
    expect(s.sigo('mateo-cabral'), isFalse);
  });

  test('seguir álbumes: solo los seguidos aparecen en albumesSeguidos', () {
    final s = SeguimientoViewModel();
    var notificaciones = 0;
    s.addListener(() => notificaciones++);

    // Al principio no hay álbumes seguidos.
    expect(s.albumesSeguidos, isEmpty);
    expect(s.sigoAlbum('postales'), isFalse);

    s.alternarAlbum('postales');
    expect(s.sigoAlbum('postales'), isTrue);
    expect(s.albumesSeguidos.length, 1);
    expect(s.albumesSeguidos.first.id, 'postales');
    expect(s.albumesSeguidos.first.titulo, 'Postales');
    expect(notificaciones, 1);

    // Dejar de seguir lo saca de la lista.
    s.alternarAlbum('postales');
    expect(s.sigoAlbum('postales'), isFalse);
    expect(s.albumesSeguidos, isEmpty);
    expect(notificaciones, 2);

    // Seguir un id que no existe en el catálogo no rompe la lista.
    s.alternarAlbum('no-existe');
    expect(s.albumesSeguidos, isEmpty);
  });
}
