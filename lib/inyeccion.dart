import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_artistas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_entradas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos_firestore.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/services/firebase_semilla.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/utils/reloj.dart';
import 'package:streamtunes_demo/viewmodels/seguimiento_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/services/fuente_conectividad.dart';
import 'package:streamtunes_demo/services/gestor_ciclo_vida.dart';
import 'package:streamtunes_demo/services/servicio_conectividad.dart';
import 'package:streamtunes_demo/services/servicio_notificaciones.dart';

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

// --- Repositorios ---
// Bloque A + B (Firestore): con Firebase inicializado, los cuatro repositorios
// vienen de Firestore (snapshots en tiempo real; entradas con compra atómica
// transaccional). Sin Firebase (tests, demo, Windows/Linux) todo queda en
// memoria con la semilla de datos_ejemplo.dart (que ya no se toca desde ningún
// ViewModel).
final FuenteFirestore fuenteFirestore = FuenteFirestoreFirebase();

final RepositorioCatalogo repositorioCatalogo = _crearCatalogo();
final RepositorioArtistas repositorioArtistas = _crearArtistas();
final RepositorioEntradas repositorioEntradas = _crearEntradas();
final RepositorioMovimientos repositorioMovimientos = _crearMovimientos();

/// UID de la sesión VÁLIDA de Firebase, resuelto de forma diferida (el usuario
/// hace login después de crear los repositorios). Devuelve null cuando no hay
/// sesión o cuando el usuario es invitado: el invitado es una cuenta LOCAL
/// (id `invitado_N` del simulado) y NO tiene sesión en Firebase, así que ese
/// id nunca debe usarse como uid de Firestore.
String? _uidSesionValida() {
  final usuario = authViewModel.usuario;
  if (usuario == null || usuario.rol == RolUsuario.invitado) return null;
  return usuario.id; // en Firebase mode Usuario.id = fbUser.uid
}

RepositorioCatalogo _crearCatalogo() {
  if (!firebaseInicializado) return RepositorioCatalogoMemoria();
  _dispararSemilla();
  return RepositorioCatalogoFirestore(fuente: fuenteFirestore);
}

RepositorioArtistas _crearArtistas() {
  if (!firebaseInicializado) return RepositorioArtistasMemoria();
  _dispararSemilla();
  return RepositorioArtistasFirestore(fuente: fuenteFirestore);
}

RepositorioEntradas _crearEntradas() {
  if (!firebaseInicializado) return RepositorioEntradasMemoria();
  _dispararSemilla();
  return RepositorioEntradasFirestore(
    fuente: fuenteFirestore,
    uidActual: _uidSesionValida,
  );
}

RepositorioMovimientos _crearMovimientos() {
  if (!firebaseInicializado) return RepositorioMovimientosMemoria();
  _dispararSemilla();
  return RepositorioMovimientosFirestore(
    fuente: fuenteFirestore,
    uidActual: _uidSesionValida,
  );
}

// Semilla idempotente (Bloque A): se dispara UNA SOLA VEZ por arranque y solo
// con Firebase inicializado. No bloquea la creación de los repositorios ni el
// hilo principal: corre en segundo plano con sus propios errores capturados,
// y los repos se enteran de los datos nuevos vía sus snapshots. Si falla, la
// app sigue con lo que haya en Firestore.
//
// Las reglas de Firestore solo permiten escribir con `request.auth != null`,
// así que la semilla espera al primer usuario con sesión en Firebase Auth (al
// arrancar todavía no hay nadie logueado y la escritura daría
// PERMISSION_DENIED). El invitado es local y no cuenta como sesión.
bool _semillaDisparada = false;
StreamSubscription<User?>? _esperaSesionSemilla;

void _dispararSemilla() {
  if (_semillaDisparada) return;
  _semillaDisparada = true;
  _esperaSesionSemilla = FirebaseAuth.instance.authStateChanges().listen((
    usuario,
  ) {
    if (usuario == null) return;
    _esperaSesionSemilla?.cancel();
    _esperaSesionSemilla = null;
    unawaited(_sembrar());
  });
}

Future<void> _sembrar() async {
  try {
    debugPrint(
      'Semilla Firestore: ${await poblarSemillaSiVacia(fuenteFirestore)}',
    );
  } catch (e) {
    debugPrint(
      'Falló la semilla de Firestore (se usa lo que haya en la nube): $e',
    );
  }
}

// Reloj inyectado en los VMs que sellan fechas de lógica de negocio
// (movimientos económicos). En tests se puede inyectar un RelojFijo.
final Reloj reloj = RelojDelSistema();

