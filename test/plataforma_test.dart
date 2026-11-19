import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/configuracion_screen.dart';

// Capacidades/Políticas de la app y switch de notificaciones en la pantalla
// de configuración: hoy no hay ningún mecanismo de notificaciones, así que
// el switch debe verse apagado, deshabilitado y con el aviso de políticas.
void main() {
  group('Capacidades', () {
    test('notificacionesDisponibles devuelve false (sin mecanismo)', () {
      expect(Capacidades().notificacionesDisponibles, isFalse);
    });
  });

  group('Politicas', () {
    test('avisoNotificacionesNoDisponibles no está vacío', () {
      expect(Politicas().avisoNotificacionesNoDisponibles, isNotEmpty);
    });
  });

  group('ConfiguracionViewModel', () {
    test('notificaciones parte en false y reproduccionAutomatica en true', () {
      final vm = ConfiguracionViewModel();
      expect(vm.notificaciones, isFalse);
      expect(vm.reproduccionAutomatica, isTrue);
    });

    test('setNotificaciones(true) actualiza el getter y notifica una vez', () {
      final vm = ConfiguracionViewModel();
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);
      vm.setNotificaciones(true);
      expect(vm.notificaciones, isTrue);
      expect(notificaciones, 1);
    });
  });

  testWidgets(
    'el switch de notificaciones aparece apagado, deshabilitado y con aviso',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PantallaConfiguracion()));
      await tester.pumpAndSettle();

      // La pantalla tiene tres switches; el de notificaciones es el del
      // título 'Notificaciones'.
      expect(find.byType(SwitchListTile), findsNWidgets(3));
      final tile = find.ancestor(
        of: find.text('Notificaciones'),
        matching: find.byType(SwitchListTile),
      );
      expect(tile, findsOneWidget);

      final tileWidget = tester.widget<SwitchListTile>(tile);
      expect(tileWidget.value, isFalse); // apagado
      expect(tileWidget.onChanged, isNull); // deshabilitado

      // El subtítulo muestra el aviso de políticas.
      expect(
        find.text(Politicas().avisoNotificacionesNoDisponibles),
        findsOneWidget,
      );
    },
  );
}
