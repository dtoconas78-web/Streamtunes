// Tipo de movimiento del artista: lo que entra por entradas o por donaciones.
enum TipoMovimiento {
  venta,
  donacion;

  // Texto para mostrar en la UI (los enums van en código, no en pantalla).
  String get etiqueta => this == venta ? 'Venta' : 'Donación';
}

class Movimiento {
  final TipoMovimiento tipo;
  final String detalle;
  final double monto;
  final DateTime fecha;

  const Movimiento({
    required this.tipo,
    required this.detalle,
    required this.monto,
    required this.fecha,
  });
}
