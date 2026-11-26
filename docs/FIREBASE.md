# Firebase en StreamTunes — hoja de ruta

StreamTunes usa Firebase como backend (plan Spark, gratis para empezar):

| Producto | Para qué |
|---|---|
| **Firebase Auth + Google Sign-In** | login/registro con cuenta de Google (y email/clave) |
| **Cloud Firestore** | metadatos: usuarios (rol, perfil), catálogo (canciones/álbumes), playlists, seguimientos, donaciones/ventas, conciertos y entradas |
| **Cloud Storage** | archivos binarios: audio de las canciones, fotos de perfil, portadas de álbumes |

## Estado actual (Paso 1 — código listo, falta configurar el proyecto)

Ya está en la rama `feature/login-registro-invitado`:

- Dependencias: `firebase_core`, `firebase_auth`, `google_sign_in` (pubspec.yaml).
- `lib/firebase_options.dart`: **plantilla con placeholders**.
- `lib/main.dart` inicializa Firebase al arrancar (`inicializarFirebase()`).
- `lib/services/firebase_auth_service.dart`: login real con Google
  (`GoogleSignIn.instance.authenticate()` → credential → `FirebaseAuth.signInWithCredential`),
  email/clave y registro. El `AuthViewModel` elige solo: si Firebase está
  inicializado usa el servicio real; si no, el simulado (modo demo).
- Los tests nunca tocan Firebase (no se inicializa) y siguen en verde.

### Estado del Paso 1: ✅ HECHO

- App Android `com.example.streamtunes_demo` agregada en la consola; **Google
  habilitado** en Authentication; **SHA-1/SHA-256 de debug cargadas** (están solo
  en local: `docs/local/claves-firebase.md`, gitignored).
- `android/app/google-services.json` descargado y guardado en esa ruta
  (**gitignored**). Validado con Gradle: `./gradlew :app:processDebugGoogleServices` → OK.
  > ⚠️ **Importante**: después de agregar las huellas SHA en la consola, hay que
  > **volver a descargar `google-services.json`**: el nuevo archivo trae el OAuth
  > client de Android (`client_type: 1` con tu `certificate_hash`), que es el que
  > `google_sign_in` usa para el login en Android. Sin esa entrada el login con
  > Google falla aunque la SHA esté cargada en la consola.
- Plugin `com.google.gms.google-services` **4.5.0** en `android/settings.gradle.kts`
  y aplicado en `android/app/build.gradle.kts`.
- `lib/firebase_options.dart` con los **valores reales de Android** cargados desde
  el json (apiKey, appId `1:402504152041:android:49c2533fde4fcfa3a51178`,
  sender `402504152041`, project `streamtunes-itu`, bucket
  `streamtunes-itu.firebasestorage.app`). Como el repo es público, ese archivo
  quedó en **skip-worktree** (`git update-index --skip-worktree
  lib/firebase_options.dart`): el repo solo guarda la plantilla con placeholders
  y la apiKey real nunca se commitea. Para ver el estado real:
  `git ls-files -v lib/firebase_options.dart` (la `S` marca skip-worktree).

### Para probar el login con Google real

Correr en **Android (emulador o dispositivo) o web**:

```powershell
flutter run
```

En Windows/Linux de escritorio `firebase_auth`/`google_sign_in` no tienen
soporte: ahí la app arranca sola en **modo demo** (auth simulado), sin romperse.

### Cómo se comporta la app

- Con Firebase configurado: login con Google real; el `Usuario` mapea `uid`,
  `displayName`, `email` y `photoURL` (la foto se usa después para el perfil).
- Sin Firebase (tests, Windows, sin configurar): auth simulado, datos de ejemplo.
- El **rol (artista/oyente) no lo da Google**: la app lo elige antes de llamar
  (ver `elegir_rol.dart`). En el paso 3 se guarda en Firestore al primer login
  para restaurar la sesión.

## Paso 2 — Cloud Firestore (metadatos) — EN CURSO

Dependencia: `cloud_firestore` (ya agregada en `feature/streams-eventos-sistema`).
Firestore guarda **sólo metadatos y estructuras de datos**, nunca archivos
binarios (audio de canciones, portadas, fotos van a Storage, paso 3).

Colecciones raíz efectivas y campos:

```
canciones/{id}     { titulo, duracionSegundos, reproducciones, tendencia, lugar, horarioPico, colorPortada, genero, descripcion, publica }
albumes/{id}       { titulo, anio, colorPortada, cancionIds }
artistas/{id}      { nombre }
conciertos/{id}    { nombre, lugar, fecha (Timestamp), precio, disponibles }
entradas/{id}      { concierto, conciertoId, lugar, fecha, precio, cantidad, usuarioId }
movimientos/{id}   { tipo: venta|donacion, detalle, monto, fecha, usuarioId }
```

