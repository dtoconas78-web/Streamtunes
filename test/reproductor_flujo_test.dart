import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/reproductor_screen.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

void main() {
  setUp(() {
    authViewModel.logout();
    reproductor.marcarPantallaCompleta(false);
  });

  testWidgets('reproducir una canción y abrir el reproductor grande no falla', (
    tester,
  ) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();

    // Entrar como invitado y escuchar.
    await tester.tap(find.text('Entrar como invitado'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Tocar la primera canción de Explorar.
    await tester.tap(find.byIcon(Icons.play_circle).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(reproductor.hayCancion, isTrue);

    // Abrir el reproductor grande tocando el mini-player.
    await tester.tap(
      find
          .descendant(
            of: find.byType(MiniReproductor),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PantallaReproductor), findsOneWidget);
    expect(find.text('Reproduciendo'), findsOneWidget);

    // Controles dentro del reproductor grande.
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.pump();

    // Cerrar el reproductor grande: vuelve el mini-player.
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaReproductor), findsNothing);
    expect(reproductor.pantallaCompletaAbierta, isFalse);

    // Frenar el reloj global para no terminar el test con timers pendientes.
    reproductor.detener();
  });
}
