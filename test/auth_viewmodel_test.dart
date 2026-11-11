import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/models/usuario.dart';
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
}
