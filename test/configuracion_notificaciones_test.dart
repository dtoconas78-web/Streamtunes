import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/configuracion_screen.dart';

import 'dobles_notificaciones.dart';
import 'dobles_persistencia.dart';

void main() {
  late RecordatoriosFalsos recordatorios;
  late TareasFalsas tareas;
  late RepositorioConfiguracionMemoria repo;

  ConfiguracionViewModel crearVm() => ConfiguracionViewModel(
    repositorio: repo,
    recordatorios: recordatorios,
    tareas: tareas,
  );

  setUp(() {
    recordatorios = RecordatoriosFalsos();
    tareas = TareasFalsas();
    repo = RepositorioConfiguracionMemoria();
  });

  group('ConfiguracionViewModel.cambiarNotificaciones', () {
    test('activar con permiso concedido registra la tarea y guarda', () async {
      final vm = crearVm();
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      await vm.cambiarNotificaciones(true);

      expect(vm.notificaciones, isTrue);
      expect(recordatorios.pedidosDePermiso, 1);
      expect(tareas.registrada, isTrue);
      expect(repo.notificaciones, isTrue);
      expect(vm.permisoDenegado, isFalse);
      expect(vm.ultimoError, isNull);
      expect(vm.cargando, isFalse);
      expect(notificaciones, 2); // empieza a cargar + termina
    });

    test(
      'permiso rechazado: queda desactivada, sin tarea ni guardado',
      () async {
        recordatorios.concederPermiso = false;
        final vm = crearVm();

        await vm.cambiarNotificaciones(true);

        expect(vm.notificaciones, isFalse);
        expect(vm.permisoDenegado, isTrue);
        expect(tareas.registros, 0);
        expect(repo.notificaciones, isFalse);
        expect(vm.cargando, isFalse);
      },
    );

    test('desactivar cancela la tarea y los recordatorios', () async {
      final vm = crearVm();
      await vm.cambiarNotificaciones(true);

      await vm.cambiarNotificaciones(false);

      expect(vm.notificaciones, isFalse);
      expect(tareas.registrada, isFalse);
      expect(recordatorios.cancelaciones, 1);
      expect(repo.notificaciones, isFalse);
    });

    test('si falla registrar la tarea, no cambia y guarda el error', () async {
      tareas.errorAlRegistrar = StateError('workmanager caído');
      final vm = crearVm();

      await vm.cambiarNotificaciones(true);

      expect(vm.notificaciones, isFalse);
      expect(vm.ultimoError, isA<StateError>());
      expect(repo.notificaciones, isFalse);
      expect(vm.cargando, isFalse);
    });

    test('guard: no se piden dos permisos a la vez', () async {
      recordatorios.permisoPendiente = Completer<bool>();
      final vm = crearVm();

      final primero = vm.cambiarNotificaciones(true);
      expect(vm.cargando, isTrue);
      await vm.cambiarNotificaciones(true); // ignorado mientras carga
      expect(recordatorios.pedidosDePermiso, 1);

      recordatorios.permisoPendiente!.complete(true);
      await primero;
      expect(vm.notificaciones, isTrue);
    });

    test('pedir el mismo estado que ya tiene no hace nada', () async {
      final vm = crearVm();
      await vm.cambiarNotificaciones(false);
      expect(recordatorios.pedidosDePermiso, 0);
      expect(tareas.cancelaciones, 0);
    });

    test('arranca con la preferencia guardada en el celular', () async {
      final prefs = preferenciasEnMemoria({claveNotificacionesActivas: true});
      final repositorio = RepositorioConfiguracionPreferencias(prefs: prefs);
      await repositorio.cargar(); // como main() antes de crear el VM
      final vm = ConfiguracionViewModel(repositorio: repositorio);
      expect(vm.notificaciones, isTrue);

      // Y desactivar se guarda.
      await vm.cambiarNotificaciones(false);
      expect(await prefs.getBool(claveNotificacionesActivas), isFalse);
    });
  });

  group('Capacidades', () {
    test('por defecto todo está desactivado', () {
      const c = Capacidades();
      expect(c.notificacionesProgramadas, isFalse);
      expect(c.tareasSegundoPlano, isFalse);
    });
  });

  group('PantallaConfiguracion con notificaciones disponibles', () {
    const capacidades = Capacidades(
      notificacionesDisponibles: true,
      notificacionesProgramadas: true,
      tareasSegundoPlano: true,
    );

    Finder switchNotificaciones() => find.ancestor(
      of: find.text('Notificaciones'),
      matching: find.byType(SwitchListTile),
    );

    testWidgets('tocar el switch pide permiso y lo activa', (tester) async {
      final vm = crearVm();
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaConfiguracion(viewModel: vm, capacidades: capacidades),
        ),
      );
      expect(
        tester.widget<SwitchListTile>(switchNotificaciones()).onChanged,
        isNotNull,
      );

      await tester.tap(switchNotificaciones());
      await tester.pumpAndSettle();

      expect(recordatorios.pedidosDePermiso, 1);
      expect(
        tester.widget<SwitchListTile>(switchNotificaciones()).value,
        isTrue,
      );
    });

    testWidgets('con permiso rechazado muestra el aviso y queda apagado', (
      tester,
    ) async {
      recordatorios.concederPermiso = false;
      final vm = crearVm();
      await tester.pumpWidget(
        MaterialApp(
          home: PantallaConfiguracion(viewModel: vm, capacidades: capacidades),
        ),
      );

      await tester.tap(switchNotificaciones());
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(switchNotificaciones()).value,
        isFalse,
      );
      expect(
        find.text(Politicas().avisoPermisoNotificacionesDenegado),
        findsOneWidget,
      );
    });
  });
}