- `usuarioId` = uid de Firebase Auth del usuario que origina el registro
  (comprador de la entrada / donante). `conciertoId` vincula cada entrada al
  documento de su concierto en `conciertos`.
- Semilla automática e idempotente al iniciar con Firebase: solo puebla
  colecciones vacías (`count == 0`) con ids determinísticos
  (`concierto-N`, `entrada-N`, `movimiento-N`, …), reutilizando
  `lib/data/services/datos_ejemplo.dart`.

### Bloque A (6.1–6.4) — ✅ HECHO (commit `fe1500b`)

- Modelos serializables (`toMap`/`fromMap`, fechas como `Timestamp`).
- Contratos de repositorio observables (`ChangeNotifier`).
- `FuenteFirestore` (abstracción testeable) + semilla idempotente.
- Repositorios de catálogo y artistas con snapshots en tiempo real.

### Bloque B (6.5–6.7) — ✅ IMPLEMENTADO

- **Compra atómica:** una única `runTransaction` en
  `RepositorioEntradasFirestore.descontarDisponiblesAsync` lee el concierto,
  valida (existe, cantidad > 0, stock suficiente) y escribe en el mismo
  commit el stock descontado + la entrada + el movimiento. Si falla una
  validación, no se escribe nada: nunca hay stock descontado sin entrada y
  movimiento.
- **Ids estables e idempotencia:** los ids de entrada y movimiento se generan
  ANTES de la transacción (`generarId`, o derivados de `operacionId`), así
  sobreviven a los reintentos de Firestore. Con `operacionId`, si ambos
  documentos (`entrada-$operacionId`, `movimiento-$operacionId`) ya existen la
  operación no se repite; si existe solo uno, se rechaza por inconsistente.
- **Streams reactivos:** conciertos (todos), entradas y movimientos filtrados
  por `usuarioId`; sin sesión válida la lista queda vacía. Los ViewModels se
  suscriben a los repositorios (`addListener` en constructor, `removeListener`
  en `dispose`) y reemiten sin duplicar notificaciones.
- **Selección por inyección:** `lib/inyeccion.dart` elige Firestore solo con
  `firebaseInicializado`; sin Firebase todo queda en memoria. Los ViewModels
  deciden el flujo por la capacidad declarada `soportaCompraAtomica` del
  contrato, nunca por clases concretas de Firestore. El uid se resuelve de
  forma diferida (`authViewModel.usuario?.id`, descartando invitados: su id
  local `invitado_N` no es un uid de Firebase).
- Playlists, seguidos (artistas y álbumes) y "me gusta" NO están en Firestore:
  tienen contrato propio (`RepositorioPlaylists`, `RepositorioSeguimiento`) con
  implementación en memoria y guardado local en el celular con
  `shared_preferences` (una clave JSON por uid, ver
  `lib/services/persistencia_local.dart`). Una versión Firestore se agrega
  implementando esos mismos contratos; `usuarios/{uid}` queda para el paso de
  perfil.

### Reglas de seguridad — riesgo documentado (sin cambios en esta etapa)

Las reglas actuales son lectura pública / escritura con `request.auth != null`.
**Ojo:** un usuario autenticado ANÓNIMAMENTE también tiene uid y cumple esa
condición, así que hoy también puede escribir. No se tocan las reglas en este
paso; endurecerlas por uid (distinguir registrado vs. anónimo) queda para una
etapa posterior.

## Paso 3 — Cloud Storage (archivos) — POSTERIOR

**Queda pospuesto porque requiere habilitar el plan de facturación (Blaze) en
el proyecto Firebase.** Cuando esté habilitado, dependencia `firebase_storage`;
estructura propuesta del bucket:

```
/canciones/{cancionId}.mp3        audio subido por el artista
/portadas/albumes/{albumId}.jpg   portada del álbum
/perfiles/{uid}.jpg               foto de perfil del usuario
```

Reglas de seguridad propuestas: lectura pública de canciones/portadas;
escritura solo por el dueño (artista verificado para subir música, usuario
para su foto).

Mientras tanto, la app guarda todo lo que no es binario en Firestore: con
Firebase inicializado, los repositorios Firestore reemplazan la memoria
(`lib/data/services/datos_ejemplo.dart`); sin Firebase (tests, demo, Windows/Linux), todo sigue
en memoria y las pantallas no cambian (igual que se hizo con el auth).
