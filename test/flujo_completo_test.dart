import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/views/screens/publicar_concierto_screen.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';
import 'package:streamtunes_demo/views/widgets/mini_reproductor.dart';

// Suite E2E de flujos completos. Acá viven las regresiones que antes estaban
// sueltas en repro_scratch_test.dart: si alguno de estos tests falla, se rompió
// un flujo real de la app.
void main() {
  setUp(() {
    authViewModel.logout();
    reproductor.detener();
  });

  Future<void> entrarComoOyente(WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    authViewModel.login(
      const Usuario(
        id: 'o1',
        nombre: 'Ana',
        email: 'ana@example.com',
        rol: RolUsuario.oyente,
      ),
    );
    await tester.pump();
  }

  Future<void> entrarComoArtista(WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    authViewModel.login(
      const Usuario(
        id: 'a1',
        nombre: 'Mateo',
        email: 'mateo@example.com',
        rol: RolUsuario.artista,
      ),
    );
    await tester.pump();
  }

  testWidgets('regresión: el sheet de donar se cierra arrastrando abajo', (
    tester,
  ) async {
    await entrarComoOyente(tester);
    // pestaña Donar (índice 1)
    await tester.tap(find.text('Donar').last);
    await tester.pump();
    // seguir al artista para que aparezca en "podés donar"
    seguimientoViewModel.seguir('mateo-cabral');
    await tester.pump();
    await tester.tap(find.text('Mateo Cabral'));
    await tester.pumpAndSettle();
    expect(find.text('Donar a Mateo Cabral'), findsOneWidget);
    // escribir un monto a mano (teclado abierto) y después arrastrar abajo
    await tester.enterText(find.byType(TextField), '1500');
    await tester.pump();
    await tester.drag(find.text('Donar a Mateo Cabral'), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Donar a Mateo Cabral'), findsNothing);
    // y confirmar un monto con el botón para ver el snackbar de gracias
    await tester.tap(find.text('Mateo Cabral'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\$1.000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donar \$1.000'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Donaste', findRichText: true), findsOneWidget);
  });

  testWidgets('regresión: crear playlist con nombre y tocar Crear', (
    tester,
  ) async {
    await entrarComoOyente(tester);
    // pestaña Biblioteca (índice 4)
    await tester.tap(find.text('Biblioteca').last);
    await tester.pump();
    await tester.tap(find.text('Crear playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mi playlist');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(find.text('Mi playlist'), findsWidgets);
  });

  testWidgets('regresión: reproducir playlist abre el mini reproductor', (
    tester,
  ) async {
    await entrarComoOyente(tester);
    final p = playlistsViewModel.crear('Repro');
    playlistsViewModel.agregarCancion(p.id, 'luces-de-la-ciudad');
    navegadorKey.currentState!.pushNamed(Rutas.playlist, arguments: p);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir'));
    await tester.pump();
    expect(reproductor.hayCancion, isTrue);
    expect(find.byType(MiniReproductor), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MiniReproductor),
        matching: find.text('Luces de la Ciudad'),
      ),
      findsOneWidget,
    );
    reproductor.detener();
  });

  testWidgets('regresión: reproducir álbum abre el mini reproductor', (
    tester,
  ) async {
    await entrarComoOyente(tester);
    navegadorKey.currentState!.pushNamed(
      Rutas.album,
      arguments: catalogo.albumes.first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir'));
    await tester.pump();
    expect(reproductor.hayCancion, isTrue);
    expect(find.byType(MiniReproductor), findsOneWidget);
    reproductor.detener();
  });

  testWidgets(
    'regresión: inicio con tamaño de teléfono físico y texto grande',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.15;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await entrarComoOyente(tester);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'regresión: el artista publica un concierto (teléfono chico, texto grande)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1.0;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await entrarComoArtista(tester);
      navegadorKey.currentState!.pushNamed(Rutas.publicarConcierto);
      await tester.pumpAndSettle();
      Future<void> escribir(int i, String texto) async {
        final campo = find.byType(TextFormField).at(i);
        await tester.ensureVisible(campo);
        await tester.pump();
        await tester.enterText(campo, texto);
        await tester.pump();
      }

      await escribir(0, 'Show en vivo');
      await escribir(1, 'Teatro Colon');
      // elegir fecha con el date picker
      await tester.ensureVisible(find.byIcon(Icons.event));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      await escribir(3, '5000');
      await escribir(4, '100');
      await tester.ensureVisible(find.byType(BotonPrincipal));
      await tester.pump();
      await tester.tap(find.byType(BotonPrincipal));
      await tester.pumpAndSettle();
      expect(
        entradasViewModel.conciertosDisponibles.any(
          (c) => c.nombre == 'Show en vivo',
        ),
        isTrue,
      );
      expect(find.byType(PublicarConciertoScreen), findsNothing);
    },
  );

  testWidgets(
    'regresión: barrido de pantallas de artista a 320x568 con texto 1.3',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await entrarComoArtista(tester);
      await tester.pumpAndSettle();
      for (final ruta in [
        Rutas.ventas,
        Rutas.publicarConcierto,
        Rutas.subirMusica,
        Rutas.editarPerfil,
        Rutas.verificacion,
      ]) {
        navegadorKey.currentState!.pushNamed(ruta);
        await tester.pumpAndSettle();
        navegadorKey.currentState!.pop();
        await tester.pumpAndSettle();
      }
      // y la pantalla de álbum (ruta del oyente, pero renderizable igual)
      navegadorKey.currentState!.pushNamed(
        Rutas.album,
        arguments: catalogo.albumes.first,
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'al cambiar de usuario no se ven las playlists ni los seguidos del anterior',
    (tester) async {
      await entrarComoOyente(tester);
      playlistsViewModel.crear('De Ana');
      seguimientoViewModel.seguir('mateo-cabral');
      await tester.pump();
      expect(playlistsViewModel.playlists, isNotEmpty);

      cerrarSesion();
      await tester.pump();
      authViewModel.login(
        const Usuario(
          id: 'o2',
          nombre: 'Beto',
          email: 'beto@example.com',
          rol: RolUsuario.oyente,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Biblioteca').last);
      await tester.pump();

      expect(playlistsViewModel.playlists, isEmpty);
      expect(seguimientoViewModel.seguidos, isEmpty);
      expect(find.text('De Ana'), findsNothing);
    },
  );
}
