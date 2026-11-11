import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get estaLogueado => _usuario != null;
  bool get esArtista => _usuario?.rol == RolUsuario.artista;
  bool get esOyente => _usuario?.rol == RolUsuario.oyente;
  bool get esInvitado => _usuario?.rol == RolUsuario.invitado;
  // Cuenta registrada (gratis): artista u oyente. El invitado no lo es.
  bool get esRegistrado => esArtista || esOyente;

  void login(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void logout() {
    _usuario = null;
    notifyListeners();
  }

  Future<void> loginConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await authService.ingresarConEmail(
        email: email,
        password: password,
        rol: rol,
      ),
    );
  }

  Future<void> loginConGoogle({required RolUsuario rol}) async {
    login(await authService.ingresarConGoogle(rol: rol));
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await authService.registrar(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
      ),
    );
  }

  Future<void> entrarComoInvitado() async {
    login(await authService.crearInvitado());
  }
}

final AuthViewModel authViewModel = AuthViewModel();
