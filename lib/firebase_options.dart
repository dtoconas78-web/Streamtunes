// ---------------------------------------------------------------------------
// Configuración de Firebase para StreamTunes.
//
// ESTE ARCHIVO ES UNA PLANTILLA CON PLACEHOLDERS. Para generar los valores
// reales del proyecto "streamtunes-itu" ejecutá en la raíz del proyecto:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=streamtunes-itu
//
// Ese comando SOBRESCRIBE este archivo con lib/firebase_options.dart real
// (apiKey, appId, projectId, etc. de cada plataforma) y agrega
// android/app/google-services.json. Hasta entonces la app arranca en
// "modo demo": Firebase no se inicializa y se usa el auth simulado.
// ---------------------------------------------------------------------------

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return linux;
    }
  }

  // TODO(firebase): reemplazar por los valores reales de flutterfire configure.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY_ANDROID',
    appId: 'REEMPLAZAR_APP_ID_ANDROID',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'streamtunes-itu',
    storageBucket: 'streamtunes-itu.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY_IOS',
    appId: 'REEMPLAZAR_APP_ID_IOS',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'streamtunes-itu',
    storageBucket: 'streamtunes-itu.appspot.com',
    iosBundleId: 'com.example.streamtunesDemo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY_MACOS',
    appId: 'REEMPLAZAR_APP_ID_MACOS',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'streamtunes-itu',
    storageBucket: 'streamtunes-itu.appspot.com',
    iosBundleId: 'com.example.streamtunesDemo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY_WEB',
    appId: 'REEMPLAZAR_APP_ID_WEB',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'streamtunes-itu',
    storageBucket: 'streamtunes-itu.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REEMPLAZAR_API_KEY_WEB',
    appId: 'REEMPLAZAR_APP_ID_WEB',
    messagingSenderId: 'REEMPLAZAR_SENDER_ID',
    projectId: 'streamtunes-itu',
    storageBucket: 'streamtunes-itu.appspot.com',
  );
}
