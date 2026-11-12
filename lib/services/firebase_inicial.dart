import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/firebase_options.dart';

/// true cuando Firebase se inicializó bien (proyecto configurado con valores
/// reales y plataforma soportada: Android/iOS/web/macOS). Si es false, la app
/// arranca en "modo demo": auth simulado y datos de ejemplo, y los tests no
/// tocan Firebase.
bool firebaseInicializado = false;

/// Inicializa Firebase al arrancar la app. Si falla (todavía no se corrió
/// `flutterfire configure`, plataforma sin soporte como Windows/Linux, o
/// sin red), la app sigue en modo demo sin romperse.
Future<void> inicializarFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInicializado = true;
    debugPrint('Firebase OK (proyecto: ${Firebase.app().options.projectId})');
  } catch (e) {
    firebaseInicializado = false;
    debugPrint('Firebase no disponible ($e) -> modo demo (auth simulado)');
  }
}
