import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/cancion.dart';

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
//
// Estado encapsulado: los campos son privados y se leen por getters de solo
// lectura; todo cambio pasa por los métodos de abajo (que notifican).
class ControladorReproduccion extends ChangeNotifier {
  // El catálogo se lee del repositorio inyectado (mismo que usa CatalogoViewModel,
  // ver lib/inyeccion.dart), así los índices de la cola siempre apuntan bien.
  ControladorReproduccion({required this._repositorioCatalogo});

  final RepositorioCatalogo _repositorioCatalogo;

  int? _indiceActual; // null = todavía no se eligió ninguna canción
  int _posicion = 0; // segundos reproducidos de la canción actual
  bool _reproduciendo = false;
  bool _pantallaCompletaAbierta =
      false; // true cuando está abierto el reproductor grande
  final Set<int> _meGustas = {}; // índices de canciones guardadas
  Timer? _timer;

  // Cola de reproducción (índices del catálogo). Vacía = todo el catálogo.
  List<int> _cola = [];
  ModoReproduccion _modo = ModoReproduccion.enOrden;
  final List<int> _historialAleatorio =
      []; // para poder volver atrás en modo aleatorio

  // Getters de solo lectura: los consumidores no pueden mutar el estado.
  int? get indiceActual => _indiceActual;
  int get posicion => _posicion;
  bool get reproduciendo => _reproduciendo;
  bool get pantallaCompletaAbierta => _pantallaCompletaAbierta;
  List<int> get cola => List.unmodifiable(_cola);
  ModoReproduccion get modo => _modo;

  bool get hayCancion => _indiceActual != null;
  Cancion? get cancion => _indiceActual == null
      ? null
      : _repositorioCatalogo.canciones[_indiceActual!];
  int get total => cancion == null ? 0 : cancion!.duracionSegundos;
  bool get leGusta =>
      _indiceActual != null && _meGustas.contains(_indiceActual);

  int get _largoCola =>
      _cola.isEmpty ? _repositorioCatalogo.canciones.length : _cola.length;

  // Posición de la canción actual dentro de la cola (0 si no está).
  int _posEnCola() {
    if (_cola.isEmpty) return _indiceActual ?? 0;
    final p = _cola.indexOf(_indiceActual!);
    return p < 0 ? 0 : p;
  }

  // Índice del catálogo que ocupa la posición pos de la cola (con wrap-around).
  int _indiceEnCola(int pos) {
    final largo = _largoCola;
    if (largo == 0) return 0;
    final p = ((pos % largo) + largo) % largo;
    return _cola.isEmpty ? p : _cola[p];
  }

  // Pone a sonar una canción. Si ya era la actual, sigue desde donde estaba.
  void reproducir(int indice) {
    _cola = []; // vuelve al modo "todo el catálogo"
    if (_indiceActual != indice) {
      _indiceActual = indice;
      _posicion = 0;
    }
    _reproduciendo = true;
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
    _cola = List.of(indices);
    if (modoNuevo != null) _modo = modoNuevo;
    _historialAleatorio.clear();
    _indiceActual =
        _cola[((inicio % _cola.length) + _cola.length) % _cola.length];
    _posicion = 0;
    _reproduciendo = true;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _avanzar());
    notifyListeners();
  }

  void _avanzar() {
    if (!_reproduciendo || !hayCancion) return;
    _posicion++;
    // Al terminar la canción: en "solo esta canción" vuelve a empezarla;
    // en los otros modos pasa a la siguiente de la cola.
    if (_posicion >= total) {
      if (_modo == ModoReproduccion.repetirUna) {
        _posicion = 0;
      } else {
        _irA(_indiceEnCola(_posEnCola() + 1));
      }
    }
    notifyListeners();
  }

  void _irA(int nuevoIndice) {
    _indiceActual = nuevoIndice;
    _posicion = 0;
  }

  void alternarPausa() {
    if (!hayCancion) return;
    _reproduciendo = !_reproduciendo;
    notifyListeners();
  }

  // Cicla entre "en orden" -> "aleatorio" -> "solo esta canción" y devuelve
  // el modo activo.
  ModoReproduccion alternarModo() {
    _modo = switch (_modo) {
      ModoReproduccion.enOrden => ModoReproduccion.aleatorio,
      ModoReproduccion.aleatorio => ModoReproduccion.repetirUna,
      ModoReproduccion.repetirUna => ModoReproduccion.enOrden,
    };
    _historialAleatorio.clear();
    notifyListeners();
    return _modo;
  }

  void siguiente() {
    if (!hayCancion) return;
    if (_modo == ModoReproduccion.aleatorio && _largoCola > 1) {
      // Elige otra canción de la cola al azar (nunca la misma dos veces seguidas).
      _historialAleatorio.add(_indiceActual!);
      var elegido = _indiceActual!;
      while (elegido == _indiceActual) {
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
    if (_modo == ModoReproduccion.aleatorio && _historialAleatorio.isNotEmpty) {
      _irA(_historialAleatorio.removeLast());
    } else if (_posicion > 3) {
      _posicion = 0;
    } else {
      _irA(_indiceEnCola(_posEnCola() - 1));
    }
    notifyListeners();
  }

  void saltarA(int segundos) {
    _posicion = segundos;
    notifyListeners();
  }

  void alternarMeGusta() {
    if (!hayCancion) return;
    if (!_meGustas.remove(_indiceActual)) _meGustas.add(_indiceActual!);
    notifyListeners();
  }

  // Lo llama el observador de navegación para ocultar el mini-player
  // mientras está abierto el reproductor grande.
  void marcarPantallaCompleta(bool abierta) {
    if (_pantallaCompletaAbierta == abierta) return;
    _pantallaCompletaAbierta = abierta;
    notifyListeners();
  }

  // Detiene todo y frena el reloj (al cerrar sesión, por ejemplo).
  void detener() {
    _reproduciendo = false;
    _indiceActual = null;
    _posicion = 0;
    _cola = [];
    _modo = ModoReproduccion.enOrden;
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
