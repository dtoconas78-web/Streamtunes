import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/utils/comision.dart';
import 'package:streamtunes_demo/utils/reloj.dart';

// Ventas y donaciones del artista. Los movimientos viven en el
// [RepositorioMovimientos] inyectado, que es observable: este VM se suscribe
// UNA SOLA VEZ en el constructor y reemite los cambios, así que una compra
// hecha desde otro VM (EntradasViewModel) también se refleja acá sin que los
// VMs se conozcan entre sí.
class VentasViewModel extends ChangeNotifier {
  VentasViewModel({
    required this._repositorio,
    this._reloj = const RelojDelSistema(),
  }) {
    _repositorio.addListener(notifyListeners);
  }

  final RepositorioMovimientos _repositorio;
  // Reloj para sellar la fecha de los movimientos económicos (lógica de
  // negocio): en tests se inyecta un RelojFijo para fechas deterministas.
  final Reloj _reloj;

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

  /// Comisión de StreamTunes sobre las ventas de entradas (las donaciones
  /// no tienen).
  double get totalComisiones {
    double total = 0;
    for (final m in _repositorio.movimientos) {
      if (m.tipo == TipoMovimiento.venta) total += m.comision;
    }
    return total;
  }

  /// Lo que recibe el artista por entradas: [totalVentas] (lo que pagaron
  /// los fans) menos [totalComisiones].
  double get netoVentas => totalVentas - totalComisiones;

  void registrarVenta(String detalle, double monto) {
    // No se notifica acá: el repo ya notificó y este VM reemite por la
    // suscripción (una sola notificación por movimiento).
    _repositorio.registrar(
      Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: detalle,
        monto: monto,
        comision: comisionDe(monto),
        fecha: _reloj.ahora(),
      ),
    );
  }

  /// Registra una donación. [donante] es el nombre que el fan elige mostrar
  /// ('' = anónima); [artistaId] es quien la recibe.
  void registrarDonacion(
    String detalle,
    double monto, {
    String donante = '',
    String artistaId = '',
  }) {
    _repositorio.registrar(
      Movimiento(
        tipo: TipoMovimiento.donacion,
        detalle: detalle,
        monto: monto,
        fecha: _reloj.ahora(),
        donante: donante.trim(),
        artistaId: artistaId,
      ),
    );
  }

  /// "Quién te banca": donantes agrupados por nombre, de mayor a menor
  /// total. Todas las donaciones anónimas van juntas en una sola fila
  /// (con [Bancador.anonimo] en true).
  List<Bancador> get quienesTeBancan {
    final porNombre = <String, Bancador>{};
    for (final m in _repositorio.movimientos) {
      if (m.tipo != TipoMovimiento.donacion) continue;
      final previo = porNombre[m.donante];
      porNombre[m.donante] = Bancador(
        nombre: m.donante,
        total: (previo?.total ?? 0) + m.monto,
        cantidad: (previo?.cantidad ?? 0) + 1,
      );
    }
    return porNombre.values.toList()..sort((a, b) {
      final porTotal = b.total.compareTo(a.total);
      return porTotal != 0 ? porTotal : a.nombre.compareTo(b.nombre);
    });
  }

  @override
  void dispose() {
    _repositorio.removeListener(notifyListeners);
    super.dispose();
  }
}

/// Un fan que apoya al artista (o todos los anónimos juntos).
class Bancador {
  const Bancador({
    required this.nombre,
    required this.total,
    required this.cantidad,
  });

  /// '' = donaciones anónimas.
  final String nombre;
  final double total;
  final int cantidad;

  bool get anonimo => nombre.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Bancador &&
      other.nombre == nombre &&
      other.total == total &&
      other.cantidad == cantidad;

  @override
  int get hashCode => Object.hash(nombre, total, cantidad);

  @override
  String toString() => 'Bancador($nombre, $total, $cantidad)';
}
