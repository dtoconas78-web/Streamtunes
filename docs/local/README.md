# Carpeta local (NO se commitea el contenido sensible)

Acá se guardan claves y datos de Firebase **solo de esta máquina**, porque el
repositorio es público:

- `claves-firebase.md` (gitignored): SHA-1/SHA-256 del keystore de debug y de
  release. Se copian a mano en Firebase Console → Settings de la app Android →
  "Agregar huella digital". **Nunca commitear este archivo.**
- `android/app/google-services.json` también está gitignored: cada persona lo
  descarga de la Firebase Console (o lo genera `flutterfire configure`).

Para obtener las claves de nuevo (desde la carpeta `android/`):

```powershell
./gradlew signingReport
```

O con keytool directo:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

> Ojo: después de correr `flutterfire configure`, el `lib/firebase_options.dart`
> real (con apiKey) queda pisado localmente. **No commitear esa versión real**:
> el repo guarda la plantilla con placeholders. Para no subirla por accidente:
> `git update-index --skip-worktree lib/firebase_options.dart`.
