import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';

// Una hoja inferior o un diálogo no son pantallas: ocultan el
// mini-reproductor mientras están abiertos y no "cierran" el reproductor
// grande cuando se abren desde él.
void main() {
  Future<void> montar(WidgetTester tester) async {
    reproductor.marcarPantallaCompleta(false);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navegadorKey,
        navigatorObservers: [ObservadorReproductor()],
        home: const Scaffold(body: Text('home')),
      ),
    );
  }

  BuildContext contexto() => navegadorKey.currentContext!;

  testWidgets('la hoja inferior marca un modal abierto mientras está', (
    tester,
  ) async {
    await montar(tester);
    expect(estadoNavegacion.hayModalAbierto, isFalse);

    unawaited(
      showModalBottomSheet<void>(
        context: contexto(),
        builder: (_) => const Text('hoja'),
      ),
    );
    await tester.pumpAndSettle();
    expect(estadoNavegacion.hayModalAbierto, isTrue);

    navegadorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(estadoNavegacion.hayModalAbierto, isFalse);
  });

  testWidgets('los diálogos también cuentan como modal', (tester) async {
    await montar(tester);
    unawaited(
      showDialog<void>(
        context: contexto(),
        builder: (_) => const AlertDialog(content: Text('diálogo')),
      ),
    );
    await tester.pumpAndSettle();
    expect(estadoNavegacion.hayModalAbierto, isTrue);

    navegadorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(estadoNavegacion.hayModalAbierto, isFalse);
  });

  testWidgets('una hoja abierta desde el reproductor grande no lo da por '
      'cerrado', (tester) async {
    await montar(tester);
    navegadorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/reproductor'),
        builder: (_) => const Scaffold(body: Text('reproductor')),
      ),
    );
    await tester.pumpAndSettle();
    expect(reproductor.pantallaCompletaAbierta, isTrue);

    unawaited(
      showModalBottomSheet<void>(
        context: contexto(),
        builder: (_) => const Text('donar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(reproductor.pantallaCompletaAbierta, isTrue);
    expect(estadoNavegacion.hayModalAbierto, isTrue);

    navegadorKey.currentState!.pop(); // cierra la hoja
    await tester.pumpAndSettle();
    expect(reproductor.pantallaCompletaAbierta, isTrue);
    expect(estadoNavegacion.hayModalAbierto, isFalse);

    navegadorKey.currentState!.pop(); // cierra el reproductor
    await tester.pumpAndSettle();
    expect(reproductor.pantallaCompletaAbierta, isFalse);
  });
}
