import 'package:streamtunes_demo/models/usuario.dart';

/// Contrato de la capa de autenticación.
///
/// La implementación concreta se elige UNA SOLA VEZ en lib/inyeccion.dart y
/// se inyecta por constructor en AuthViewModel:
/// - [AuthServiceSimulado]: modo demo (tests, o todavía no se corrió
///   `flutterfire configure`).
/// - FirebaseAuthService (lib/services/firebase_auth_service.dart): auth real
///   con Firebase, ver docs/FIREBASE.md.
abstract class AuthService {
  /// Login/registro con email y contraseña.
  /// Con Firebase: FirebaseAuth.instance.signInWithEmailAndPassword /
  /// createUserWithEmailAndPassword.
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  });

  /// Login con Google. El rol (artista/oyente) no lo da Google: la app lo
  /// elige antes de llamar a este método (ver elegir_rol.dart).
  /// Apple Sign-In queda fuera por ahora (Android-first).
  Future<Usuario> ingresarConGoogle({required RolUsuario rol});

  /// Registro de cuenta nueva (gratis) con email y contraseña.
  /// Con Firebase: createUserWithEmailAndPassword + guardar el perfil
  /// (nombre, rol) en Firestore (paso 3, docs/FIREBASE.md).
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  });

  /// Entra sin cuenta: solo va a poder escuchar.
  Future<Usuario> crearInvitado();

  /// Cierra la sesión en el proveedor de auth (en el simulado es un no-op).
  Future<void> cerrarSesion();
}

/// Auth SIMULADO (modo demo): se usa cuando Firebase no está inicializado
/// (tests, o todavía no se corrió `flutterfire configure`).
class AuthServiceSimulado implements AuthService {
  int _contador = 0;

  // Simula la latencia de la red para que la UI muestre su estado de carga.
  Future<Usuario> _simularRed(Usuario Function() crear) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return crear();
  }

  @override
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

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) {
    // SIMULADO: hoy devuelve una cuenta de mentira. Con Firebase se hace el
    // flujo real de Google Sign-In y se crea el credential para FirebaseAuth
    // (paso a paso en docs/AUTH_GOOGLE.md).
    return _simularRed(
      () => Usuario(
        id: 'google_${++_contador}',
        nombre: 'Usuario de Google',
        email: 'usuario.google@gmail.com',
        rol: rol,
      ),
    );
  }

  @override
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

  @override
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

  @override
  Future<void> cerrarSesion() async {
    // El modo demo no tiene sesión que cerrar en ningún lado.
  }
}

// Instancia compartida del simulado (lazy: no hace nada hasta usarse).
final AuthServiceSimulado authServiceSimulado = AuthServiceSimulado();
