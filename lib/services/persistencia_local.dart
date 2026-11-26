import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guardado local en el celular (shared_preferences), con el mismo criterio
/// que `firebaseInicializado`: si main() logró abrirlo, inyeccion.dart usa
/// los repositorios *Preferencias; si no (tests, o falla el plugin), quedan
/// los *Memoria y la app sigue funcionando sin guardar.
SharedPreferences? preferenciasLocales;

/// Abre shared_preferences UNA vez al arrancar (antes de runApp). Nunca
/// lanza: ante un error la app sigue sin guardado local.
Future<void> inicializarPersistenciaLocal() async {
  try {
    preferenciasLocales = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Sin guardado local (se usa memoria): $e');
  }
}
