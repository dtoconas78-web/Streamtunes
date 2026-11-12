import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';

void main() {
  setUp(() => authViewModel.logout());

  test('entrar como invitado: solo escucha, no es registrado', () async {
    await authViewModel.entrarComoInvitado();
    expect(authViewModel.estaLogueado, isTrue);
    expect(authViewModel.esInvitado, isTrue);
    expect(authViewModel.esRegistrado, isFalse);
    expect(authViewModel.esArtista, isFalse);
    expect(authViewModel.esOyente, isFalse);
  });

  test('login con email como artista queda registrado', () async {
    await authViewModel.loginConEmail(
      email: 'mateo@b.com',
      password: '123456',
      rol: RolUsuario.artista,
    );
    expect(authViewModel.esArtista, isTrue);
    expect(authViewModel.esRegistrado, isTrue);
    expect(authViewModel.usuario?.email, 'mateo@b.com');
  });

  test('login con google como oyente', () async {
    await authViewModel.loginConGoogle(rol: RolUsuario.oyente);
    expect(authViewModel.esOyente, isTrue);
    expect(authViewModel.esRegistrado, isTrue);
  });

  test('registrar crea la cuenta y logout la limpia', () async {
    await authViewModel.registrar(
      nombre: 'Ana',
      email: 'ana@b.com',
      password: '123456',
      rol: RolUsuario.oyente,
    );
    expect(authViewModel.estaLogueado, isTrue);
    expect(authViewModel.usuario?.nombre, 'Ana');
    authViewModel.logout();
    expect(authViewModel.estaLogueado, isFalse);
    expect(authViewModel.esInvitado, isFalse);
  });

  test(
    'sin Firebase inicializado se usa el auth simulado (modo demo)',
    () async {
      // En los tests nunca se llama a inicializarFirebase(): modo demo.
      expect(firebaseInicializado, isFalse);
      await authViewModel.loginConGoogle(rol: RolUsuario.oyente);
      // El id "google_..." es del servicio simulado, no de Firebase (uid real).
      expect(authViewModel.usuario?.id, startsWith('google_'));
      expect(authViewModel.esOyente, isTrue);
    },
  );
}
