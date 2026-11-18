import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';

/// Contrato del repositorio de entradas: conciertos publicados por el
/// artista y entradas compradas por el oyente.
///
/// La implementación de demo es en memoria (semilla: datos_ejemplo.dart).
abstract class RepositorioEntradas {
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
}

/// Implementación en memoria: arranca con los datos de ejemplo.
class RepositorioEntradasMemoria implements RepositorioEntradas {
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
  void agregarConcierto(Concierto concierto) =>
      _conciertosDisponibles.add(concierto);

  @override
  void agregarEntrada(Entrada entrada) => _entradasCompradas.add(entrada);

  @override
  bool descontarDisponibles(Concierto concierto, int cantidad) {
    // Cantidad inválida: no se toca el estado.
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
    return true;
  }
}
