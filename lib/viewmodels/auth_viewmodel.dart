import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/services/auth_service.dart';

// ViewModel de autenticación: depende SOLO del contrato [AuthService], que se
// inyecta por constructor. Qué implementación concreta se usa (Firebase o
// simulado) se decide en un único lugar: lib/inyeccion.dart. Los tests pueden
// pasar un AuthService falso para probar el VM aislado del singleton global.
//
// Además del usuario, expone el estado de la operación async en curso
// ([cargando]) y el último error crudo ([ultimoError]): la vista traduce ese
// error con descripcionErrorAuth, así que los mensajes específicos de
// Firebase/Google se conservan tal cual.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._servicio});

  final AuthService _servicio;

  Usuario? _usuario;
  bool _cargando = false;
  Object? _ultimoError;

  Usuario? get usuario => _usuario;
  bool get estaLogueado => _usuario != null;
  bool get esArtista => _usuario?.rol == RolUsuario.artista;
  bool get esOyente => _usuario?.rol == RolUsuario.oyente;
  bool get esInvitado => _usuario?.rol == RolUsuario.invitado;
  // Cuenta registrada (gratis): artista u oyente. El invitado no lo es.
  bool get esRegistrado => esArtista || esOyente;

  /// true mientras hay una operación de autenticación en curso.
  bool get cargando => _cargando;

  /// Error crudo de la última operación (null si la última fue exitosa o
  /// todavía no hubo ninguna). La vista lo traduce con descripcionErrorAuth.
  Object? get ultimoError => _ultimoError;

  void login(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void logout() {
    _usuario = null;
    // El cierre remoto va en segundo plano: el helper captura cualquier error
    // para que no quede una excepción asíncrona no gestionada (unawaited solo
    // marca la intención, NO atrapa errores). El estado local ya quedó en
    // "deslogueado"; si el cierre remoto falla solo se diagnostica con
    // debugPrint, nunca se afirma que la sesión remota se cerró.
    unawaited(_cerrarSesionEnProveedor());
    notifyListeners();
  }

  Future<void> _cerrarSesionEnProveedor() async {
    try {
      await _servicio.cerrarSesion();
    } catch (e) {
      debugPrint(
        'Falló cerrarSesion en el proveedor (la sesión local ya se cerró): $e',
      );
    }
  }

  // Envuelve cualquier operación del servicio con el estado de carga: notifica
  // al comenzar y al finalizar (finally), limpia el error anterior al arrancar
  // y rechaza operaciones concurrentes SIN tocar el estado de la que ya está
  // en curso (ni cargando, ni error, ni usuario).
  Future<void> _ejecutarAuth(Future<Usuario> Function() operacion) async {
    if (_cargando) return;
    _cargando = true;
    _ultimoError = null;
    notifyListeners();
    try {
      login(await operacion());
    } catch (e) {
      // Se guarda el error crudo: la traducción a mensaje va en la vista.
      _ultimoError = e;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> loginConEmail({
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _ejecutarAuth(
    () =>
        _servicio.ingresarConEmail(email: email, password: password, rol: rol),
  );

  Future<void> loginConGoogle({required RolUsuario rol}) =>
      _ejecutarAuth(() => _servicio.ingresarConGoogle(rol: rol));

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) => _ejecutarAuth(
    () => _servicio.registrar(
      nombre: nombre,
      email: email,
      password: password,
      rol: rol,
    ),
  );

  Future<void> entrarComoInvitado() =>
      _ejecutarAuth(() => _servicio.crearInvitado());
}
