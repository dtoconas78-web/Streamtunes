import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

// Cómo se recorre la cola: en orden, aleatorio o repitiendo solo la canción
// elegida.
enum ModoReproduccion { enOrden, aleatorio, repetirUna }

extension ModoReproduccionEtiqueta on ModoReproduccion {
  String get etiqueta => switch (this) {
    ModoReproduccion.enOrden => 'En orden',
    ModoReproduccion.aleatorio => 'Aleatoria',
    ModoReproduccion.repetirUna => 'Solo esta canción',
  };
  IconData get icono => switch (this) {
    ModoReproduccion.enOrden => Icons.repeat,
    ModoReproduccion.aleatorio => Icons.shuffle,
    ModoReproduccion.repetirUna => Icons.repeat_one,
  };
}

// Controlador de reproducción: guarda qué suena, en qué segundo y si está en pausa.
// Vive fuera de las pantallas, por eso la música sigue al navegar.
// Cuando se conecte audio real (just_audio), solo hay que tocar esta clase.
class ControladorReproduccion extends ChangeNotifier {
  int? indiceActual; // null = todavía no se eligió ninguna canción
  int posicion = 0; // segundos reproducidos de la canción actual
  bool reproduciendo = false;
  bool pantallaCompletaAbierta =
      false; // true cuando está abierto el reproductor grande
  final Set<int> meGustas = {}; // índices de canciones guardadas
  Timer? _timer;

  // Cola de reproducción (índices del catálogo). Vacía = todo el catálogo.
  List<int> cola = [];
  ModoReproduccion modo = ModoReproduccion.enOrden;
  final List<int> _historialAleatorio =
      []; // para poder volver atrás en modo aleatorio

  bool get hayCancion => indiceActual != null;
  Cancion? get cancion =>
      indiceActual == null ? null : catalogo.canciones[indiceActual!];
  int get total => cancion == null ? 0 : cancion!.duracionSegundos;
  bool get leGusta => indiceActual != null && meGustas.contains(indiceActual);

  int get _largoCola => cola.isEmpty ? catalogo.canciones.length : cola.length;

  // Posición de la canción actual dentro de la cola (0 si no está).
  int _posEnCola() {
    if (cola.isEmpty) return indiceActual ?? 0;
    final p = cola.indexOf(indiceActual!);
    return p < 0 ? 0 : p;
  }

  // Índice del catálogo que ocupa la posición pos de la cola (con wrap-around).
  int _indiceEnCola(int pos) {
    final largo = _largoCola;
    if (largo == 0) return 0;
    final p = ((pos % largo) + largo) % largo;
    return cola.isEmpty ? p : cola[p];
  }

  // Pone a sonar una canción. Si ya era la actual, sigue desde donde estaba.
  void reproducir(int indice) {
    cola = []; // vuelve al modo "todo el catálogo"
    if (indiceActual != indice) {
      indiceActual = indice;
      posicion = 0;
    }
    reproduciendo = true;
    // El reloj se crea una sola vez y avanza cada segundo mientras suena.
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _avanzar());
    notifyListeners();
  }

  // Reproduce una cola (por ejemplo una playlist) desde la posición inicio.
  void reproducirCola(
    List<int> indices, {
    ModoReproduccion? modoNuevo,
    int inicio = 0,
  }) {
    if (indices.isEmpty) return;
    cola = List.of(indices);
    if (modoNuevo != null) modo = modoNuevo;
    _historialAleatorio.clear();
    indiceActual = cola[((inicio % cola.length) + cola.length) % cola.length];
    posicion = 0;
    reproduciendo = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _avanzar());
    notifyListeners();
  }

  void _avanzar() {
    if (!reproduciendo || !hayCancion) return;
    posicion++;
    // Al terminar la canción: en "solo esta canción" vuelve a empezarla;
    // en los otros modos pasa a la siguiente de la cola.
    if (posicion >= total) {
      if (modo == ModoReproduccion.repetirUna) {
        posicion = 0;
      } else {
        _irA(_indiceEnCola(_posEnCola() + 1));
      }
    }
    notifyListeners();
  }

  void _irA(int nuevoIndice) {
    indiceActual = nuevoIndice;
    posicion = 0;
  }

  void alternarPausa() {
    if (!hayCancion) return;
    reproduciendo = !reproduciendo;
    notifyListeners();
  }

  // Cicla entre "en orden" -> "aleatorio" -> "solo esta canción" y devuelve
  // el modo activo.
  ModoReproduccion alternarModo() {
    modo = switch (modo) {
      ModoReproduccion.enOrden => ModoReproduccion.aleatorio,
      ModoReproduccion.aleatorio => ModoReproduccion.repetirUna,
      ModoReproduccion.repetirUna => ModoReproduccion.enOrden,
    };
    _historialAleatorio.clear();
    notifyListeners();
    return modo;
  }

  void siguiente() {
    if (!hayCancion) return;
    if (modo == ModoReproduccion.aleatorio && _largoCola > 1) {
      // Elige otra canción de la cola al azar (nunca la misma dos veces seguidas).
      _historialAleatorio.add(indiceActual!);
      var elegido = indiceActual!;
      while (elegido == indiceActual) {
        elegido = _indiceEnCola(Random().nextInt(_largoCola));
      }
      _irA(elegido);
    } else {
      _irA(_indiceEnCola(_posEnCola() + 1));
    }
    notifyListeners();
  }

  // Si ya pasaron más de 3 segundos, "anterior" vuelve al inicio de la misma
  // canción; si no, va a la anterior (en aleatorio, a la que sonó antes).
  void anterior() {
    if (!hayCancion) return;
    if (modo == ModoReproduccion.aleatorio && _historialAleatorio.isNotEmpty) {
      _irA(_historialAleatorio.removeLast());
    } else if (posicion > 3) {
      posicion = 0;
    } else {
      _irA(_indiceEnCola(_posEnCola() - 1));
    }
    notifyListeners();
  }

  void saltarA(int segundos) {
    posicion = segundos;
    notifyListeners();
  }

  void alternarMeGusta() {
    if (!hayCancion) return;
    if (!meGustas.remove(indiceActual)) meGustas.add(indiceActual!);
    notifyListeners();
  }

  // Lo llama el observador de navegación para ocultar el mini-player
  // mientras está abierto el reproductor grande.
  void marcarPantallaCompleta(bool abierta) {
    if (pantallaCompletaAbierta == abierta) return;
    pantallaCompletaAbierta = abierta;
    notifyListeners();
  }

  // Detiene todo y frena el reloj (al cerrar sesión, por ejemplo).
  void detener() {
    reproduciendo = false;
    indiceActual = null;
    posicion = 0;
    cola = [];
    modo = ModoReproduccion.enOrden;
    _historialAleatorio.clear();
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Una única instancia compartida por toda la app.
final ControladorReproduccion reproductor = ControladorReproduccion();
