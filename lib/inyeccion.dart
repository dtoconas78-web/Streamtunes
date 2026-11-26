import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/services/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_artistas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_ciudad.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/data/repositorio_metricas.dart';
import 'package:streamtunes_demo/data/reproducciones_dao.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_entradas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/data/playlists_dao.dart';
import 'package:streamtunes_demo/data/repositorio_playlists_sqlite.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento_preferencias.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/aviso_donaciones.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/services/firebase_semilla.dart';
import 'package:streamtunes_demo/services/persistencia_local.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/metricas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/perfil_oyente_viewmodel.dart';
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
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:streamtunes_demo/services/sincronizacion_metricas.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano_workmanager.dart';

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
// memoria con la semilla de data/services/datos_ejemplo.dart (que ya no se toca desde ningún
// ViewModel).
final FuenteFirestore fuenteFirestore = FuenteFirestoreFirebase();

final RepositorioCatalogo repositorioCatalogo = _crearCatalogo();
final RepositorioArtistas repositorioArtistas = _crearArtistas();
final RepositorioEntradas repositorioEntradas = _crearEntradas();
final RepositorioMovimientos repositorioMovimientos = _crearMovimientos();

// Datos del oyente: las playlists van en SQLite y los seguidos y "me gusta"
// en SharedPreferencesAsync, si main() pudo abrirlos
// (inicializarPersistenciaLocal); si no (tests, o falla el plugin), quedan en
// memoria. Son POR USUARIO: siguen al usuario con sesión de authViewModel y
// al cerrar sesión (o como invitado) quedan vacíos y no se guarda nada.
final RepositorioPlaylists repositorioPlaylists = _vincularAlUsuario(
  baseDatosLocal == null
      ? RepositorioPlaylistsMemoria()
      : RepositorioPlaylistsSqlite(
          dao: PlaylistsDao(baseDatosLocal!),
          // Para importar las playlists del guardado anterior (JSON).
          prefsViejas: preferenciasLocales,
        ),
  (r, uid) => r.usarUsuario(uid),
);
final RepositorioSeguimiento repositorioSeguimiento = _vincularAlUsuario(
  preferenciasLocales == null
      ? RepositorioSeguimientoMemoria()
      : RepositorioSeguimientoPreferencias(prefs: preferenciasLocales!),
  (r, uid) => r.usarUsuario(uid),
);

// Ciudad que declara el oyente en su perfil (para las métricas; sin GPS).
final PerfilOyenteViewModel perfilOyenteViewModel = _vincularAlUsuario(
  PerfilOyenteViewModel(
    repositorio: preferenciasLocales == null
        ? RepositorioCiudadMemoria()
        : RepositorioCiudadPreferencias(prefs: preferenciasLocales!),
  ),
  (vm, uid) => vm.usarUsuario(uid),
);

// --- Métricas de reproducción ---
// Con Firebase, las métricas viven en la colección `metricas` (todos los
// oyentes suman con incrementos atómicos); sin Firebase, en memoria. Cada
// reproducción contada va primero a la cola local en SQLite (si hay) y se
// sube con registroReproducciones.sincronizar().
final RepositorioMetricas repositorioMetricas = firebaseInicializado
    ? RepositorioMetricasFirestore(fuente: fuenteFirestore)
    : RepositorioMetricasMemoria();

final RegistroReproducciones registroReproducciones = RegistroReproducciones(
  metricas: repositorioMetricas,
  ciudad: () => perfilOyenteViewModel.ciudadParaMetricas,
  dao: baseDatosLocal == null ? null : ReproduccionesDao(baseDatosLocal!),
  reloj: reloj,
);

final MetricasViewModel metricasViewModel = MetricasViewModel(
  repositorio: repositorioMetricas,
);

/// Sube las reproducciones pendientes al arrancar, al iniciar sesión (las
/// reglas de Firestore piden sesión para escribir) y al ir a segundo plano.
/// La tarea de workmanager cubre el caso de la app cerrada.
void inicializarMetricas() {
  if (!firebaseInicializado) return;
  void sincronizar() {
    if (_uidSesionValida() != null) {
      unawaited(registroReproducciones.sincronizar());
    }
  }

  sincronizar();
  authViewModel.addListener(sincronizar);
  gestorCicloVida.registrar(alPausar: sincronizar);
}

// Carga ya los datos del usuario actual y los recarga en cada login/logout
// (usarUsuario no hace nada si el uid no cambió).
T _vincularAlUsuario<T>(T repo, void Function(T, String?) usarUsuario) {
  usarUsuario(repo, _uidSesionValida());
  authViewModel.addListener(() => usarUsuario(repo, _uidSesionValida()));
  return repo;
}

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

/// Id del artista de la sesión, o null si quien usa la app no es artista.
String? _artistaSesionId() =>
    authViewModel.esArtista ? perfil.artista.id : null;

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
    // El artista ve también las donaciones que le hacen otros usuarios.
    artistaActual: _artistaSesionId,
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
// usuario cuando algo no lo está. Las de notificaciones y tareas se activan
// solo si main() inicializó de verdad el plugin y workmanager (en los tests
// main() no corre y quedan en false). Es lazy: se evalúa en el primer acceso,
// que en la app ocurre después de esas inicializaciones.
final Capacidades capacidades = Capacidades(
  notificacionesDisponibles: _notificacionesListas,
  notificacionesProgramadas: _notificacionesListas,
  tareasSegundoPlano: _tareasListas,
);
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
final ServicioNotificacionesLocal _notificacionesLocal =
    ServicioNotificacionesLocal();
