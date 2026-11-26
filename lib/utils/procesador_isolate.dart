import 'dart:isolate';

import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

/// Umbral de uso: recién conviene mandar el cómputo a un isolate aparte
/// cuando el lote es grande (más de [umbralIsolate] elementos) o cuando la
/// operación tarda más de un frame (~16 ms) y trabaría la UI. Abajo de eso,
/// llamar directo a la función es más barato que crear el isolate.
const int umbralIsolate = 200;

/// Ejecuta [tarea] en un isolate aparte y devuelve su resultado.
///
/// La tarea corre en otro hilo: no toca la UI y no bloquea el frame.
/// Ojo: solo se pueden mandar datos "sendable" (objetos planos como los
/// modelos de lib/models); no se pueden capturar servicios con estado.
Future<T> computarEnIsolate<T>(T Function() tarea) => Isolate.run(tarea);

/// Resumen agregado (cómputo CPU) de un lote de movimientos del artista:
/// cantidades y montos por tipo. Es una operación pura sobre datos planos,
/// así que se puede mandar sin problemas a un isolate.
Map<String, Object> resumenMovimientos(List<Movimiento> movimientos) {
  var montoVentas = 0.0;
  var montoDonaciones = 0.0;
  var cantidadVentas = 0;
  var cantidadDonaciones = 0;
  for (final movimiento in movimientos) {
    if (movimiento.tipo == TipoMovimiento.venta) {
      montoVentas += movimiento.monto;
      cantidadVentas++;
    } else {
      montoDonaciones += movimiento.monto;
      cantidadDonaciones++;
    }
  }
  return <String, Object>{
    'cantidad': movimientos.length,
    'cantidadVentas': cantidadVentas,
    'cantidadDonaciones': cantidadDonaciones,
    'montoVentas': montoVentas,
    'montoDonaciones': montoDonaciones,
    'montoTotal': montoVentas + montoDonaciones,
  };
}

/// Igual que [resumenMovimientos] pero corriendo en un isolate aparte.
/// Usar cuando `movimientos.length >= umbralIsolate`.
Future<Map<String, Object>> resumenMovimientosEnIsolate(
  List<Movimiento> movimientos,
) => computarEnIsolate(() => resumenMovimientos(movimientos));

/// Resumen de métricas ([resumirMetricas]) corriendo en un isolate aparte
/// si hay muchas canciones (>= [umbralIsolate]); si no, directo.
Future<ResumenMetricas> resumirMetricasAdaptativo(
  List<MetricasCancion> metricas,
) => metricas.length >= umbralIsolate
    ? computarEnIsolate(() => resumirMetricas(metricas))
    : Future.value(resumirMetricas(metricas));
