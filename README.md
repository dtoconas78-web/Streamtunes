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
- Por ahora no hay backend: los datos y los logins externos (Google) son **simulados**
  con la misma capa de servicio, lista para conectar la API real después
  (ver `docs/AUTH_GOOGLE.md`). Apple Sign-In queda fuera por ahora: el desarrollo
  es Android-first.
- UX: nada ambiguo. Cualquier acción bloqueada para invitados dice claramente
  "registrate para…" y lleva al registro.

## Estructura actual

```
lib/
├── main.dart            → runApp
├── navigation/          → navegador global, abrir reproductor, cerrar sesión
├── models/              → Usuario, Cancion, Album, Concierto, Entrada, Movimiento
├── data/                → datos de ejemplo (hasta conectar backend)
├── services/            → auth simulado (listo para Firebase/Google real)
├── viewmodels/          → ChangeNotifiers globales (auth, reproductor, perfil, …)
├── views/screens/       → pantallas
├── views/widgets/       → mini reproductor, botón principal, diálogo de registro
├── theme/ + utils/      → colores, constantes, validadores, formatos
```

## Cómo correr

```bash
flutter pub get
flutter run
```
