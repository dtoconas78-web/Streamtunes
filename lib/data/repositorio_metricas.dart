import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';

/// Métricas de reproducción por canción (colección `metricas` en Firestore:
/// un documento por canción, ver [MetricasCancion]).
///
/// Observable, como los demás repositorios. [esRemoto] dice si los datos
/// vienen de Firestore (reales, de todos los oyentes) o están en memoria
/// (demo y tests: solo lo que se escuchó en este celular).
abstract class RepositorioMetricas extends ChangeNotifier {
  Map<String, MetricasCancion> get porCancion;

  /// Métricas de una canción (null = todavía no tiene reproducciones).
  MetricasCancion? de(String cancionId) {
    final m = porCancion[cancionId];
    return m == null || m.vacia ? null : m;
  }

  bool get esRemoto;

  /// Suma [incremento] a las métricas de [cancionId].
  Future<void> sumar(String cancionId, MetricasCancion incremento);
}

/// En memoria (demo / tests).
class RepositorioMetricasMemoria extends RepositorioMetricas {
  final Map<String, MetricasCancion> _metricas = {};

  @override
  Map<String, MetricasCancion> get porCancion => Map.unmodifiable(_metricas);

  @override
  bool get esRemoto => false;

  @override
  Future<void> sumar(String cancionId, MetricasCancion incremento) async {
    _metricas[cancionId] = (_metricas[cancionId] ?? const MetricasCancion())
        .sumar(incremento);
    notifyListeners();
  }
}

/// En Cloud Firestore: lee la colección `metricas` en tiempo real y suma
/// con incrementos atómicos (si la fuente es [IncrementadorFirestore]).
class RepositorioMetricasFirestore extends RepositorioMetricas {
  RepositorioMetricasFirestore({required this._fuente}) {
    _suscripcion = _fuente
        .snapshotsColeccion(coleccionMetricas)
        .listen(_alCambiar, onError: _alError);
  }

  static const String coleccionMetricas = 'metricas';

  final FuenteFirestore _fuente;
  StreamSubscription<List<DocumentoFirestore>>? _suscripcion;
  Map<String, MetricasCancion> _metricas = {};

  /// Último error del stream (se conservan los últimos datos válidos).
  Object? ultimoError;

  @override
  Map<String, MetricasCancion> get porCancion => Map.unmodifiable(_metricas);

  @override
  bool get esRemoto => true;

  void _alCambiar(List<DocumentoFirestore> docs) {
    final nuevas = {
      for (final d in docs) d.id: MetricasCancion.fromMap(d.datos),
    };
    if (mapEquals(nuevas, _metricas)) return;
    _metricas = nuevas;
    notifyListeners();
  }

  void _alError(Object e) {
    ultimoError = e;
    debugPrint('RepositorioMetricasFirestore: error de stream: $e');
  }

  @override
  Future<void> sumar(String cancionId, MetricasCancion incremento) {
    final fuente = _fuente;
    if (fuente is! IncrementadorFirestore) {
      throw UnsupportedError('La fuente no sabe sumar contadores');
    }
    return (fuente as IncrementadorFirestore).incrementar(
      coleccionMetricas,
      cancionId,
      incremento.toMap(),
    );
  }

  Future<void> cerrar() async {
    await _suscripcion?.cancel();
    _suscripcion = null;
  }

  @override
  void dispose() {
    unawaited(cerrar());
    super.dispose();
  }
}