final ServicioNotificaciones servicioNotificaciones = _notificacionesLocal;

/// Permiso, recordatorios de conciertos y novedades (misma instancia real).
final ServicioRecordatorios servicioRecordatorios = _notificacionesLocal;

bool _notificacionesListas = false;

/// Inicializa el plugin de notificaciones. Nunca lanza: si falla (p. ej.
/// plataforma sin soporte), la app sigue sin notificaciones y la capacidad
/// queda en false.
Future<void> inicializarNotificaciones() async {
  try {
    await servicioNotificaciones.inicializar();
    _notificacionesListas = true;
  } catch (e) {
    debugPrint('Notificaciones no disponibles: $e');
  }
}

// --- Tareas en segundo plano (workmanager) ---
final ServicioTareasWorkmanager _tareasWorkmanager =
    ServicioTareasWorkmanager();
bool _tareasListas = false;

/// Servicio de tareas activo: workmanager si se inicializó; si no, uno vacío.
/// Lazy: en la app se evalúa después de [inicializarTareasSegundoPlano].
final ServicioTareasSegundoPlano servicioTareas = _tareasListas
    ? _tareasWorkmanager
    : const ServicioTareasNulo();

/// Inicializa workmanager UNA vez al arrancar (después de las
/// notificaciones). Si el usuario ya tenía las notificaciones activadas, se
/// asegura de que la tarea periódica esté registrada (política update: no se
/// duplica). Nunca lanza.
Future<void> inicializarTareasSegundoPlano() async {
  try {
    await _tareasWorkmanager.inicializar();
    _tareasListas = true;
    // Subida de métricas con la app cerrada: siempre registrada (no depende
    // de la preferencia de notificaciones). Política update: no se duplica.
    if (firebaseInicializado && baseDatosLocal != null) {
      await _tareasWorkmanager.registrarSincronizacionMetricas();
    }
    if (configuracionViewModel.notificaciones) {
      await servicioTareas.registrarVerificacionPeriodica();
    }
  } catch (e) {
    debugPrint('Tareas en segundo plano no disponibles: $e');
  }
}

// --- Aviso de donaciones recibidas (al artista, con la app abierta) ---
final AvisoDonaciones avisoDonaciones = AvisoDonaciones(
  repositorio: repositorioMovimientos,
  sesion: authViewModel,
  artistaActual: _artistaSesionId,
  // Capacidad real + preferencia del usuario, consultadas en cada aviso.
  activo: () =>
      capacidades.notificacionesDisponibles &&
      configuracionViewModel.notificaciones,
  avisar: servicioRecordatorios.mostrarDonacionRecibida,
  reloj: reloj,
);

/// Activa el aviso de donaciones (solo si el plugin de notificaciones se
/// inicializó; en los tests no se activa).
void inicializarAvisoDonaciones() {
  if (_notificacionesListas) avisoDonaciones.iniciar();
}

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
  repositorioSeguimiento: repositorioSeguimiento,
  // Cada reproducción contada (30 s escuchados) va a las métricas.
  alContarReproduccion: registroReproducciones.contar,
);
final SeguimientoViewModel seguimientoViewModel = SeguimientoViewModel(
  repositorioArtistas: repositorioArtistas,
  repositorioCatalogo: repositorioCatalogo,
  repositorioSeguimiento: repositorioSeguimiento,
);
final EntradasViewModel entradasViewModel = EntradasViewModel(
  repositorioEntradas: repositorioEntradas,
  repositorioMovimientos: repositorioMovimientos,
  reloj: reloj,
  uidActual: _uidSesionValida,
  recordatorios: servicioRecordatorios,
  // Se consulta en cada compra: capacidad real + preferencia del usuario.
  recordatoriosActivos: () =>
      capacidades.notificacionesProgramadas &&
      configuracionViewModel.notificaciones,
);
final VentasViewModel ventasViewModel = VentasViewModel(
  repositorio: repositorioMovimientos,
  reloj: reloj,
);

final PlaylistsViewModel playlistsViewModel = PlaylistsViewModel(
  repositorio: repositorioPlaylists,
);
// La preferencia de notificaciones se guarda en el celular si hay guardado
// local. Como SharedPreferencesAsync lee en forma asíncrona, main() espera
// [inicializarConfiguracion] antes de que se cree el ViewModel.
final RepositorioConfiguracion repositorioConfiguracion =
    preferenciasLocales == null
    ? RepositorioConfiguracionMemoria()
    : RepositorioConfiguracionPreferencias(prefs: preferenciasLocales!);

/// Lee la configuración guardada. Nunca lanza (el repo captura sus errores).
Future<void> inicializarConfiguracion() => repositorioConfiguracion.cargar();

// El permiso y los recordatorios solo se usan con el plugin listo.
final ConfiguracionViewModel configuracionViewModel = ConfiguracionViewModel(
  repositorio: repositorioConfiguracion,
  recordatorios: _notificacionesListas ? servicioRecordatorios : null,
  tareas: servicioTareas,
);

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
    'revisar la semilla de data/services/datos_ejemplo.dart.',
  );
}

final PerfilUsuario perfil = PerfilUsuario(artista: _artistaSesion());
