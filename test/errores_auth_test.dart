import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:streamtunes_demo/utils/errores_auth.dart';

// Conservación de los mensajes específicos de autenticación: el VM guarda el
// error crudo y la vista lo traduce con descripcionErrorAuth; estos tests fijan
// que los códigos de Firebase/Google sigan produciendo su mensaje exacto.
void main() {
  test('FirebaseAuthException wrong-password conserva mensaje y código', () {
    final msg = descripcionErrorAuth(
      FirebaseAuthException(code: 'wrong-password'),
    );
    expect(msg, contains('La contraseña es incorrecta'));
    expect(msg, contains('wrong-password'));
  });

  test('FirebaseAuthException network-request-failed menciona la red', () {
    final msg = descripcionErrorAuth(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    expect(msg, contains('Sin conexión'));
    expect(msg, contains('network-request-failed'));
  });

  test(
    'código de Firebase desconocido cae en el genérico pero muestra el código',
    () {
      final msg = descripcionErrorAuth(
        FirebaseAuthException(code: 'codigo-raro'),
      );
      expect(msg, contains('Error de Firebase'));
      expect(msg, contains('codigo-raro'));
    },
  );

  test('GoogleSignInException cancelado conserva su mensaje', () {
    final msg = descripcionErrorAuth(
      GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );
    expect(msg, contains('Cancelaste el ingreso con Google'));
  });

  test('error genérico de otro tipo', () {
    final msg = descripcionErrorAuth(StateError('boom'));
    expect(msg, contains('Error inesperado'));
    expect(msg, contains('boom'));
  });
}
