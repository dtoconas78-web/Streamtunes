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
  });
}
