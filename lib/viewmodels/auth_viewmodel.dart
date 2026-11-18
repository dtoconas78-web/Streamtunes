import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';

// ViewModel de autenticación: depende SOLO del contrato [AuthService], que se
// inyecta por constructor. Qué implementación concreta se usa (Firebase o
// simulado) se decide en un único lugar: lib/inyeccion.dart. Los tests pueden
// pasar un AuthService falso para probar el VM aislado del singleton global.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._servicio});

  final AuthService _servicio;

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
    // También se cierra la sesión en el proveedor inyectado (fire and
    // forget; en el simulado es un no-op).
    _servicio.cerrarSesion();
    notifyListeners();
  }

  Future<void> loginConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await _servicio.ingresarConEmail(
        email: email,
        password: password,
        rol: rol,
      ),
    );
  }

  Future<void> loginConGoogle({required RolUsuario rol}) async {
    login(await _servicio.ingresarConGoogle(rol: rol));
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    login(
      await _servicio.registrar(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
      ),
    );
  }

  Future<void> entrarComoInvitado() async {
    login(await _servicio.crearInvitado());
  }
}
