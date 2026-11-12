import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';

// Servicio de auth activo: Firebase si se inicializó bien; si no, el simulado.
// Así la app funciona igual en modo demo (tests, sin configurar Firebase).
AuthService get _servicioAuth =>
    firebaseInicializado ? firebaseAuthService : authService;

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
    // Si hay Firebase, también se cierra la sesión allá (fire and forget).
    if (firebaseInicializado) {
      firebaseAuthService.cerrarSesion();
    }
    notifyListeners();
  }

  Future<void> loginConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await _servicioAuth.ingresarConEmail(
        email: email,
        password: password,
        rol: rol,
      ),
    );
  }

  Future<void> loginConGoogle({required RolUsuario rol}) async {
    login(await _servicioAuth.ingresarConGoogle(rol: rol));
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await _servicioAuth.registrar(
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
