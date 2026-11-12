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

### Lo que falta hacer VOS en la Firebase Console (proyecto `streamtunes-itu`)

1. **Agregar la app Android** con package name `com.example.streamtunes_demo`
   (ver `android/app/build.gradle.kts` → `applicationId`).
2. **Authentication → Sign-in method → habilitar Google**.
3. **Huellas SHA**: en PowerShell
   ```powershell
   keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
   Copiar SHA-1 y SHA-256 en Settings de la app Android → "Agregar huella digital".
4. **Vincular el proyecto con el código** (genera `lib/firebase_options.dart` real
   y `android/app/google-services.json` + el plugin de Gradle):
   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure --project=streamtunes-itu
   ```
   > Si no podés correr `flutterfire`, pasame los valores de la app
   > (apiKey, appId, messagingSenderId, projectId, storageBucket) y los cargo
   > yo en `lib/firebase_options.dart`.
5. Correr la app en **Android (emulador/dispositivo) o web** — en Windows/Linux
   de escritorio `firebase_auth`/`google_sign_in` no tienen soporte, así que ahí
   la app arranca sola en modo demo (auth simulado), sin romperse.

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
