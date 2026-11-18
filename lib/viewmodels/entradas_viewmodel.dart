import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

class EntradasViewModel extends ChangeNotifier {
  final List<Entrada> _entradasCompradas = List.of(entradas);
  final List<Concierto> _conciertosDisponibles = List.of(conciertos);

  // Vistas de solo lectura: las altas/bajas pasan por [publicarConcierto] y
  // [comprar].
  List<Entrada> get entradasCompradas => List.unmodifiable(_entradasCompradas);
  List<Concierto> get conciertosDisponibles =>
      List.unmodifiable(_conciertosDisponibles);

  // El artista publica un concierto: aparece en "Comprar entrada" del oyente.
  void publicarConcierto({
    required String nombre,
    required String lugar,
    required DateTime fecha,
    required double precio,
    required int disponibles,
  }) {
    _conciertosDisponibles.add(
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
    final posicion = _conciertosDisponibles.indexOf(concierto);
    if (posicion < 0) return false;
    _entradasCompradas.add(
      Entrada(
        concierto: concierto.nombre,
        lugar: concierto.lugar,
        fecha: concierto.fecha,
        precio: concierto.precio,
        cantidad: cantidad,
      ),
    );
    // El concierto es inmutable: se reemplaza por una copia actualizada.
    _conciertosDisponibles[posicion] = concierto.conDisponibles(
      concierto.disponibles - cantidad,
    );
    ventasViewModel.registrarVenta(
      '${concierto.nombre} x$cantidad',
      concierto.precio * cantidad,
    );
    notifyListeners();
    return true;
  }
}

final EntradasViewModel entradasViewModel = EntradasViewModel();
