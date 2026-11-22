import 'package:connectivity_plus/connectivity_plus.dart';

/// Fuente de verdad de la conectividad de red de la app.
///
/// Contrato chico para poder inyectar un fake en los tests sin depender del
/// plugin real ni de hardware: el servicio solo ve esta interfaz.
abstract class FuenteConectividad {
  /// Emite true/false cada vez que cambia el estado de la red.
  Stream<bool> get cambios;

  /// Estado actual de la red (true = online).
  Future<bool> get estadoActual;
}

/// Envoltura mínima sobre connectivity_plus: traduce la lista de
/// [ConnectivityResult] a un bool (online = hay al menos una interfaz que no
/// sea `none`).
class FuenteConectividadPlus implements FuenteConectividad {
  FuenteConectividadPlus({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get cambios => _connectivity.onConnectivityChanged.map(
    (resultados) => resultados.any((r) => r != ConnectivityResult.none),
  );

  @override
  Future<bool> get estadoActual async {
    final resultados = await _connectivity.checkConnectivity();
    return resultados.any((r) => r != ConnectivityResult.none);
  }
}
