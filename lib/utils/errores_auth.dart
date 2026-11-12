import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Convierte la excepción real de Firebase/Google en un mensaje en español que
// incluye el código de error: así cuando falla el login se ve la causa real
// (proveedor no habilitado, SHA mal cargada, sin Play Services, etc.) en vez
// de un "Probá de nuevo" genérico. Ver docs/FIREBASE.md (diagnóstico Paso 1).
String descripcionErrorAuth(Object e) {
  if (e is FirebaseAuthException) {
    final msg = switch (e.code) {
      'operation-not-allowed' =>
        'El método de ingreso no está habilitado en Firebase Console '
            '(Authentication → Sign-in method → habilitar Google/email).',
      'email-already-in-use' => 'Ese email ya tiene una cuenta.',
      'invalid-email' => 'El email no es válido.',
      'weak-password' => 'La contraseña es muy débil (mínimo 6 caracteres).',
      'user-not-found' => 'No hay ninguna cuenta con ese email.',
      'wrong-password' => 'La contraseña es incorrecta.',
      'invalid-credential' => 'Email o contraseña incorrectos.',
      'user-disabled' => 'Esa cuenta fue deshabilitada.',
      'network-request-failed' =>
        'Sin conexión: revisá la red del emulador/dispositivo.',
      'too-many-requests' => 'Demasiados intentos: esperá un rato.',
      _ => null,
    };
    return '${msg ?? 'Error de Firebase'} (código: ${e.code})';
  }
  if (e is GoogleSignInException) {
    final msg = switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Cancelaste el ingreso con Google.',
      GoogleSignInExceptionCode.interrupted =>
        'El ingreso con Google se interrumpió. Probá de nuevo.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google rechazó la configuración: verificá en Firebase Console que el '
            'proveedor Google esté habilitado y que la huella SHA-1/SHA-256 de esta '
            'build esté agregada (y re-descargado google-services.json).',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'La app está mal configurada para Google Sign-In (revisar '
            'google-services.json y package name).',
      GoogleSignInExceptionCode.uiUnavailable =>
        'No se pudo mostrar la ventana de Google (¿emulador sin Google Play '
            'o sin cuenta agregada?).',
      GoogleSignInExceptionCode.userMismatch =>
        'La cuenta seleccionada no coincide con la sesión actual.',
      _ => null,
    };
    final detalle = e.description ?? e.details?.toString();
    return '${msg ?? 'Error de Google Sign-In'}${detalle != null ? ' — $detalle' : ''} '
        '(código: ${e.code})';
  }
  return 'Error inesperado: $e';
}
