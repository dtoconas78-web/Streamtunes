import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

/// Contrato del repositorio de entradas: conciertos publicados por el
/// artista y entradas compradas por el oyente.
///
/// Es observable (ChangeNotifier): altas y descuentos notifican a los
/// listeners, y con backend también los cambios remotos (snapshots).
/// La implementación de demo es en memoria (semilla: datos_ejemplo.dart).
abstract class RepositorioEntradas extends ChangeNotifier {
  List<Entrada> get entradasCompradas;
  List<Concierto> get conciertosDisponibles;

  void agregarConcierto(Concierto concierto);
  void agregarEntrada(Entrada entrada);

  /// Descuenta [cantidad] disponibles de [concierto] y devuelve true.
  ///
  /// El repositorio es la fuente de verdad del stock: la operación se rechaza
  /// (devuelve false, sin modificar el estado interno) si [cantidad] es menor
  /// o igual a cero, si el concierto no está en el repo, o si la cantidad
  /// supera los disponibles de la instancia almacenada (nunca los del objeto
  /// recibido como parámetro). Al descontar, reemplaza el concierto por una
  /// copia inmutable con `conDisponibles()`.
  bool descontarDisponibles(Concierto concierto, int cantidad);

  /// Capacidad declarada del repositorio (NO es detección de tipo concreto):
  /// `true` solo cuando el repo puede ejecutar una compra ATÓMICA real
  /// (Firestore: stock + entrada + movimiento en una sola transacción).
  /// Por defecto `false`: las implementaciones en memoria (y cualquier otra)
  /// conservan su comportamiento sin modificaciones adicionales.
  bool get soportaCompraAtomica => false;

  /// Compra asíncrona. La implementación POR DEFECTO delega al flujo
  /// sincrónico existente (`descontarDisponibles`), sin simular persistencia:
  /// sirve para las implementaciones en memoria. La implementación Firestore
  /// la sobrescribe con la operación transaccional completa: cuando recibe
  /// [entradaGenerada] y [movimientoGenerado], descuenta el stock y crea
  /// ambos documentos dentro de UNA única transacción (si falta alguno, se
  /// rechaza antes de escribir nada). [operacionId] (opcional) hace la
  /// operación idempotente: si los documentos asociados ya existen, no se
  /// repite el descuento.
  Future<bool> descontarDisponiblesAsync(
    String conciertoId,
    int cantidad, {
    Entrada? entradaGenerada,
    Movimiento? movimientoGenerado,
    String? operacionId,
  }) async {
    final concierto = conciertosDisponibles
        .where((c) => c.id == conciertoId)
        .firstOrNull;
    if (concierto == null) return false;
    return descontarDisponibles(concierto, cantidad);
  }
}

/// Implementación en memoria: arranca con los datos de ejemplo.
class RepositorioEntradasMemoria extends RepositorioEntradas {
  RepositorioEntradasMemoria({
    List<Entrada>? entradas,
    List<Concierto>? conciertos,
  }) : _entradasCompradas = List.of(entradas ?? datos.entradas),
       _conciertosDisponibles = List.of(conciertos ?? datos.conciertos);

  final List<Entrada> _entradasCompradas;
  final List<Concierto> _conciertosDisponibles;

  @override
  List<Entrada> get entradasCompradas => List.unmodifiable(_entradasCompradas);

  @override
  List<Concierto> get conciertosDisponibles =>
      List.unmodifiable(_conciertosDisponibles);

  @override
  void agregarConcierto(Concierto concierto) {
    _conciertosDisponibles.add(concierto);
    notifyListeners();
  }

  @override
  void agregarEntrada(Entrada entrada) {
    _entradasCompradas.add(entrada);
    notifyListeners();
  }

  @override
  bool descontarDisponibles(Concierto concierto, int cantidad) {
    // Cantidad inválida: no se toca el estado (ni se notifica).
    if (cantidad <= 0) return false;
    // Búsqueda por instancia (Concierto no tiene id por ahora).
    final posicion = _conciertosDisponibles.indexOf(concierto);
    if (posicion < 0) return false;
    // Fuente de verdad: SIEMPRE la disponibilidad de la instancia almacenada,
    // nunca la del objeto recibido como parámetro.
    final almacenado = _conciertosDisponibles[posicion];
    if (cantidad > almacenado.disponibles) return false;
    // El concierto es inmutable: se reemplaza por una copia actualizada.
    _conciertosDisponibles[posicion] = almacenado.conDisponibles(
      almacenado.disponibles - cantidad,
    );
    notifyListeners();
    return true;
  }
}
