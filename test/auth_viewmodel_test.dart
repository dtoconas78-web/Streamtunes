import 'dart:async';

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

// Servicio que deja la operación pendiente hasta que el test la complete con
// [completar]: permite verificar el estado "cargando" intermedio.
class _AuthServiceControlable implements AuthService {
  final completer = Completer<Usuario>();
  int llamadas = 0;

  void completar(Usuario u) => completer.complete(u);

  Future<Usuario> _pendiente() {
    llamadas++;
    return completer.future;
  }

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _pendiente();

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) => _pendiente();

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _pendiente();

  @override
  Future<Usuario> crearInvitado() => _pendiente();

  @override
  Future<void> cerrarSesion() async {}
}

// Servicio que falla siempre con el error indicado.
class _AuthServiceQueFalla implements AuthService {
  _AuthServiceQueFalla(this.error);

  final Object error;
  int llamadas = 0;

  Future<Usuario> _fallo() {
    llamadas++;
    return Future.error(error);
  }

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _fallo();

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) => _fallo();

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _fallo();

  @override
  Future<Usuario> crearInvitado() => _fallo();

  @override
  Future<void> cerrarSesion() async {}
}

// Servicio que falla el PRIMER intento y después funciona: sirve para probar
// que un nuevo intento limpia el error anterior.
class _AuthServiceFallaPrimero implements AuthService {
  int intentos = 0;

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    intentos++;
    if (intentos == 1) throw StateError('primer intento falla');
    return Usuario(id: 'ok', nombre: 'Ok', email: email, rol: rol);
  }

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) async =>
      Usuario(id: 'ok-g', nombre: 'Ok', email: '', rol: rol);

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async => Usuario(id: 'ok-r', nombre: nombre, email: email, rol: rol);

  @override
  Future<Usuario> crearInvitado() async => Usuario(
    id: 'ok-i',
    nombre: 'Invitado',
    email: '',
    rol: RolUsuario.invitado,
  );

  @override
  Future<void> cerrarSesion() async {}
}

// Servicio cuyo cerrarSesion SIEMPRE falla: sirve para probar que el helper
// del logout captura el error (sin error asíncrono no gestionado).
class _AuthServiceCierreFalla implements AuthService {
  int vecesCerrarSesion = 0;

  @override
  Future<Usuario> ingresarConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) async => Usuario(id: 'x', nombre: 'X', email: email, rol: rol);

  @override
  Future<Usuario> ingresarConGoogle({required RolUsuario rol}) async =>
      Usuario(id: 'x', nombre: 'X', email: '', rol: rol);

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async => Usuario(id: 'x', nombre: nombre, email: email, rol: rol);

  @override
  Future<Usuario> crearInvitado() async =>
      Usuario(id: 'x', nombre: 'Invitado', email: '', rol: RolUsuario.invitado);

  @override
  Future<void> cerrarSesion() async {
    vecesCerrarSesion++;
    throw StateError('no se pudo cerrar la sesión en el proveedor');
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

  test(
    'cargando es true durante la operación y false al finalizar (éxito)',
    () async {
      final servicio = _AuthServiceControlable();
      final vm = AuthViewModel(servicio: servicio);

      final pendiente = vm.loginConEmail(
        email: 'a@b.com',
        password: '123456',
        rol: RolUsuario.oyente,
      );
      // Mientras el servicio no responde, el VM está cargando y sin error.
      expect(vm.cargando, isTrue);
      expect(vm.ultimoError, isNull);
      expect(vm.estaLogueado, isFalse);

      servicio.completar(
        Usuario(
          id: 'u1',
          nombre: 'Ana',
          email: 'a@b.com',
          rol: RolUsuario.oyente,
        ),
      );
      await pendiente;

      expect(vm.cargando, isFalse);
      expect(vm.estaLogueado, isTrue);
      expect(vm.usuario?.id, 'u1');
      expect(vm.ultimoError, isNull);
    },
  );

  test('si la operación falla, cargando se limpia (finally) y el error queda crudo', () async {
    final servicio = _AuthServiceQueFalla(StateError('credenciales inválidas'));
    final vm = AuthViewModel(servicio: servicio);

    await vm.loginConGoogle(rol: RolUsuario.oyente);

    expect(vm.cargando, isFalse);
    expect(vm.estaLogueado, isFalse);
    // El VM guarda la excepción original, sin traducirla.
    expect(vm.ultimoError, isA<StateError>());
    expect((vm.ultimoError as StateError).message, 'credenciales inválidas');
  });

  test('un nuevo intento limpia el error anterior', () async {
    final servicio = _AuthServiceFallaPrimero();
    final vm = AuthViewModel(servicio: servicio);

    await vm.loginConEmail(
      email: 'a@b.com',
      password: '123456',
      rol: RolUsuario.oyente,
    );
    expect(vm.ultimoError, isA<StateError>());
    expect(vm.estaLogueado, isFalse);

    await vm.loginConEmail(
      email: 'a@b.com',
      password: '123456',
      rol: RolUsuario.oyente,
    );
    expect(vm.ultimoError, isNull);
    expect(vm.estaLogueado, isTrue);
    expect(vm.cargando, isFalse);
  });

  test(
    'una operación concurrente se rechaza sin alterar la que está en curso',
    () async {
      final servicio = _AuthServiceControlable();
      final vm = AuthViewModel(servicio: servicio);

      final enCurso = vm.loginConEmail(
        email: 'a@b.com',
        password: '123456',
        rol: RolUsuario.oyente,
      );
      expect(vm.cargando, isTrue);

      // Segunda operación mientras la primera está pendiente: el guard la
      // rechaza ANTES de llamar al servicio o tocar cualquier estado.
      await vm.registrar(
        nombre: 'Otro',
        email: 'o@b.com',
        password: '123456',
        rol: RolUsuario.artista,
      );
      expect(servicio.llamadas, 1);
      expect(vm.cargando, isTrue);
      expect(vm.ultimoError, isNull);
      expect(vm.estaLogueado, isFalse);

      servicio.completar(
        Usuario(
          id: 'u1',
          nombre: 'Ana',
          email: 'a@b.com',
          rol: RolUsuario.oyente,
        ),
      );
      await enCurso;

      expect(vm.cargando, isFalse);
      expect(vm.usuario?.id, 'u1');
      expect(vm.ultimoError, isNull);
    },
  );

  test('logout con cerrarSesion fallando: el helper captura el error y no hay '
      'error asíncrono no gestionado', () async {
    final servicio = _AuthServiceCierreFalla();
    final vm = AuthViewModel(servicio: servicio);
    vm.login(
      Usuario(id: 'x', nombre: 'X', email: 'x@b.com', rol: RolUsuario.oyente),
    );

    Object? errorNoGestionado;
    await runZonedGuarded(() async {
      vm.logout();
      // Dejar correr el helper async hasta su catch.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }, (e, stack) => errorNoGestionado = e);

    expect(
      errorNoGestionado,
      isNull,
      reason:
          'unawaited no atrapa errores: el helper con try/catch debe '
          'capturar el fallo de cerrarSesion',
    );
    // El estado local igualmente quedó deslogueado.
    expect(vm.estaLogueado, isFalse);
    expect(servicio.vecesCerrarSesion, 1);
  });
}
