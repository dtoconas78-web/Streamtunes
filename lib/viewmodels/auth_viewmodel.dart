import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';

class AuthViewModel extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get estaLogueado => _usuario != null;
  bool get esArtista => _usuario?.rol == RolUsuario.artista;
  bool get esOyente => _usuario?.rol == RolUsuario.oyente;

  void login(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void logout() {
    _usuario = null;
    notifyListeners();
  }
}

final AuthViewModel authViewModel = AuthViewModel();