# StreamTunes

App móvil (Flutter) para escuchar música gratis, pensada para artistas "under".

## La idea

- **Escuchar es gratis, siempre.** No hay suscripciones ni paywall: si está en
  StreamTunes, se puede escuchar gratis.
- **La diferencia es el apoyo directo al artista.** La plata entra por:
  - Donaciones directas al artista.
  - Conciertos publicados por el artista (ver concierto, comprar entrada).
  - El artista ve sus **ventas y donaciones** desde su perfil.
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
├── data/                → contratos Repositorio* + implementaciones *Memoria/*Firestore/*Preferencias (guardado local)
│   └── services/        → semilla datos_ejemplo.dart
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
  - Guardado local: playlists, seguidos y "me gusta" se guardan en el celular con
    `shared_preferences` (repositorios `*Preferencias`, una clave por uid). Si
    `inicializarPersistenciaLocal()` no corrió (tests) quedan en memoria. Son por
    usuario: al cerrar sesión o como invitado quedan vacíos y no se guarda nada.
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
  Actualmente: analyze sin issues y **56 tests aprobados**.
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
