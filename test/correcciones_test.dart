// Pruebas de las correcciones de la auditoría.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/main.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

void main() {
  test('los géneros de las canciones existen en la lista de géneros', () {
    for (final c in canciones) {
      expect(generos, contains(c.genero), reason: c.titulo);
    }
  });

  test('formatos', () {
    expect(formatearMiles(48302), '48.302');
    expect(formatearPrecio(15000), '\$15.000');
    expect(etiquetaCanciones(1), '1 canción');
    expect(etiquetaCanciones(2), '2 canciones');
  });

  test('detener corta la reproducción', () {
    reproductor.reproducir(0);
    expect(reproductor.hayCancion, isTrue);
    reproductor.detener();
    expect(reproductor.hayCancion, isFalse);
    expect(reproductor.reproduciendo, isFalse);
  });

  testWidgets('login reemplaza la pantalla y logout limpia el historial', (
    tester,
  ) async {
    await tester.pumpWidget(const MiApp());

    await tester.enterText(find.byType(TextFormField).first, 'ana@mail.com');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    // El login ya no queda debajo: no se puede volver atrás.
    expect(navegadorKey.currentState!.canPop(), isFalse);
    expect(find.textContaining(', ana'), findsOneWidget);

    // Pone música y entra a una pantalla anidada antes de cerrar sesión.
    reproductor.reproducir(0);
    await tester.tap(find.byTooltip('Conciertos y entradas'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresá para continuar'), findsOneWidget);
    expect(navegadorKey.currentState!.canPop(), isFalse);
    expect(authViewModel.estaLogueado, isFalse);
    expect(reproductor.hayCancion, isFalse);
  });

  testWidgets('buscar "senal" encuentra "Sin Señal"', (tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.enterText(find.byType(TextFormField).first, 'x@y.com');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'senal');
    await tester.pumpAndSettle();

    expect(find.text('Sin Señal'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
