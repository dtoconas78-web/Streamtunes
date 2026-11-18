import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';

/// Raíz de composición de la app: acá se arma UNA SOLA VEZ qué
/// implementaciones concretas reciben los ViewModels (inyección de
/// dependencias por constructor).
///
/// Las globales top-level de Dart son lazy: se evalúan en el primer acceso,
/// que en la app ocurre después de `inicializarFirebase()` en main(). En los
/// tests `firebaseInicializado` queda en false y se usa el simulado, así que
/// los tests nunca tocan Firebase.

/// Servicio de auth activo: Firebase si se inicializó bien; si no, el simulado.
final AuthService servicioAuth = firebaseInicializado
    ? firebaseAuthService
    : authServiceSimulado;

/// ViewModel de auth compartido por toda la app, con su servicio inyectado.
final AuthViewModel authViewModel = AuthViewModel(servicio: servicioAuth);
