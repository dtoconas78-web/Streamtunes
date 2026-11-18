import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

// Entradas del oyente y conciertos disponibles. Los datos viven en los
// repositorios inyectados; al comprar, el movimiento económico se registra
// en el repositorio de movimientos (que es observable), así que VentasViewModel
// se entera sin que estos dos VMs se conozcan.
class EntradasViewModel extends ChangeNotifier {
  EntradasViewModel({
    required this._repositorioEntradas,
    required this._repositorioMovimientos,
  });

  final RepositorioEntradas _repositorioEntradas;
  final RepositorioMovimientos _repositorioMovimientos;

  // Vistas de solo lectura: las altas/bajas pasan por [publicarConcierto] y
  // [comprar].
  List<Entrada> get entradasCompradas => _repositorioEntradas.entradasCompradas;
  List<Concierto> get conciertosDisponibles =>
      _repositorioEntradas.conciertosDisponibles;

  // El artista publica un concierto: aparece en "Comprar entrada" del oyente.
  void publicarConcierto({
    required String nombre,
    required String lugar,
    required DateTime fecha,
    required double precio,
    required int disponibles,
  }) {
    _repositorioEntradas.agregarConcierto(
      Concierto(
        nombre: nombre,
        lugar: lugar,
        fecha: fecha,
        precio: precio,
        disponibles: disponibles,
      ),
    );
    notifyListeners();
  }

  bool comprar(Concierto concierto, int cantidad) {
    if (cantidad <= 0 || cantidad > concierto.disponibles) {
      return false;
    }
    if (!_repositorioEntradas.descontarDisponibles(concierto, cantidad)) {
      return false;
    }
    _repositorioEntradas.agregarEntrada(
      Entrada(
        concierto: concierto.nombre,
        lugar: concierto.lugar,
        fecha: concierto.fecha,
        precio: concierto.precio,
        cantidad: cantidad,
      ),
    );
    // Venta registrada en el repo compartido: VentasViewModel la levanta
    // porque el repo notifica sus cambios.
    _repositorioMovimientos.registrar(
      Movimiento(
        tipo: TipoMovimiento.venta,
        detalle: '${concierto.nombre} x$cantidad',
        monto: concierto.precio * cantidad,
        fecha: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }
}
