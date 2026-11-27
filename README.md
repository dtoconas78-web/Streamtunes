# StreamTunes

App móvil (Flutter) para escuchar música gratis, pensada para artistas "under".

## La idea

- **Escuchar es gratis, siempre.** No hay suscripciones ni paywall: si está en
  StreamTunes, se puede escuchar gratis.
- **La diferencia es el apoyo directo al artista.** La plata entra por:
  - Donaciones directas al artista.
  - Conciertos publicados por el artista (ver concierto, comprar entrada).
  - El artista ve sus **ventas y donaciones** desde su perfil.
  - **Comisión:** StreamTunes se queda con el 30% de cada entrada vendida
    (`utils/comision.dart`). El fan paga el precio publicado, sin cargos extra; las
    donaciones llegan completas. Cada venta guarda su `comision` y Ventas y
    donaciones muestra bruto, comisión y neto (documentos viejos: comisión 0).
  - **Donaciones:** el fan dona con su nombre o en forma anónima, desde Donar o
    desde el reproductor sin dejar de escuchar (`views/widgets/hoja_donacion.dart`;
    si no sigue al artista se le ofrece "Seguir y donar"). Cada donación guarda
    `donante` ('' = anónima) y `artistaId`. El artista ve "Quién te banca" en su
    perfil y recibe una notificación local por cada donación nueva mientras tiene
    la app abierta (`services/aviso_donaciones.dart`; sin push ni servidor).
  - **Métricas reales:** una reproducción cuenta cuando se escuchan 30 s (o la
    canción entera si es más corta; adelantar no suma). Se guarda en la cola local
    SQLite (`reproducciones`, esquema v2) con la ciudad que el oyente declara en su
    perfil (sin GPS) y la franja horaria, y se sube a `metricas/{cancionId}` con
    `FieldValue.increment` (`services/sincronizacion_metricas.dart`) al arrancar, al
    iniciar sesión, al ir a segundo plano y con una tarea periódica de workmanager.
    La app y la tarea reservan lotes para no sumar dos veces. El artista ve "Tu
    música en números" en su perfil y por canción en Estadísticas (resumen calculado
    en un isolate si hay muchas canciones). Sin Firebase ni datos, Estadísticas
    muestra los valores de ejemplo avisando que son de ejemplo.
  - **Cámara y galería** (`image_picker` + `path_provider`): foto de perfil del
    artista, foto de portada al subir música y foto del documento en la solicitud
    de verificación. Contrato `FuenteDeFotos` (resultado sellado: foto, canceló o
    falló) y `FotoViewModel`, que copia la foto a la carpeta de la app, guarda solo
    la RUTA (perfil en SharedPreferencesAsync, portadas en la tabla SQLite
    `portadas`, esquema v3) y borra la foto reemplazada. La del documento va a la
    carpeta temporal y se borra al enviar o salir (dato sensible); una portada no
    publicada también se borra. Si Android cierra la app con la cámara abierta, la
    foto de perfil se recupera al iniciar sesión (`retrieveLostData`). Sin permisos
    nuevos: usa la cámara y el selector de fotos del sistema. `Capacidades.camara`
    solo en Android/iOS.
- **Audio real** (`just_audio` + `audio_service`): las canciones suenan, también
  con la app en segundo plano o la pantalla bloqueada, con la notificación de
  reproducción (anterior, pausa, siguiente y barra). `ControladorReproduccion`
  sigue siendo la fuente de verdad (cola, modos, posición, conteo de 30 s);
  `services/audio/sincronizador_audio.dart` hace que el motor lo siga y devuelve
  al reproductor las órdenes de la notificación, auriculares y llamadas. Cada
  canción usa uno de los 6 audios de demo de `assets/audio/` (melodías originales
  generadas con `tool/generar_audios_demo.py`, sin derechos de terceros), en loop
  durante la duración de la canción del catálogo. Si el servicio de audio no
  arranca (o en los tests), la app sigue sin sonido y pausa al ir a segundo plano,
  como antes.
- **Dos roles + invitado:**
  - **Artista:** sube música, ve estadísticas, publica conciertos, ve ventas/donaciones.
  - **Oyente registrado:** escucha, compra entradas, dona, guarda música, crea listas.
  - **Invitado:** solo puede escuchar. Para subir canciones, guardar, crear listas,
    comprar entradas o donar, la app le pide crear una cuenta (gratis).

## Reglas de trabajo

