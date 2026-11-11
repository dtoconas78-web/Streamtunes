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
}
