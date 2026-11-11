import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/movimiento.dart';

class VentasViewModel extends ChangeNotifier {
  final List<Movimiento> movimientos = List.of(datos.movimientos);
  double get totalVentas {
    double total = 0;
    for (final m in movimientos) {
      if (m.tipo == TipoMovimiento.venta) {
        total += m.monto;
      }
    }
    return total;
  }

  double get totalDonaciones {
    double total = 0;
    for (final m in movimientos) {
      if (m.tipo == TipoMovimiento.donacion) {
        total += m.monto;
      }
    }
    return total;
  }

  void registrarVenta(String detalle, double monto) {
    movimientos.add(
      Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: detalle,
        monto: monto,
        fecha: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void registrarDonacion(String detalle, double monto) {
    movimientos.add(
      Movimiento(
        tipo: TipoMovimiento.donacion,
        detalle: detalle,
        monto: monto,
        fecha: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}

final VentasViewModel ventasViewModel = VentasViewModel();
