# StreamTunes

Demo de una app para artistas independientes: perfil del artista,
estadísticas de cada canción y edición de perfil. Por ahora es solo
front, sin lógica real ni conexión a un servidor.

## Cómo correrla

```
flutter pub get
flutter run
```

## Cómo correr las pruebas

```
flutter test
```

## Organización

Por ahora todo el código está en `lib/main.dart`. Pantallas:

- Perfil del artista (banner, botón Seguir, tabs y lista de canciones)
- Estadísticas de la canción (métricas y reproducciones en vivo)
- Editar perfil

El logotipo está en `assets/images/`.

## Convenciones

**Idioma:** español para el dominio (Cancion, reproducciones, seguir) e
inglés para lo que viene de Flutter (build, Widget, Screen).

**Nombres de las piezas de cada pantalla:**

- Pantallas: `<Funcionalidad>Screen` (ej.: `PerfilArtistaScreen`)
- ViewModels: `<Funcionalidad>ViewModel`
- Repositorios: `<Dato>Repository`
- Archivos: `snake_case`, uno por clase (ej.: `perfil_artista_screen.dart`)

(Se aplican de ahora en adelante; las pantallas actuales todavía se llaman
`PantallaA`, `PantallaB` y `PantallaC`.)

**Verbos para las acciones comunes:**

- `cargar`: traer datos (cargarCanciones)
- `guardar`: guardar cambios (guardarPerfil)
- `seguir` / `dejarDeSeguir`: seguir a un artista
- `compartir`: compartir una canción

**Booleanos:** en positivo y como pregunta (`estaSiguiendo`, `tieneCanciones`).

**Antes de cada entrega:**

```
dart format .
flutter analyze
flutter test
```
