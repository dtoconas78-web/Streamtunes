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

## Paso 2 — Cloud Storage (archivos) — PRÓXIMO

Dependencia: `firebase_storage`. Estructura propuesta del bucket:

```
/canciones/{cancionId}.mp3        audio subido por el artista
/portadas/albumes/{albumId}.jpg   portada del álbum
/perfiles/{uid}.jpg               foto de perfil del usuario
```

Reglas de seguridad: lectura pública de canciones/portadas; escritura solo
por el dueño (artista verificado para subir música, usuario para su foto).

## Paso 3 — Cloud Firestore (metadatos) — DESPUÉS

Dependencia: `cloud_firestore`. Colecciones propuestas:

```
usuarios/{uid}        { nombre, email, rol, fotoUrl, verificado, creadoEn }
canciones/{id}        { titulo, artistaId, albumId, duracionSegundos, storagePath, reproducciones }
albumes/{id}          { titulo, artistaId, anio, portadaUrl, cancionIds }
playlists/{id}        { duenoId, nombre, cancionIds }
seguidores/{uid}/artistasSeguidos/{artistaId}
seguidores/{uid}/albumesSeguidos/{albumId}
movimientos/{id}      { tipo: donacion|venta, usuarioId, artistaId, monto, fecha, detalle }
conciertos/{id}       { artistaId, nombre, lugar, fecha, precio, disponibles }
entradas/{id}         { conciertoId, usuarioId, cantidad, fechaCompra }
```

La app hoy guarda todo en viewmodels en memoria (`datos_ejemplo.dart`); en este
paso se reemplaza el interior de esos viewmodels por llamadas a Firestore sin
tocar las pantallas (igual que se hizo con el auth).
