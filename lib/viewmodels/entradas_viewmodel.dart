import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

class EntradasViewModel extends ChangeNotifier {
  final List<Entrada> entradasCompradas = List.of(entradas);
  final List<Concierto> conciertosDisponibles = List.of(conciertos);

  bool comprar(Concierto concierto, int cantidad) {
    if (cantidad <= 0 || cantidad > concierto.disponibles) {
      return false;
    }
    entradasCompradas.add(
      Entrada(
        concierto: concierto.nombre,
        lugar: concierto.lugar,
        fecha: concierto.fecha,
        precio: concierto.precio,
        cantidad: cantidad,
      ),
    );
    concierto.disponibles -= cantidad;
    ventasViewModel.registrarVenta(
      '${concierto.nombre} x$cantidad',
      concierto.precio * cantidad,
    );
    notifyListeners();
    return true;
  }
}

final EntradasViewModel entradasViewModel = EntradasViewModel();
