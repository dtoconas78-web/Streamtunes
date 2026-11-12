import 'package:flutter/material.dart';

// Preferencias simples del oyente (en memoria; con backend van a la cuenta).
class ConfiguracionViewModel extends ChangeNotifier {
  bool notificaciones = true;
  bool reproduccionAutomatica = true;
  bool modoAleatorioPorDefecto = false;

  void setNotificaciones(bool v) {
    if (notificaciones == v) return;
    notificaciones = v;
    notifyListeners();
  }

  void setReproduccionAutomatica(bool v) {
    if (reproduccionAutomatica == v) return;
    reproduccionAutomatica = v;
    notifyListeners();
  }

  void setModoAleatorioPorDefecto(bool v) {
    if (modoAleatorioPorDefecto == v) return;
    modoAleatorioPorDefecto = v;
    notifyListeners();
  }
}

// Instancia compartida por toda la app.
final ConfiguracionViewModel configuracionViewModel = ConfiguracionViewModel();
