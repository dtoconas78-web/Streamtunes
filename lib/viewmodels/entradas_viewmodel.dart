import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/utils/reloj.dart';

// Entradas del oyente y conciertos disponibles. Los datos viven en los
// repositorios inyectados; al comprar, el movimiento económico se registra
// en el repositorio de movimientos (que es observable), así que VentasViewModel
// se entera sin que estos dos VMs se conozcan.
//
// Reactividad (Bloque B): este VM se suscribe UNA SOLA VEZ al repositorio de
// entradas y reemite sus cambios, así los snapshots de Firestore (o las altas
// en memoria) llegan a la UI sin notificaciones manuales duplicadas.
//
// Compra: `comprar` (sync) es el flujo completo en memoria. `comprarAsync`
// elige el flujo según la CAPACIDAD declarada por el contrato
// (`soportaCompraAtomica`), nunca según la clase concreta del repositorio:
// - false (memoria): delega en `comprar` (descuenta stock + entrada + movimiento).
// - true (Firestore): una única `descontarDisponiblesAsync` transaccional que
//   descuenta stock y crea entrada y movimiento juntos, asociados al uid.
class EntradasViewModel extends ChangeNotifier {
  EntradasViewModel({
    required this._repositorioEntradas,
    required this._repositorioMovimientos,
    this._reloj = const RelojDelSistema(),
    this.uidActual,
  }) {
    _repositorioEntradas.addListener(notifyListeners);
  }

  final RepositorioEntradas _repositorioEntradas;
  final RepositorioMovimientos _repositorioMovimientos;
  // Reloj para sellar la fecha de los movimientos económicos (lógica de
  // negocio): en tests se inyecta un RelojFijo para fechas deterministas.
  final Reloj _reloj;
  // Proveedor diferido del uid de la sesión válida (null = invitado/sin
  // sesión Firebase). Sólo se usa en el flujo de compra atómica.
  final String? Function()? uidActual;
  int _contadorOperaciones = 0;

  // Vistas de solo lectura: las altas/bajas pasan por [publicarConcierto] y
  // [comprar]/[comprarAsync].
  List<Entrada> get entradasCompradas => _repositorioEntradas.entradasCompradas;
  List<Concierto> get conciertosDisponibles =>
      _repositorioEntradas.conciertosDisponibles;

  // El artista publica un concierto: aparece en "Comprar entrada" del oyente.
  // No se notifica acá: el repo ya notificó y este VM reemite por la suscripción.
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
  }

  // Flujo completo EN MEMORIA (sync): descuenta stock, registra la entrada y
  // el movimiento. Se conserva intacto para demo/tests y como ruta de
  // `comprarAsync` cuando el repo no soporta compra atómica.
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
        conciertoId: concierto.id,
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
        fecha: _reloj.ahora(),
      ),
    );
    return true;
  }

  /// Compra asíncrona. La bifurcación depende SOLO de la capacidad declarada
  /// por el contrato (`soportaCompraAtomica`), no de clases concretas:
  ///
  /// - `false` (memoria): delega en el flujo completo `comprar` (una sola vez;
  ///   no se ejecuta además `descontarDisponiblesAsync`).
  /// - `true` (Firestore): construye la Entrada y el Movimiento asociados al
  ///   uid de la sesión válida y ejecuta UNA ÚNICA operación transaccional
  ///   (`descontarDisponiblesAsync` con `operacionId`); no se llama `comprar`
  ///   ni se registra el movimiento por separado.
  Future<bool> comprarAsync(Concierto concierto, int cantidad) async {
    if (!_repositorioEntradas.soportaCompraAtomica) {
      return comprar(concierto, cantidad);
    }
    if (cantidad <= 0) return false;
    final uid = uidActual?.call();
    if (uid == null || uid.isEmpty) return false; // sin sesión válida
    final entrada = Entrada(
      concierto: concierto.nombre,
      conciertoId: concierto.id,
      lugar: concierto.lugar,
      fecha: concierto.fecha,
      precio: concierto.precio,
      cantidad: cantidad,
      usuarioId: uid,
    );
    final movimiento = Movimiento(
      tipo: TipoMovimiento.venta,
      detalle: '${concierto.nombre} x$cantidad',
      monto: concierto.precio * cantidad,
      fecha: _reloj.ahora(),
      usuarioId: uid,
    );
    // operacionId único por intento de compra: idempotencia ante reintentos.
    final operacionId =
        'op-${_reloj.ahora().millisecondsSinceEpoch}-${++_contadorOperaciones}';
    return _repositorioEntradas.descontarDisponiblesAsync(
      concierto.id,
      cantidad,
      entradaGenerada: entrada,
      movimientoGenerado: movimiento,
      operacionId: operacionId,
    );
  }

  @override
  void dispose() {
    _repositorioEntradas.removeListener(notifyListeners);
    super.dispose();
  }
}
