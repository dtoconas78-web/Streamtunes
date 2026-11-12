import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/explorar_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/oyente_shell.dart';
import 'package:streamtunes_demo/views/screens/perfil_oyente_screen.dart';
import 'package:streamtunes_demo/views/screens/registro_screen.dart';

void main() {
  setUp(() => authViewModel.logout());

  testWidgets('sin sesión la app muestra la pantalla de acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('StreamTunes'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Continuar con email'), findsOneWidget);
    expect(find.text('Entrar como invitado'), findsOneWidget);
  });

  testWidgets('el invitado solo ve Explorar (escuchar gratis)', (tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    await tester.tap(find.text('Entrar como invitado'));
    await tester.pump();
    // avanza el "login" simulado del AuthService
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(authViewModel.esInvitado, isTrue);
    expect(authViewModel.esRegistrado, isFalse);
    expect(find.byType(ExplorarScreen), findsOneWidget);
    expect(find.text('Estás como invitado'), findsOneWidget);
  });

  testWidgets('el registro también ofrece registrarse con Google', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RegistroScreen()));
    await tester.pump();
    expect(find.text('Registrarse con Google'), findsOneWidget);
    expect(find.text('Crear cuenta gratis'), findsOneWidget);
  });

  testWidgets('navegar a registro por ruta nombrada funciona', (tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    await tester.tap(
      find.textContaining('Crear cuenta gratis', findRichText: true),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RegistroScreen), findsOneWidget);
  });

  testWidgets('el oyente entra a Inicio con barra inferior y navega', (
    tester,
  ) async {
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

    // Arranca en el shell con las cinco pestañas.
    expect(find.byType(OyenteShell), findsOneWidget);
    final barra = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(barra.selectedIndex, 0);
    expect(barra.destinations.length, 5);
    expect(find.text('Hola, Ana'), findsOneWidget);

    // Tocar "Donar" en la barra (índice 1) muestra la pantalla de donación.
    await tester.tap(find.text('Donar'));
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('Donar al artista'), findsOneWidget);

    // Tocar "Buscar" (índice 2) cambia la pestaña activa.
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  testWidgets(
    'el avatar de perfil abre el desplegable (Perfil/Configuración/Cerrar sesión)',
    (tester) async {
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

      // Abrir el desplegable tocando el círculo del perfil.
      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // "Perfil" abre la pantalla de perfil del oyente.
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaPerfilOyente), findsOneWidget);
      expect(find.text('ana@example.com'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // "Cerrar sesión" vuelve a la pantalla de acceso.
      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(authViewModel.estaLogueado, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
