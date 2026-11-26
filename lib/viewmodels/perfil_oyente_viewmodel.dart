import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_ciudad.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';

/// Datos que el oyente declara en su perfil: por ahora, su ciudad (se usa
/// en las estadísticas de los artistas; sin GPS). Es POR USUARIO: sigue al
/// usuario con sesión (ver `usarUsuario`, llamado desde inyeccion.dart).
class PerfilOyenteViewModel extends ChangeNotifier {
  PerfilOyenteViewModel({RepositorioCiudad? repositorio})
    : _repositorio = repositorio ?? RepositorioCiudadMemoria();

  final RepositorioCiudad _repositorio;
  String? _uid;
  String _ciudad = '';
  bool _guardando = false;
  Object? _ultimoError;
  Future<void> _listo = Future.value();

  /// Ciudad declarada ('' = no declaró ninguna).
  String get ciudad => _ciudad;

  /// Ciudad que se registra en las métricas.
  String get ciudadParaMetricas => normalizarCiudad(_ciudad);

  bool get puedeDeclarar => _uid != null;
  bool get guardando => _guardando;
  Object? get ultimoError => _ultimoError;

  /// Se completa cuando terminó la última carga.
  Future<void> get listo => _listo;

  /// Cambia de usuario (null = sin sesión o invitado) y lee su ciudad.
  void usarUsuario(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _ciudad = '';
    notifyListeners();
    if (uid == null) return;
    _listo = _cargar(uid);
  }

  Future<void> _cargar(String uid) async {
    final guardada = await _repositorio.leer(uid);
    if (_uid != uid) return; // cambió de usuario mientras tanto
    _ciudad = guardada ?? '';
    notifyListeners();
  }

  /// Guarda la ciudad declarada (normalizada; vacía = no declarar).
  Future<void> guardarCiudad(String ciudad) async {
    final uid = _uid;
    if (uid == null || _guardando) return;
    final limpia = normalizarCiudad(ciudad);
    final valor = limpia == ciudadSinDeclarar ? '' : limpia;
    _guardando = true;
    _ultimoError = null;
    notifyListeners();
    try {
      await _repositorio.guardar(uid, valor);
      if (_uid == uid) _ciudad = valor;
    } catch (e) {
      _ultimoError = e;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }
}
