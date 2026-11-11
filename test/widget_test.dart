import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/explorar_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';

void main() {
  setUp(() => authViewModel.logout());

  testWidgets('sin sesión la app muestra la pantalla de acceso',
      (WidgetTester tester) async {
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
}