// Capacidades y políticas de la app (ver lib/plataforma/plataforma.dart):
// un solo lugar para saber qué está implementado y qué se le explica al
// usuario cuando algo no lo está.
final Capacidades capacidades = Capacidades();
final Politicas politicas = Politicas();

/// Servicio reactivo de conectividad (online/offline). En la app la fuente es
/// connectivity_plus; en los tests se inyecta un FuenteConectividad falso.
final ServicioConectividad servicioConectividad = ServicioConectividad(
  fuente: FuenteConectividadPlus(),
);

// --- Ciclo de vida de la app ---
// El gestor es lazy a propósito: hay que activarlo UNA VEZ al arrancar con
// inicializarCicloVida() (después de WidgetsFlutterBinding.ensureInitialized(),
// porque el AppLifecycleListener necesita el binding). En los tests no se
// activa y no pasa nada.
GestorCicloVida? _gestorCicloVida;

GestorCicloVida get gestorCicloVida =>
    _gestorCicloVida ??= _crearGestorCicloVida();

/// Activa el gestor de ciclo de vida: crea el AppLifecycleListener y registra
/// los callbacks que frenan/reanudan la reproducción al ir a segundo plano.
void inicializarCicloVida() {
  _gestorCicloVida ??= _crearGestorCicloVida();
}

/// Servicio de notificaciones locales (aviso de reproducción en pausa al ir
/// a segundo plano). En la app es el plugin real; en los tests se inyecta uno
/// falso. Hay que inicializarlo una vez al arrancar (ver main.dart).
final ServicioNotificaciones servicioNotificaciones =
    ServicioNotificacionesLocal();

Future<void> inicializarNotificaciones() =>
    servicioNotificaciones.inicializar();

GestorCicloVida _crearGestorCicloVida() {
  final gestor = GestorCicloVida();
  registrarReproduccionEnCicloVida(gestor, reproductor, servicioNotificaciones);
  return gestor;
}

/// Registra en el gestor de ciclo de vida el comportamiento de la
/// reproducción: al ir a segundo plano se pausa y se muestra la notificación
/// fija "en pausa"; al volver se reanuda y se oculta la notificación.
void registrarReproduccionEnCicloVida(
  GestorCicloVida gestor,
  ControladorReproduccion reproductor,
  ServicioNotificaciones notificaciones,
) {
  var pausadaPorCiclo = false;
  gestor.registrar(
    alPausar: () {
      // Al ir a segundo plano se frena la reproducción si sonaba y se avisa
      // con la notificación fija para saber que quedó en pausa.
      if (reproductor.reproduciendo) {
        pausadaPorCiclo = true;
        reproductor.alternarPausa();
        notificaciones.mostrarReproduccionEnPausa(
          reproductor.cancion?.titulo ?? '',
        );
      }
    },
    alReanudar: () {
      // Al volver se reanuda solo si el ciclo de vida la había frenado.
      if (pausadaPorCiclo) {
        pausadaPorCiclo = false;
        reproductor.alternarPausa();
        notificaciones.ocultarReproduccion();
      }
    },
  );
}

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
  reloj: reloj,
  uidActual: _uidSesionValida,
);
final VentasViewModel ventasViewModel = VentasViewModel(
  repositorio: repositorioMovimientos,
  reloj: reloj,
);

final PlaylistsViewModel playlistsViewModel = PlaylistsViewModel();
final ConfiguracionViewModel configuracionViewModel = ConfiguracionViewModel();

// Identidad del artista de esta sesión: SIEMPRE sale del repositorio.
// Si porId no lo encuentra, se falla con error explícito en vez de inventar
// un artista desconectado (en el demo, la semilla datos_ejemplo lo incluye).
// Excepción documentada: con Firestore la caché del repo arranca vacía hasta
// el primer snapshot, así que hasta entonces se usa la semilla local como
// identidad provisoria (el repo se actualiza solo cuando llega el snapshot).
Artista _artistaSesion() {
  final artista = repositorioArtistas.porId('mateo-cabral');
  if (artista != null) return artista;
  if (firebaseInicializado) {
    final provisorio = datos.artistas
        .where((a) => a.id == 'mateo-cabral')
        .firstOrNull;
    if (provisorio != null) return provisorio;
  }
  throw StateError(
    'RepositorioArtistas no contiene al artista "mateo-cabral": '
    'revisar la semilla de datos_ejemplo.dart.',
  );
}

final PerfilUsuario perfil = PerfilUsuario(artista: _artistaSesion());
