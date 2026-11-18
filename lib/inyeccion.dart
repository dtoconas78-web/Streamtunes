import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

/// Raíz de composición de la app: acá se arma UNA SOLA VEZ qué
/// implementaciones concretas reciben los servicios y ViewModels (inyección de
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

// --- Repositorios: en memoria, con los datos de ejemplo como semilla ---
// (datos_ejemplo.dart ya no se toca desde ningún ViewModel; con backend, acá
// se cambian estas líneas por las implementaciones reales, p. ej. Firestore).
final RepositorioCatalogo repositorioCatalogo = RepositorioCatalogoMemoria();
final RepositorioArtistas repositorioArtistas = RepositorioArtistasMemoria();
final RepositorioEntradas repositorioEntradas = RepositorioEntradasMemoria();
final RepositorioMovimientos repositorioMovimientos =
    RepositorioMovimientosMemoria();

// --- ViewModels con sus dependencias inyectadas ---
// Ojo: catalogo y reproductor comparten el MISMO repositorio de catálogo,
// así los índices de la cola de reproducción siempre apuntan al catálogo real.
final CatalogoViewModel catalogo = CatalogoViewModel(
  repositorio: repositorioCatalogo,
);
final ControladorReproduccion reproductor = ControladorReproduccion(
  repositorioCatalogo: repositorioCatalogo,
);
final SeguimientoViewModel seguimientoViewModel = SeguimientoViewModel(
  repositorioArtistas: repositorioArtistas,
  repositorioCatalogo: repositorioCatalogo,
);
final EntradasViewModel entradasViewModel = EntradasViewModel(
  repositorioEntradas: repositorioEntradas,
  repositorioMovimientos: repositorioMovimientos,
);
final VentasViewModel ventasViewModel = VentasViewModel(
  repositorio: repositorioMovimientos,
);
