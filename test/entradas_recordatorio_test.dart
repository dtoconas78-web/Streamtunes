import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';

import 'dobles_notificaciones.dart';

void main() {
  group('recordatorio al comprar una entrada', () {
    late RecordatoriosFalsos recordatorios;
    late bool activos;

    EntradasViewModel crearVm() => EntradasViewModel(
      repositorioEntradas: RepositorioEntradasMemoria(),
      repositorioMovimientos: RepositorioMovimientosMemoria(),
      recordatorios: recordatorios,
      recordatoriosActivos: () => activos,
    );

    setUp(() {
      recordatorios = RecordatoriosFalsos();
      activos = true;
    });

    test('compra exitosa con recordatorios activos: se programa', () async {
      final vm = crearVm();
      final concierto = vm.conciertosDisponibles.first;

      expect(await vm.comprarAsync(concierto, 1), isTrue);
      await Future<void>.delayed(Duration.zero); // se programa con unawaited

      expect(recordatorios.programados.map((c) => c.nombre), [
        concierto.nombre,
      ]);
    });

    test('con recordatorios desactivados no se programa', () async {
      activos = false;
      final vm = crearVm();

      expect(await vm.comprarAsync(vm.conciertosDisponibles.first, 1), isTrue);
      await Future<void>.delayed(Duration.zero);

      expect(recordatorios.programados, isEmpty);
    });

    test('compra fallida (sin stock) no programa nada', () async {
      final vm = crearVm();
      final agotado = vm.conciertosDisponibles.firstWhere(
        (c) => c.disponibles == 0,
      );

      expect(await vm.comprarAsync(agotado, 1), isFalse);
      await Future<void>.delayed(Duration.zero);

      expect(recordatorios.programados, isEmpty);
    });

    test('sin servicio inyectado la compra funciona igual', () async {
      final vm = EntradasViewModel(
        repositorioEntradas: RepositorioEntradasMemoria(),
        repositorioMovimientos: RepositorioMovimientosMemoria(),
      );
      expect(await vm.comprarAsync(vm.conciertosDisponibles.first, 1), isTrue);
    });
  });

  group('momentoRecordatorio', () {
    final concierto = DateTime(2027, 3, 20, 21);

    test('es el día anterior a las 10', () {
      expect(
        momentoRecordatorio(concierto, DateTime(2027, 3, 1)),
        DateTime(2027, 3, 19, horaRecordatorio),
      );
    });

    test('si ese momento ya pasó devuelve null', () {
      expect(momentoRecordatorio(concierto, DateTime(2027, 3, 19, 11)), isNull);
      expect(momentoRecordatorio(concierto, DateTime(2027, 4, 1)), isNull);
    });

    test('cruza bien el cambio de mes', () {
      expect(
        momentoRecordatorio(DateTime(2027, 4, 1), DateTime(2027, 1, 1)),
        DateTime(2027, 3, 31, horaRecordatorio),
      );
    });
  });

  test('idRecordatorio es estable y no choca con los ids fijos', () {
    final a = Concierto(
      id: 'concierto-1',
      nombre: 'A',
      lugar: 'L',
      fecha: DateTime(2027),
      precio: 1,
      disponibles: 1,
    );
    final sinId = Concierto(
      nombre: 'B',
      lugar: 'L',
      fecha: DateTime(2027),
      precio: 1,
      disponibles: 1,
    );
    expect(idRecordatorio(a), idRecordatorio(a));
    expect(idRecordatorio(a), isNot(idRecordatorio(sinId)));
    expect(idRecordatorio(a), greaterThanOrEqualTo(1000));
    expect(idRecordatorio(sinId), greaterThanOrEqualTo(1000));
  });
}
