# Login con Google (Android) — guía original

> **Actualizado**: esta guía quedó reemplazada por **docs/FIREBASE.md**, que es
> la hoja de ruta completa de Firebase (Auth + Google ya implementado en código
> como `FirebaseAuthService`; falta correr `flutterfire configure` y habilitar
> Google en la consola). Lo de abajo se conserva como referencia histórica del
> flujo paso a paso.

Hoy `lib/services/auth_service.dart` **simula** el login con Google (modo demo,
cuando Firebase no está inicializado). Con Firebase activo se usa
`lib/services/firebase_auth_service.dart` (mismo contrato).

> Apple Sign-In quedó **descartado** por ahora: el desarrollo es Android-first.
> Ojo: si después se publica en iOS y la app ofrece login con Google, Apple
> obliga a incluir también "Sign in with Apple".

## 1) Proyecto en Firebase Console

1. Crear proyecto en https://console.firebase.google.com
2. Agregar app **Android** con el package name de la app:
   `com.example.streamtunes_demo` (ver `android/app/build.gradle.kts` → `applicationId`).
3. Descargar `google-services.json` y copiarlo a `android/app/google-services.json`.
4. En **Authentication → Sign-in method** habilitar **Google**.

## 2) Registrar la huella digital (SHA) del keystore

Firebase exige la SHA-1 (y conviene la SHA-256) del keystore con el que se firma la app.

Keystore de debug (el que se usa en desarrollo), en PowerShell:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copiar **SHA-1** y **SHA-256** → Firebase Console → Settings de la app Android →
"Agregar huella digital". Para release se repite con el keystore de producción.

## 3) Dependencias

```bash
flutter pub add firebase_core firebase_auth google_sign_in
```

## 4) Configurar Gradle (proyecto Android)

- `android/build.gradle.kts` (nivel raíz), en `plugins`/`buildscript` agregar:
  `com.google.gms:google-services:4.4.2`
- `android/app/build.gradle.kts`, aplicar el plugin:
  ```kotlin
  plugins {
      // ...
      id("com.google.gms.google-services")
  }
  ```

## 5) Inicializar Firebase al arrancar

`lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // lee google-services.json en Android
  runApp(const MiApp());
}
```

## 6) Flujo real dentro de `AuthService.ingresarConGoogle()`

Con `google_sign_in` v7+ (la API actual; en v6 era `GoogleSignIn().signIn()`):

```dart
Future<Usuario> ingresarConGoogle({required RolUsuario rol}) async {
  // 1. Abre el selector de cuentas de Google del dispositivo.
  final googleUser = await GoogleSignIn.instance.authenticate();

  // 2. Con el token de Google se arma el credential de Firebase.
  final googleAuth = googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: googleAuth.accessToken, // en v7 accessToken puede venir en otra propiedad; verificar según versión instalada
  );

  // 3. Login en Firebase Auth.
  final cred = await FirebaseAuth.instance.signInWithCredential(credential);
  final fbUser = cred.user!;

  // 4. Mapear al modelo de la app. Ojo: el rol NO lo da Google; la app lo eligió
  //    antes de llamar (ver PantallaAcceso). Si es la primera vez, guardar el
  //    perfil (nombre, rol) en Firestore.
  return Usuario(
    id: fbUser.uid,
    nombre: fbUser.displayName ?? 'Usuario de Google',
    email: fbUser.email ?? '',
    rol: rol,
    fotoUrl: fbUser.photoURL,
  );
}
```

Puntos a verificar según la versión que instale `flutter pub add`:
- En `google_sign_in` v7+, `accessToken` se obtiene con
  `googleUser.authorizationClient.authorizationForScopes([...])` o ya no se expone
  igual; para login básico con Firebase alcanza con `idToken`.
- En Android no hace falta `clientId` en `GoogleSignIn.instance.initialize(...)`
  porque se lee de `google-services.json`. En web/iOS sí se necesita
  (`serverClientId` / `clientId`).

## 7) Manejo de errores típico

- `SignInException` / cancelación del usuario → mostrar "Login cancelado", no crashear.
- `firebase_auth/account-exists-with-different-credential` → vincular proveedores.
- Siempre chequear `FirebaseAuth.instance.currentUser` al iniciar la app para
  restaurar la sesión sin pedir login de nuevo.
