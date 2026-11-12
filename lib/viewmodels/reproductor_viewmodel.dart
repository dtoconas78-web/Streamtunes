import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

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

  bool get hayCancion => indiceActual != null;
  Cancion? get cancion =>
      indiceActual == null ? null : catalogo.canciones[indiceActual!];
  int get total => cancion == null ? 0 : cancion!.duracionSegundos;
  bool get leGusta => indiceActual != null && meGustas.contains(indiceActual);

  // Pone a sonar una canción. Si ya era la actual, sigue desde donde estaba.
  void reproducir(int indice) {
    if (indiceActual != indice) {
      indiceActual = indice;
      posicion = 0;
    }
    reproduciendo = true;
    // El reloj se crea una sola vez y avanza cada segundo mientras suena.
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _avanzar());
    notifyListeners();
  }

  void _avanzar() {
    if (!reproduciendo || !hayCancion) return;
    posicion++;
    // Al terminar la canción, pasa a la siguiente.
    if (posicion >= total) {
      _irA((indiceActual! + 1) % catalogo.canciones.length);
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

  void siguiente() {
    if (!hayCancion) return;
    _irA((indiceActual! + 1) % catalogo.canciones.length);
    notifyListeners();
  }

  // Si ya pasaron más de 3 segundos, "anterior" vuelve al inicio de la misma
  // canción; si no, va a la anterior (como en la mayoría de los reproductores).
  void anterior() {
    if (!hayCancion) return;
    if (posicion > 3) {
      posicion = 0;
    } else {
      _irA(
        (indiceActual! - 1 + catalogo.canciones.length) %
            catalogo.canciones.length,
      );
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
