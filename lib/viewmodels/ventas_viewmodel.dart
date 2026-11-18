import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

// Ventas y donaciones del artista. Los movimientos viven en el
// [RepositorioMovimientos] inyectado, que es observable: este VM se suscribe
// UNA SOLA VEZ en el constructor y reemite los cambios, así que una compra
// hecha desde otro VM (EntradasViewModel) también se refleja acá sin que los
// VMs se conozcan entre sí.
class VentasViewModel extends ChangeNotifier {
  VentasViewModel({required this._repositorio}) {
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioMovimientos _repositorio;

  // Vista de solo lectura: los movimientos se agregan con [registrarVenta] /
  // [registrarDonacion] (o desde otros VMs vía el repo, que notifica).
  List<Movimiento> get movimientos => _repositorio.movimientos;
  double get totalVentas {
    double total = 0;
    for (final m in _repositorio.movimientos) {
      if (m.tipo == TipoMovimiento.venta) {
        total += m.monto;
      }
    }
    return total;
  }

  double get totalDonaciones {
    double total = 0;
    for (final m in _repositorio.movimientos) {
      if (m.tipo == TipoMovimiento.donacion) {
        total += m.monto;
      }
    }
    return total;
  }

  void registrarVenta(String detalle, double monto) {
    // No se notifica acá: el repo ya notificó y este VM reemite por la
    // suscripción (una sola notificación por movimiento).
    _repositorio.registrar(
      Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: detalle,
        monto: monto,
        fecha: DateTime.now(),
      ),
    );
  }

  void registrarDonacion(String detalle, double monto) {
    _repositorio.registrar(
      Movimiento(
        tipo: TipoMovimiento.donacion,
        detalle: detalle,
        monto: monto,
        fecha: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}
