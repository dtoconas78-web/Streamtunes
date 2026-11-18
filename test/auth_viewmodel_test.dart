import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';
import 'package:streamtunes_demo/services/firebase_inicial.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';

// AuthService falso: sirve para comprobar que el ViewModel depende SOLO del
// contrato inyectado y no del singleton global ni de ninguna implementación
// concreta.
class _AuthServiceFalso implements AuthService {
  int vecesCerrarSesion = 0;

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async => Usuario(id: 'fake-email', nombre: 'Fake', email: email, rol: rol);

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) async =>
      Usuario(id: 'fake-google', nombre: 'Fake', email: 'fake@g.com', rol: rol);

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async => Usuario(id: 'fake-reg', nombre: nombre, email: email, rol: rol);

  @override
  Future<Usuario> crearInvitado() async => Usuario(
    id: 'fake-invitado',
    nombre: 'Invitado',
    email: '',
    rol: RolUsuario.invitado,
  );

  @override
  Future<void> cerrarSesion() async {
    vecesCerrarSesion++;
  }
}

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

  test(
    'el VM usa solo el AuthService inyectado (independiente del singleton)',
    () async {
      final servicio = _AuthServiceFalso();
      final vm = AuthViewModel(servicio: servicio);

      await vm.loginConEmail(
        email: 'fake@b.com',
        password: '123456',
        rol: RolUsuario.artista,
      );
      expect(vm.estaLogueado, isTrue);
      expect(vm.esArtista, isTrue);
      expect(vm.usuario?.id, 'fake-email');

      vm.logout();
      expect(vm.estaLogueado, isFalse);
      expect(servicio.vecesCerrarSesion, 1);

      // El singleton global no se tocó.
      expect(authViewModel.estaLogueado, isFalse);
    },
  );
}
