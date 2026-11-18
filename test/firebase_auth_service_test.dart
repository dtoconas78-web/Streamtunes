import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/services/firebase_auth_service.dart';

// Prueba el cierre de sesión de FirebaseAuthService sin tocar Firebase/Google
// reales: se sobreescriben signOutGoogle/signOutFirebase (los seams de prueba)
// para simular cada combinación de fallos.
class _CierreControlado extends FirebaseAuthService {
  _CierreControlado({this.fallaGoogle = false, this.fallaFirebase = false});

  final bool fallaGoogle;
  final bool fallaFirebase;
  int llamadasGoogle = 0;
  int llamadasFirebase = 0;

  @override
  Future<void> signOutGoogle() async {
    llamadasGoogle++;
    if (fallaGoogle) throw StateError('google caído');
  }

  @override
  Future<void> signOutFirebase() async {
    llamadasFirebase++;
    if (fallaFirebase) throw StateError('firebase caído');
  }
}

void main() {
  test('sin fallos: ambas operaciones se ejecutan y no hay error', () async {
    final s = _CierreControlado();
    await s.cerrarSesion();
    expect(s.llamadasGoogle, 1);
    expect(s.llamadasFirebase, 1);
  });

  test('falla solo Google: Firebase se intenta igual y NO se lanza (solo se diagnostica)', () async {
    final s = _CierreControlado(fallaGoogle: true);
    await s.cerrarSesion(); // no debe lanzar
    expect(s.llamadasGoogle, 1);
    expect(s.llamadasFirebase, 1);
  });

  test(
    'falla solo Firebase: Google se intentó igualmente y el fallo se comunica',
    () async {
      final s = _CierreControlado(fallaFirebase: true);
      await expectLater(s.cerrarSesion(), throwsA(isA<StateError>()));
      expect(s.llamadasGoogle, 1);
      expect(s.llamadasFirebase, 1);
    },
  );

  test(
    'fallan ambas: ambas se intentan y el error menciona los dos fallos',
    () async {
      final s = _CierreControlado(fallaGoogle: true, fallaFirebase: true);
      await expectLater(
        s.cerrarSesion(),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('Firebase') &&
                e.toString().contains('Google'),
          ),
        ),
      );
      expect(s.llamadasGoogle, 1);
      expect(s.llamadasFirebase, 1);
    },
  );
}