- Primero que todo **funcione**, después se mejora la estética.
- Cada cambio va en su **propio commit** (mensajes breves en español), para no meter bugs.
- Trabajo en ramas (`feature/...`); `main` queda limpia.
- Por ahora el backend está pendiente (ver `docs/FIREBASE.md`): los datos y los logins
  externos (Google) usan la capa de servicio simulada, lista para conectar la API real
  después (ver `docs/AUTH_GOOGLE.md`). Apple Sign-In queda fuera por ahora: el desarrollo
  es Android-first.
- UX: nada ambiguo. Cualquier acción bloqueada para invitados dice claramente
  "registrate para…" y lleva al registro.

## Estructura actual

```
lib/
├── main.dart            → runApp + inicializarFirebase (modo demo si Firebase no está configurado)
├── inyeccion.dart       → raíz de composición: globales lazy (servicios, repositorios, VMs, reloj)
├── navigation/          → navegador global, rutas, cerrar sesión
├── models/              → Usuario, Artista, Cancion, Album, Concierto, Entrada, Movimiento, Playlist (inmutables)
├── data/                → contratos Repositorio* + implementaciones *Memoria/*Firestore/*Preferencias/*Sqlite (guardado local) y DAOs
│   └── services/        → semilla datos_ejemplo.dart y base SQLite (base_datos_local.dart)
├── services/            → contrato AuthService (simulado vs FirebaseAuthService, elegido en inyeccion.dart) + inicialización Firebase
├── viewmodels/          → ChangeNotifiers sin dependencias de UI (solo importan flutter/foundation)
├── views/screens/       → pantallas
├── views/widgets/       → widgets reutilizables
├── theme/ + utils/      → colores/tema, constantes, validadores, formatos, tiempo, errores_auth, reloj
```

## Convenciones de desarrollo

- **Capas y responsabilidades:**
  - `views/`: construye la UI con `material.dart` y escucha a los ViewModels con
    `ListenableBuilder`. No contiene lógica de negocio ni llamadas a servicios.
  - `viewmodels/`: estado + lógica de negocio como `ChangeNotifier`. **No importan
    nada de UI** (solo `flutter/foundation.dart`; verificado con `dart analyze`).
    Reciben sus dependencias por constructor.
  - `services/` y `data/`: contratos (`AuthService`, `Repositorio*`); la implementación
    concreta (simulada, memoria o Firebase) se elige en un único lugar: `inyeccion.dart`.
  - Guardado local (`services/persistencia_local.dart`):
    - Playlists en **SQLite** (`sqflite`): `data/services/base_datos_local.dart`
      (esquema versionado con `onCreate`/`onUpgrade`), `data/playlists_dao.dart`
      (consultas con `whereArgs`, escritura en transacción) y
      `RepositorioPlaylistsSqlite`. La primera vez importa las playlists que había
      como JSON en shared_preferences y borra esa clave.
    - Seguidos, "me gusta" y configuración en **`SharedPreferencesAsync`** (sin
      caché por isolate: la tarea de workmanager lee lo mismo que la app). Al
      arrancar se migran una sola vez los valores de la API vieja.
    - La carga es asíncrona: `usarUsuario(uid)` vacía en el acto, lee en segundo
      plano y notifica al terminar (`cargando`, `listo`); si cambia el usuario a
      mitad de la carga se descarta. Si `inicializarPersistenciaLocal()` no corrió
      (tests) todo queda en memoria. Son por usuario: al cerrar sesión o como
      invitado quedan vacíos y no se guarda nada.
    - Tests: base en memoria con `sqflite_common_ffi` y
      `InMemorySharedPreferencesAsync` (`test/dobles_persistencia.dart`).
  - Notificaciones (Configuración): al activarlas se pide el permiso real
    (`ServicioRecordatorios.solicitarPermisos`), se guarda la preferencia y se
    registra con `workmanager` una verificación periódica de conciertos nuevos
    (`callbackDispatcher` en `services/tareas_segundo_plano_workmanager.dart`,
    corre en un isolate aparte sin ViewModels). Al comprar una entrada se
    programa un recordatorio el día anterior a las 10 (modo inexacto, sin
    `SCHEDULE_EXACT_ALARM`). Las `Capacidades` solo se activan si `main()`
    inicializó el plugin y workmanager; en los tests quedan en `false`.
  - `models/`: datos inmutables, sin dependencias de Flutter.
  - `utils/`: funciones puras (formatos, validadores, `errores_auth`, `reloj`).
