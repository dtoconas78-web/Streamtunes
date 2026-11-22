import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:streamtunes_demo/services/fuente_conectividad.dart';

/// Servicio reactivo de conectividad (online/offline).
///
/// Expone el estado actual como bool y un stream de CAMBIOS (sin valores
/// repetidos) para que la UI reaccione cuando se va o vuelve la red. La
/// suscripción interna a la fuente se cancela en dispose().
class ServicioConectividad extends ChangeNotifier {
  ServicioConectividad({required this._fuente}) {
    _cargarEstadoInicial();
    _sub = _fuente.cambios.listen(_alCambiar);
  }

  final FuenteConectividad _fuente;
  final StreamController<bool> _controlador =
      StreamController<bool>.broadcast();
  StreamSubscription<bool>? _sub;
  bool _estaConectado = true;
  bool _desechado = false;
  bool _recibioCambio = false;

  /// Estado actual: true = online. Arranca en true y se corrige con la
  /// primera lectura de la fuente.
  bool get estaConectado => _estaConectado;

  /// Stream de cambios de conectividad: emite solo cuando el estado cambia
  /// (nunca valores repetidos).
  Stream<bool> get cambiosConectividad => _controlador.stream;

  Future<void> _cargarEstadoInicial() async {
    final online = await _fuente.estadoActual;
    // Si mientras se leía el estado inicial ya llegó un cambio de la fuente,
    // ese cambio es más reciente: no pisar con la foto vieja.
    if (_desechado || _recibioCambio) return;
    _aplicar(online);
  }

  void _alCambiar(bool online) {
    if (_desechado) return;
    _recibioCambio = true;
    _aplicar(online);
  }

  void _aplicar(bool online) {
    if (_estaConectado == online) return;
    _estaConectado = online;
    _controlador.add(online);
    notifyListeners();
  }

  @override
  void dispose() {
    _desechado = true;
    _sub?.cancel();
    _sub = null;
    _controlador.close();
    super.dispose();
  }
}
