import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/services/almacen_fotos.dart';
import 'package:streamtunes_demo/services/fuente_de_fotos.dart';

/// Una foto elegida por el usuario (perfil, portada o documento).
///
/// - [elegir] saca o elige la foto, la copia al almacén y, si había otra,
///   BORRA la anterior (no se acumulan archivos).
/// - Contempla los tres resultados: foto, canceló (no cambia nada) o error
///   ([ultimoError] crudo; la vista lo traduce).
/// - [alGuardar] persiste la RUTA (nunca la imagen) donde corresponda.
/// - [alPendiente] marca/desmarca que se abrió la cámara, para poder
///   recuperar la foto si Android cierra la app en el medio
///   ([recuperarPerdida]).
class FotoViewModel extends ChangeNotifier {
  FotoViewModel({
    required this._fuente,
    required this._almacen,
    required this._prefijo,
    this._temporal = false,
    this._ruta,
    this._alGuardar,
    this._alPendiente,
  });

  final FuenteDeFotos _fuente;
  final AlmacenFotos _almacen;
  final String _prefijo;
  final bool _temporal;
  final Future<void> Function(String? ruta)? _alGuardar;
  final Future<void> Function(bool pendiente)? _alPendiente;

  String? _ruta;
  bool _cargando = false;
  Object? _ultimoError;

  /// Ruta de la foto actual (null = sin foto).
  String? get ruta => _ruta;
  bool get tieneFoto => _ruta != null;
  bool get cargando => _cargando;
  Object? get ultimoError => _ultimoError;

  /// Muestra una foto ya guardada (p. ej. al cambiar de usuario) sin borrar
  /// la anterior ni persistir nada. Si el archivo ya no existe, queda sin foto.
  void mostrar(String? ruta) {
    final valida = ruta != null && _almacen.existe(ruta) ? ruta : null;
    if (valida == _ruta) return;
    _ruta = valida;
    _ultimoError = null;
    notifyListeners();
  }

  /// Saca (cámara) o elige (galería) una foto. Devuelve el resultado para
  /// que la vista avise lo que corresponda.
  Future<ResultadoFoto> elegir(OrigenFoto origen) async {
    if (_cargando) return const FotoCancelada();
    _cargando = true;
    _ultimoError = null;
    notifyListeners();
    try {
      if (origen == OrigenFoto.camara) await _marcarPendiente(true);
      final resultado = await _fuente.tomar(origen);
      if (origen == OrigenFoto.camara) await _marcarPendiente(false);
      await _aplicar(resultado);
      return resultado;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Recupera la foto que quedó pendiente si Android cerró la app con la
  /// cámara abierta (llamar al arrancar).
  Future<void> recuperarPerdida() async {
    final resultado = await _fuente.recuperarPerdida();
    await _marcarPendiente(false);
    await _aplicar(resultado);
    notifyListeners();
  }

  /// Quita la foto actual (y borra el archivo).
  Future<void> quitar() async {
    final anterior = _ruta;
    if (anterior == null) return;
    _ruta = null;
    notifyListeners();
    await _alGuardar?.call(null);
    await _almacen.borrar(anterior);
  }

  /// Borra el archivo sin persistir nada (formularios que no se enviaron, o
  /// la foto del documento después de enviarla: es un dato sensible).
  Future<void> descartar() async {
    final anterior = _ruta;
    _ruta = null;
    if (anterior != null) await _almacen.borrar(anterior);
  }

  Future<void> _aplicar(ResultadoFoto resultado) async {
    switch (resultado) {
      case FotoCancelada():
        return;
      case FotoFallida(:final error):
        _ultimoError = error;
      case FotoTomada(ruta: final temporal):
        try {
          final nueva = await _almacen.guardar(
            temporal,
            prefijo: _prefijo,
            temporal: _temporal,
          );
          final anterior = _ruta;
          _ruta = nueva;
          await _alGuardar?.call(nueva);
          if (anterior != null && anterior != nueva) {
            await _almacen.borrar(anterior);
          }
        } catch (e) {
          _ultimoError = e;
        }
    }
  }

  Future<void> _marcarPendiente(bool pendiente) async {
    try {
      await _alPendiente?.call(pendiente);
    } catch (e) {
      debugPrint('No se pudo marcar la foto pendiente: $e');
    }
  }
}
