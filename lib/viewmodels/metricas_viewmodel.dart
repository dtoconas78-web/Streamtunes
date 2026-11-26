import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_metricas.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/utils/procesador_isolate.dart';

/// Estadísticas reales de reproducción para el artista: por canción y el
/// total de su música (reproducciones, ciudades y franjas horarias).
///
/// Escucha el [RepositorioMetricas] y recalcula el resumen del artista en
/// cada cambio; con muchas canciones el cálculo va a un isolate aparte (ver
/// utils/procesador_isolate.dart) para no trabar la UI.
class MetricasViewModel extends ChangeNotifier {
  MetricasViewModel({required this._repositorio}) {
    _repositorio.addListener(_alCambiar);
    _alCambiar();
  }

  final RepositorioMetricas _repositorio;
  ResumenMetricas _resumenArtista = resumirMetricas(const []);
  int _version = 0;
  bool _calculando = false;

  /// true si los datos vienen de Firestore (todos los oyentes).
  bool get esRemoto => _repositorio.esRemoto;

  /// Resumen de toda la música del artista.
  ResumenMetricas get resumenArtista => _resumenArtista;

  bool get calculando => _calculando;

  /// Resumen de una canción (null = todavía no tiene reproducciones).
  ResumenMetricas? resumenDe(String cancionId) {
    final m = _repositorio.de(cancionId);
    return m == null ? null : resumirMetricas([m]);
  }

  void _alCambiar() {
    final version = ++_version;
    _calculando = true;
    notifyListeners();
    unawaited(_recalcular(version));
  }

  Future<void> _recalcular(int version) async {
    try {
      final resumen = await resumirMetricasAdaptativo(
        _repositorio.porCancion.values.toList(),
      );
      if (version != _version) return; // llegó otro cambio: vale el último
      _resumenArtista = resumen;
    } catch (e) {
      debugPrint('No se pudo calcular el resumen de métricas: $e');
    }
    if (version != _version) return;
    _calculando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _repositorio.removeListener(_alCambiar);
    super.dispose();
  }
}
