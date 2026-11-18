import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/movimiento.dart';

/// Contrato del repositorio de movimientos económicos del artista (ventas de
/// entradas y donaciones).
///
/// A diferencia de los otros repositorios, este ES observable: se escribe
/// desde más de un lugar (comprar entrada y donar), así que anuncia sus
/// cambios para que los interesados (p. ej. VentasViewModel) los reemitan.
///
/// La implementación de demo es en memoria (semilla: datos_ejemplo.dart).
abstract class RepositorioMovimientos extends ChangeNotifier {
  /// Movimientos de solo lectura.
  List<Movimiento> get movimientos;

  void registrar(Movimiento movimiento);
}

/// Implementación en memoria: arranca con los datos de ejemplo y notifica
/// cada movimiento nuevo.
class RepositorioMovimientosMemoria extends RepositorioMovimientos {
  RepositorioMovimientosMemoria({List<Movimiento>? movimientos})
    : _movimientos = List.of(movimientos ?? datos.movimientos);

  final List<Movimiento> _movimientos;

  @override
  List<Movimiento> get movimientos => List.unmodifiable(_movimientos);

  @override
  void registrar(Movimiento movimiento) {
    _movimientos.add(movimiento);
    notifyListeners();
  }
}
