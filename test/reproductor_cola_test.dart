import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

void main() {
  setUp(() {
    reproductor.detener();
  });

  test('reproducirCola reproduce la cola en orden y envuelve al final', () {
    final total = catalogo.canciones.length;
    reproductor.reproducirCola([0, 1, 2]);

    expect(reproductor.indiceActual, 0);
    expect(reproductor.reproduciendo, isTrue);
    expect(reproductor.modo, ModoReproduccion.enOrden);

    reproductor.siguiente();
    expect(reproductor.indiceActual, 1);
    reproductor.siguiente();
    expect(reproductor.indiceActual, 2);
    // Al terminar la cola, vuelve a empezar.
    reproductor.siguiente();
    expect(reproductor.indiceActual, 0);

    // Anterior también envuelve.
    reproductor.anterior();
    expect(reproductor.indiceActual, 2);
    reproductor.detener();
    expect(total, greaterThan(2));
  });

  test(
    'reproducirCola puede arrancar en una posición y con modo aleatorio',
    () {
      reproductor.reproducirCola(
        [2, 0, 1],
        inicio: 2,
        modoNuevo: ModoReproduccion.aleatorio,
      );
      expect(reproductor.indiceActual, 1);
      expect(reproductor.modo, ModoReproduccion.aleatorio);
      reproductor.detener();
    },
  );

  test('en modo aleatorio siguiente nunca repite y anterior vuelve atrás', () {
    reproductor.reproducirCola([
      0,
      1,
      2,
      3,
    ], modoNuevo: ModoReproduccion.aleatorio);
    final primera = reproductor.indiceActual;
    expect(primera, isNotNull);

    for (var i = 0; i < 20; i++) {
      final antesDeSaltar = reproductor.indiceActual;
      reproductor.siguiente();
      // Nunca repite la canción que acaba de sonar.
      expect(reproductor.indiceActual, isNot(antesDeSaltar));
      // Y "anterior" vuelve a la que sonaba antes.
      reproductor.anterior();
      expect(reproductor.indiceActual, antesDeSaltar);
    }
    reproductor.detener();
  });

  test('alternarModo cambia entre enOrden y aleatorio', () {
    expect(reproductor.modo, ModoReproduccion.enOrden);
    expect(reproductor.alternarModo(), ModoReproduccion.aleatorio);
    expect(reproductor.alternarModo(), ModoReproduccion.enOrden);
    reproductor.detener();
  });

  test('reproducir una canción suelta vuelve al catálogo completo', () {
    reproductor.reproducirCola([1, 2]);
    reproductor.reproducir(0);
    expect(reproductor.cola, isEmpty);
    reproductor.siguiente();
    expect(reproductor.indiceActual, 1);
    reproductor.detener();
  });

  test('detener limpia la cola y frena la reproducción', () {
    reproductor.reproducirCola([0, 1, 2]);
    reproductor.detener();
    expect(reproductor.hayCancion, isFalse);
    expect(reproductor.cola, isEmpty);
    expect(reproductor.reproduciendo, isFalse);
  });
}
