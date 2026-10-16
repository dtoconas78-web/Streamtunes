import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/main.dart';

void main() {
  testWidgets('Perfil: se puede seguir al artista', (tester) async {
    await tester.pumpWidget(const MiApp());

    expect(find.text('Mateo Cabral'), findsOneWidget);
    expect(find.text('Seguir'), findsOneWidget);

    await tester.tap(find.text('Seguir'));
    await tester.pump();

    expect(find.text('Siguiendo'), findsOneWidget);
  });
}