- **Inyección de dependencias:** `lib/inyeccion.dart` define globales top-level lazy
  (`servicioAuth`, los repositorios, los VMs, `perfil`, `reloj`). Los tests no usan los
  singletons: construyen VMs con dobles por constructor (p. ej.
  `AuthViewModel(servicio: _AuthServiceFalso())`).
- **Nomenclatura:** identificadores en español (`cargando`, `ultimoError`, `porId`).
- **Callbacks de widgets propios:** los parámetros de callback de widgets reutilizables
  usan el prefijo **`alXxx`** (ejemplos reales: `alAceptar` / `alCancelar` en los diálogos
  de `biblioteca_screen.dart` y `playlist_screen.dart`), junto a los `onXxx` estándar de
  Flutter (`onPressed`, `onChanged`, …).
- **Estado asíncrono en ViewModels:** `AuthViewModel` expone `cargando` (bool) y
  `ultimoError` (la excepción cruda, sin traducir) en vez de un enum `EstadoCarga`:
  alcanza porque cada pantalla ejecuta una operación a la vez. La vista traduce el error
  con `descripcionErrorAuth` (`utils/errores_auth.dart`), así que los mensajes específicos
  de Firebase/Google se conservan. Las operaciones llevan guard anti-concurrencia
  (`if (_cargando) return;`) y limpieza con `finally`. Las llamadas a Futures que se
  descartan intencionalmente van con `unawaited(...)` de `dart:async` (regla
  `unawaited_futures` activa; `unawaited` no atrapa errores, solo marca la intención).
- **Reloj inyectable:** `utils/reloj.dart` define `Reloj` (`RelojDelSistema` /
  `RelojFijo`). Se inyecta solo donde la fecha es lógica de negocio: los movimientos
  económicos (`EntradasViewModel`, `VentasViewModel`, vía `inyeccion.dart`). Las fechas
  de mera presentación (date pickers, valores por defecto de formularios) usan
  `DateTime.now()` directo en la vista.
- **Análisis estático:** `analysis_options.yaml` hereda `package:flutter_lints/flutter.yaml`
  y agrega explícitamente `prefer_single_quotes`, `always_declare_return_types` y
  `unawaited_futures` (ninguna viene en el conjunto heredado). Pendiente a futuro (no
  habilitada todavía porque hoy hay imports sin ordenar alfabéticamente en varios
  archivos): `directives_ordering`.

## Testing

- **Organización** (todo en `test/`):
  - Unitarios de ViewModels con dobles de prueba: `auth_viewmodel_test.dart`
    (`_AuthServiceFalso`, `_AuthServiceControlable` con `Completer` para controlar
    cuándo se resuelve el Future, y un servicio cuyo `cerrarSesion` falla probado con
    `runZonedGuarded`), `entradas_viewmodel_test.dart`, `catalogo_viewmodel_test.dart`,
    `playlists_viewmodel_test.dart`, `seguimiento_viewmodel_test.dart`,
    `reproductor_cola_test.dart`, `reproductor_flujo_test.dart`.
  - `reloj_viewmodels_test.dart`: fechas deterministas de movimientos con `RelojFijo`.
  - `errores_auth_test.dart`: mensajes específicos de `descripcionErrorAuth`.
  - `firebase_auth_service_test.dart`: cierre de sesión con fallos simulados de
    Google/Firebase (se sobreescriben `signOutGoogle`/`signOutFirebase`).
  - `widget_test.dart`: pruebas de widgets.
  - `flujo_completo_test.dart`: regresión de flujo completo (pantallas a tamaños fijos,
    detecta overflows y presencia de widgets).
- **Comandos de verificación:**
  ```bash
  dart format --set-exit-if-changed .
  dart analyze
  flutter test
  ```
  Actualmente: analyze sin issues y **251 tests aprobados**.
- **Convenciones para agregar pruebas:**
  - Las aserciones de los tests existentes se preservan; modificarlas solo se justifica
    por un cambio funcional real.
  - Limpieza de estado entre tests: p. ej. `auth_viewmodel_test.dart` y
    `flujo_completo_test.dart` arrancan deslogueados llamando `authViewModel.logout()`
    en `setUp` (seguro: el cierre local es síncrono y el remoto va con `unawaited` +
    try/catch interno).
  - Operaciones asíncronas controladas con `Completer`; para verificar que no quedan
    errores asíncronos sin gestionar se usa `runZonedGuarded`; en widget tests,
    `pumpAndSettle()` (convive con el `Timer` de 1 s del reproductor).

## Cómo correr

```bash
flutter pub get
flutter run
```
