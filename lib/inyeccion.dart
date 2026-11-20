import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart' as datos;
import 'package:streamtunes_demo/data/fuente_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_artistas.dart';
import 'package:streamtunes_demo/data/repositorio_artistas_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo_firestore.dart';
import 'package:streamtunes_demo/data/repositorio_entradas.dart';
import 'package:streamtunes_demo/data/repositorio_movimientos.dart';
import 'package:streamtunes_demo/models/artista.dart';
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
// Bloque A (Firestore en tiempo real): con Firebase inicializado, catálogo y
// artistas vienen de Firestore (snapshots); entradas y movimientos quedan en
// memoria hasta el Bloque B. Sin Firebase (tests, demo, Windows/Linux) todo
// queda en memoria con la semilla de datos_ejemplo.dart (que ya no se toca
// desde ningún ViewModel).
final FuenteFirestore fuenteFirestore = FuenteFirestoreFirebase();

final RepositorioCatalogo repositorioCatalogo = _crearCatalogo();
final RepositorioArtistas repositorioArtistas = _crearArtistas();
final RepositorioEntradas repositorioEntradas = RepositorioEntradasMemoria();
final RepositorioMovimientos repositorioMovimientos =
    RepositorioMovimientosMemoria();

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

// Semilla idempotente (Bloque A): se dispara UNA SOLA VEZ por arranque y solo
// con Firebase inicializado. No bloquea la creación de los repositorios ni el
// hilo principal: corre en segundo plano con sus propios errores capturados,
// y los repos se enteran de los datos nuevos vía sus snapshots. Si falla, la
// app sigue con lo que haya en Firestore.
bool _semillaDisparada = false;

void _dispararSemilla() {
  if (_semillaDisparada) return;
  _semillaDisparada = true;
  unawaited(_sembrar());
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
