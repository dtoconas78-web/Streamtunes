import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';

/// Auth real con Firebase: Google Sign-In + Firebase Auth (y email/clave).
///
/// Solo se usa cuando Firebase se inicializó bien (ver firebase_inicial.dart);
/// si no, la app usa AuthService (simulado) y los tests nunca tocan Firebase.
///
/// El rol (artista/oyente) NO lo da Google: la app lo eligió antes de llamar
/// (ver elegir_rol.dart). Cuando llegue Firestore (paso 3), el perfil con el
/// rol se guarda ahí al primer login; por ahora el rol elegido se usa directo.
class FirebaseAuthService extends AuthService {
  // Ojo: estos getters solo se tocan cuando Firebase está inicializado.
  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _google => GoogleSignIn.instance;
  bool _googleInit = false;

  // google_sign_in v7 exige llamar initialize() exactamente una vez (y esperar
  // el future) antes de cualquier otro método; sin esto el comportamiento es
  // "undefined" y authenticate() puede fallar aunque todo esté bien configurado.
  // En Android alcanza sin argumentos: lee el default_web_client_id generado
  // desde google-services.json por el plugin de Gradle.
  Future<void> _initGoogle() async {
    if (_googleInit) return;
    await _google.initialize();
    _googleInit = true;
  }

  Usuario _mapear(User fbUser, RolUsuario rol) => Usuario(
    id: fbUser.uid,
    nombre:
        fbUser.displayName ??
        (fbUser.email?.split('@').first ?? 'Usuario de Google'),
    email: fbUser.email ?? '',
    rol: rol,
    fotoUrl: fbUser
        .photoURL, // foto de perfil de Google (se sube a Storage en el paso 2)
  );

  /// Login/registro con Google (google_sign_in v7 + Firebase Auth):
  /// 1) initialize + selector de cuentas de Google, 2) credential con el
  /// idToken, 3) signInWithCredential en Firebase Auth.
  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) async {
    await _initGoogle();
    final googleUser = await _google.authenticate();
    final credential = GoogleAuthProvider.credential(
      idToken: googleUser.authentication.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _mapear(cred.user!, rol);
  }

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapear(cred.user!, rol);
  }

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(nombre);
    return _mapear(cred.user!, rol);
  }

  /// Cierra la sesión en Firebase y en Google (el invitado no usa Firebase).
  Future<void> cerrarSesion() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Si nunca se logueó con Google, no pasa nada.
    }
    await _auth.signOut();
  }
}

// Instancia compartida (lazy: no toca Firebase hasta usarse).
final FirebaseAuthService firebaseAuthService = FirebaseAuthService();
