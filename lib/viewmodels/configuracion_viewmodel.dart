import 'package:flutter/material.dart';

// Preferencias simples del oyente (en memoria; con backend van a la cuenta).
class ConfiguracionViewModel extends ChangeNotifier {
  bool _notificaciones = true;
  bool _reproduccionAutomatica = true;
  bool _modoAleatorioPorDefecto = false;

  // Getters de solo lectura: los cambios pasan por los setters, que notifican.
  bool get notificaciones => _notificaciones;
  bool get reproduccionAutomatica => _reproduccionAutomatica;
  bool get modoAleatorioPorDefecto => _modoAleatorioPorDefecto;

  void setNotificaciones(bool v) {
    if (_notificaciones == v) return;
    _notificaciones = v;
    notifyListeners();
  }

  void setReproduccionAutomatica(bool v) {
    if (_reproduccionAutomatica == v) return;
    _reproduccionAutomatica = v;
    notifyListeners();
  }

  void setModoAleatorioPorDefecto(bool v) {
    if (_modoAleatorioPorDefecto == v) return;
    _modoAleatorioPorDefecto = v;
    notifyListeners();
  }
}

// Instancia compartida por toda la app.
final ConfiguracionViewModel configuracionViewModel = ConfiguracionViewModel();
