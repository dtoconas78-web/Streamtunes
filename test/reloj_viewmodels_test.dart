import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

// Fechas deterministas de los movimientos económicos vía RelojFijo.
void main() {
  final fechaFija = DateTime(2026, 11, 18, 15, 30);

  test(
    'EntradasViewModel sella el movimiento de la compra con la fecha del reloj',
    () {
      final repoMovimientos = RepositorioMovimientosMemoria(movimientos: []);
      final vm = EntradasViewModel(
        repositorioEntradas: RepositorioEntradasMemoria(
          entradas: [],
          conciertos: [],
        ),
        repositorioMovimientos: repoMovimientos,
        reloj: RelojFijo(fechaFija),
      );

      vm.publicarConcierto(
        nombre: 'Show de prueba',
        lugar: 'Teatro de prueba',
        fecha: DateTime(2027, 1, 1),
        precio: 1000,
        disponibles: 5,
      );
      final ok = vm.comprar(vm.conciertosDisponibles.last, 2);

      expect(ok, isTrue);
      expect(repoMovimientos.movimientos, hasLength(1));
      expect(repoMovimientos.movimientos.single.fecha, fechaFija);
    },
  );

  test('VentasViewModel sella ventas y donaciones con la fecha del reloj', () {
    final repoMovimientos = RepositorioMovimientosMemoria(movimientos: []);
    final vm = VentasViewModel(
      repositorio: repoMovimientos,
      reloj: RelojFijo(fechaFija),
    );

    vm.registrarVenta('Entradas x2', 2000);
    vm.registrarDonacion('Donación de oyente', 500);

    expect(repoMovimientos.movimientos, hasLength(2));
    expect(
      repoMovimientos.movimientos.every((m) => m.fecha == fechaFija),
      isTrue,
    );
  });

  test(
    'el reloj por defecto es el del sistema (compatibilidad de constructores)',
    () {
      final repoMovimientos = RepositorioMovimientosMemoria(movimientos: []);
      // Sin pasar reloj: default RelojDelSistema, no rompe las instanciaciones
      // existentes.
      final vm = VentasViewModel(repositorio: repoMovimientos);
      final antes = DateTime.now();
      vm.registrarVenta('Venta', 100);
      final despues = DateTime.now();

      final fecha = repoMovimientos.movimientos.single.fecha;
      expect(
        fecha.isAfter(antes.subtract(const Duration(seconds: 1))) &&
            fecha.isBefore(despues.add(const Duration(seconds: 1))),
        isTrue,
      );
    },
  );

  test(
    'RelojFijo siempre devuelve la misma fecha y RelojDelSistema la actual',
    () {
      expect(RelojFijo(fechaFija).ahora(), fechaFija);
      expect(RelojFijo(fechaFija).ahora(), fechaFija);
      final ahora = RelojDelSistema().ahora();
      expect(ahora.difference(DateTime.now()).inSeconds.abs() < 2, isTrue);
    },
  );
}
