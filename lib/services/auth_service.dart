import 'package:streamtunes_demo/models/usuario.dart';

/// Capa de autenticación.
///
/// AHORA está simulada con datos falsos, igual que el resto de la app (todavía
/// no hay backend). DESPUÉS solo se reemplaza el interior de esta clase por
/// Firebase Auth + Google Sign-In (ver docs/AUTH_GOOGLE.md): las pantallas y
/// el AuthViewModel no cambian.
class AuthService {
  int _contador = 0;

  // Simula la latencia de la red para que la UI muestre su estado de carga.
  Future<Usuario> _simularRed(Usuario Function() crear) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return crear();
  }

  /// Login/registro con email y contraseña.
  /// DESPUÉS: FirebaseAuth.instance.signInWithEmailAndPassword /
  /// createUserWithEmailAndPassword.
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) {
    return _simularRed(
      () => Usuario(
        id: 'email_${++_contador}',
        nombre: email.split('@').first,
        email: email,
        rol: rol,
      ),
    );
  }

  /// Login con Google. SIMULADO: hoy devuelve una cuenta de mentira.
  /// DESPUÉS: acá se hace el flujo real de Google Sign-In y se crea el
  /// credential para FirebaseAuth (paso a paso en docs/AUTH_GOOGLE.md).
  ///
  /// Nota: el rol (artista/oyente) no lo da Google; la app lo elige antes de
  /// llamar a este método. Apple Sign-In queda fuera por ahora (Android-first).
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) {
    return _simularRed(
      () => Usuario(
        id: 'google_${++_contador}',
        nombre: 'Usuario de Google',
        email: 'usuario.google@gmail.com',
        rol: rol,
      ),
    );
  }

  /// Registro de cuenta nueva (gratis) con email y contraseña.
  /// DESPUÉS: FirebaseAuth.instance.createUserWithEmailAndPassword + guardar
  /// el perfil (nombre, rol) en Firestore.
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) {
    return _simularRed(
      () => Usuario(
        id: 'reg_${++_contador}',
        nombre: nombre,
        email: email,
        rol: rol,
      ),
    );
  }

  /// Entra sin cuenta: solo va a poder escuchar.
  Future<Usuario> crearInvitado() {
    return _simularRed(
      () => Usuario(
        id: 'invitado_${++_contador}',
        nombre: 'Invitado',
        email: '',
        rol: RolUsuario.invitado,
      ),
    );
  }
}

final AuthService authService = AuthService();
