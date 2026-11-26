import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/utils/reloj.dart';

/// Firma del aviso (la implementa ServicioRecordatorios.mostrarDonacionRecibida).
typedef AvisarDonacion = Future<void> Function({
  required double monto,
  required String donante,
});

/// Avisa al ARTISTA con una notificación local cada donación nueva que le
/// llega, mientras la app está abierta (los movimientos llegan por el
/// snapshot de Firestore; sin push ni servidor).
///
/// Qué cuenta como "nueva": una donación dirigida al artista de la sesión
/// ([artistaActual]) con fecha posterior al momento en que empezó esa
/// sesión, y que todavía no se avisó. Así no se anuncian como nuevas las
/// donaciones viejas que llegan con el primer snapshot o al iniciar sesión.
/// Ojo: la fecha la pone el celular del fan; con relojes muy desfasados una
/// donación podría no avisarse (nunca se avisa dos veces).
class AvisoDonaciones {
  AvisoDonaciones({
    required this._repositorio,
    required this._sesion,
    required this._artistaActual,
    required this._activo,
    required this._avisar,
    this._reloj = const RelojDelSistema(),
  });

  final RepositorioMovimientos _repositorio;
  final Listenable _sesion;
  final String? Function() _artistaActual;
  final bool Function() _activo;
  final AvisarDonacion _avisar;
  final Reloj _reloj;

  String? _artista;
  DateTime _desde = DateTime(0);
  final Set<Movimiento> _avisadas = {};
  bool _escuchando = false;

  /// Empieza a escuchar (una sola vez).
  void iniciar() {
    if (_escuchando) return;
    _escuchando = true;
    _alCambiarSesion();
    _sesion.addListener(_alCambiarSesion);
    _repositorio.addListener(_alCambiarMovimientos);
  }

  void detener() {
    if (!_escuchando) return;
    _escuchando = false;
    _sesion.removeListener(_alCambiarSesion);
    _repositorio.removeListener(_alCambiarMovimientos);
  }

  // Nueva sesión de artista (o ninguna): se arranca a contar desde ahora.
  void _alCambiarSesion() {
    final artista = _artistaActual();
    if (artista == _artista) return;
    _artista = artista;
    _desde = _reloj.ahora();
    _avisadas.clear();
  }

  void _alCambiarMovimientos() {
    final artista = _artista;
    if (artista == null || artista.isEmpty) return;
    for (final m in _repositorio.movimientos) {
      if (m.tipo != TipoMovimiento.donacion ||
          m.artistaId != artista ||
          !m.fecha.isAfter(_desde) ||
          !_avisadas.add(m)) {
        continue;
      }
      // Con las notificaciones apagadas se marca como vista igual: no se
      // avisa más tarde al prenderlas.
      if (!_activo()) continue;
      unawaited(
        _avisar(monto: m.monto, donante: m.donante).catchError((Object e) {
          debugPrint('No se pudo avisar la donación recibida: $e');
        }),
      );
    }
  }
}
