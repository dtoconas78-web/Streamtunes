import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/utils/comision.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

void main() {
  final fecha = DateTime(2026, 11, 26, 20);

  group('comisionDe', () {
    test('es el 30% de lo que paga el fan', () {
      expect(comisionEntradas, 0.30);
      expect(comisionDe(15000), 4500);
      expect(comisionDe(0), 0);
      expect(porcentajeComision, '30%');
    });

    test('redondea a centavos', () {
      expect(comisionDe(333.33), 100); // 99.999 -> 100.00
      expect(comisionDe(10.01), 3); // 3.003 -> 3.00
    });
  });

  group('Movimiento', () {
    test('neto = monto - comisión', () {
      final m = Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: 'Show x2',
        monto: 2000,
        comision: 600,
        fecha: fecha,
      );
      expect(m.neto, 1400);
    });

    test('ida y vuelta toMap/fromMap conserva la comisión', () {
      final m = Movimiento(
        id: 'm1',
        tipo: TipoMovimiento.venta,
        detalle: 'Show',
        monto: 1000,
        comision: 300,
        fecha: fecha,
        usuarioId: 'u1',
      );
      expect(Movimiento.fromMap(m.toMap(), id: 'm1'), m);
    });

    test('un documento viejo sin comisión se lee con comisión 0', () {
      final m = Movimiento.fromMap({
        'tipo': 'venta',
        'detalle': 'Show viejo',
        'monto': 1000,
        'fecha': Timestamp.fromDate(fecha),
      }, id: 'viejo');
      expect(m.comision, 0);
      expect(m.neto, 1000);
    });

    test('una comisión que no es número es un error de formato', () {
      expect(
        () => Movimiento.fromMap({
          'tipo': 'venta',
          'detalle': 'x',
          'monto': 1000,
          'fecha': fecha,
          'comision': 'mucho',
        }),
        throwsFormatException,
      );
    });
  });

  group('ViewModels', () {
    test('al comprar una entrada la venta registra el 30% de comisión', () {
      final movimientos = RepositorioMovimientosMemoria(movimientos: []);
      final entradas = EntradasViewModel(
        repositorioEntradas: RepositorioEntradasMemoria(
          entradas: [],
          conciertos: [],
        ),
        repositorioMovimientos: movimientos,
        reloj: RelojFijo(fecha),
      );
      entradas.publicarConcierto(
        nombre: 'Show',
        lugar: 'Teatro',
        fecha: DateTime(2027, 1, 1),
        precio: 15000,
        disponibles: 10,
      );

      expect(entradas.comprar(entradas.conciertosDisponibles.last, 2), isTrue);

      final venta = movimientos.movimientos.single;
      expect(venta.monto, 30000); // el fan paga el precio publicado
      expect(venta.comision, 9000);
      expect(venta.neto, 21000);
    });

    test('totales: bruto, comisiones y neto; donaciones sin comisión', () {
      final vm = VentasViewModel(
        repositorio: RepositorioMovimientosMemoria(movimientos: []),
        reloj: RelojFijo(fecha),
      );
      vm.registrarVenta('Show A', 10000);
      vm.registrarVenta('Show B', 5000);
      vm.registrarDonacion('Donación', 2000);

      expect(vm.totalVentas, 15000);
      expect(vm.totalComisiones, 4500);
      expect(vm.netoVentas, 10500);
      expect(vm.totalDonaciones, 2000);
      expect(
        vm.movimientos
            .where((m) => m.tipo == TipoMovimiento.donacion)
            .single
            .comision,
        0,
      );
    });
  });

  test('las políticas explican la comisión al artista y al fan', () {
    final p = Politicas();
    expect(p.textoComisionArtista, contains('30%'));
    expect(p.textoComisionFan, contains('30%'));
    expect(p.textoComisionFan, contains('sin cargos extra'));
  });
}
