import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_configuracion.dart';
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano.dart';

// Preferencias del oyente. La de notificaciones se guarda en el celular (ver
// RepositorioConfiguracion) y al activarla/desactivarla se piden permisos
// reales y se registran/cancelan las tareas en segundo plano.
// Todas las dependencias son opcionales: sin ellas (tests de la Ola 1) el VM
// funciona en memoria como antes.
class ConfiguracionViewModel extends ChangeNotifier {
  ConfiguracionViewModel({
    RepositorioConfiguracion? repositorio,
    this._recordatorios,
    ServicioTareasSegundoPlano? tareas,
  }) : _repositorio = repositorio ?? RepositorioConfiguracionMemoria(),
       _tareas = tareas ?? const ServicioTareasNulo() {
    // Las notificaciones parten de lo guardado (desactivadas por defecto:
    // son opt-in, el usuario las activa y concede el permiso).
    _notificaciones = _repositorio.notificaciones;
  }

  final RepositorioConfiguracion _repositorio;
  final ServicioRecordatorios? _recordatorios;
  final ServicioTareasSegundoPlano _tareas;

  bool _notificaciones = false;
  bool _reproduccionAutomatica = true;
  bool _modoAleatorioPorDefecto = false;

  // Estado de la operación asíncrona de [cambiarNotificaciones].
  bool _cargando = false;
  bool _permisoDenegado = false;
  Object? _ultimoError;

  // Getters de solo lectura: los cambios pasan por los métodos, que notifican.
  bool get notificaciones => _notificaciones;
  bool get reproduccionAutomatica => _reproduccionAutomatica;
  bool get modoAleatorioPorDefecto => _modoAleatorioPorDefecto;
  bool get cargando => _cargando;

  /// true si el último intento de activar fue rechazado por el usuario.
  bool get permisoDenegado => _permisoDenegado;

  /// Error crudo del último cambio (la vista lo traduce a un mensaje).
  Object? get ultimoError => _ultimoError;

  /// Cambio SOLO del estado local (sin permisos, tareas ni guardado). Se
  /// conserva para compatibilidad; la pantalla usa [cambiarNotificaciones].
  void setNotificaciones(bool v) {
    if (_notificaciones == v) return;
    _notificaciones = v;
    notifyListeners();
  }

  /// Activa o desactiva las notificaciones de verdad:
  /// - Activar: pide el permiso del sistema; si se concede, registra la
  ///   verificación periódica y guarda la preferencia. Si se rechaza, queda
  ///   desactivada y [permisoDenegado] pasa a true.
  /// - Desactivar: cancela la tarea periódica y los recordatorios
  ///   programados, y guarda la preferencia.
  /// Si algo falla, la preferencia no cambia y el error queda en
  /// [ultimoError]. Con guard anti-concurrencia (un cambio a la vez).
  Future<void> cambiarNotificaciones(bool activar) async {
    if (_cargando || activar == _notificaciones) return;
    _cargando = true;
    _permisoDenegado = false;
    _ultimoError = null;
    notifyListeners();
    try {
      if (activar) {
        final concedido = await _recordatorios?.solicitarPermisos() ?? true;
        if (!concedido) {
          _permisoDenegado = true;
          return;
        }
        await _tareas.registrarVerificacionPeriodica();
      } else {
        await _tareas.cancelar();
        await _recordatorios?.cancelarRecordatorios();
      }
      _notificaciones = activar;
      await _repositorio.guardarNotificaciones(activar);
    } catch (e) {
      _ultimoError = e;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void setReproduccionAutomatica(bool v) {
    if (_reproduccionAutomatica == v) return;
    _reproduccionAutomatica = v;
    notifyListeners();
  }

  void setModoAleatorioPorDefecto(bool v) {
    if (_modoAleatorioPorDefecto == v) return;
    _modoAleatorioPorDefecto = v;
    notifyListeners();
  }
}
