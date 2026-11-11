// Prueba básica: la app arranca y muestra la pantalla de login.

import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/main.dart';

void main() {
  testWidgets('La app arranca en el login', (WidgetTester tester) async {
    await tester.pumpWidget(const MiApp());

    expect(find.text('StreamTunes'), findsOneWidget);
    expect(find.text('Ingresá para continuar'), findsOneWidget);
  });
}
