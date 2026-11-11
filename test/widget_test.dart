import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
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

  testWidgets('entrar como invitado marca el rol invitado', (tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    await tester.tap(find.text('Entrar como invitado'));
    await tester.pump();
    // avanza el "login" simulado del AuthService
    await tester.pump(const Duration(milliseconds: 500));
    expect(authViewModel.esInvitado, isTrue);
    expect(authViewModel.esRegistrado, isFalse);
  });
}
