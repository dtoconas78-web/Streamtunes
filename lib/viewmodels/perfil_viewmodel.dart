import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/models/artista.dart';

// Estados por los que pasa una solicitud de verificación.
enum EstadoVerificacion { noSolicitada, pendiente, verificada, rechazada }

// Perfil del artista logueado en esta sesión. La identidad (id + nombre)
// viene del [Artista] inyectado (semilla: RepositorioArtistas, ver
// lib/inyeccion.dart); los datos editables (país, bio) viven acá.
//
// Ojo: RepositorioArtistas es de solo lectura en esta etapa, así que
// [guardar] reemplaza la copia local del VM (mismo id, nombre nuevo) y el
// repo NO se reescribe; con backend, ambos van a la misma fuente.
//
// La presentación visual del estado (etiqueta/ícono/color) vive en la capa
// de vistas: lib/views/widgets/estado_verificacion_ui.dart.
class PerfilUsuario extends ChangeNotifier {
  PerfilUsuario({required this._artista});

  Artista _artista;
  String _pais = 'Argentina';
  String _bio =
      'Artista independiente de Mendoza. Hace música desde 2019, mezclando rock alternativo con sonidos electrónicos.';

  // Getters de solo lectura: los cambios pasan por [guardar],
  // [enviarSolicitud] y [simularResultado] (que notifican).
  Artista get artista => _artista;
  String get nombre => _artista.nombre;
  String get pais => _pais;
  String get bio => _bio;

  void guardar({
    required String nombre,
    required String pais,
    required String bio,
  }) {
    _artista = Artista(id: _artista.id, nombre: nombre);
    _pais = pais;
    _bio = bio;
    notifyListeners();
  }

  EstadoVerificacion _estadoVerificacion = EstadoVerificacion.noSolicitada;
  String _motivoRechazo = '';

  EstadoVerificacion get estadoVerificacion => _estadoVerificacion;
  String get motivoRechazo => _motivoRechazo;

  bool get esVerificado => _estadoVerificacion == EstadoVerificacion.verificada;

  // Se llama al enviar el formulario. Los datos del formulario NO se guardan
  // acá a propósito: documento y cuenta de cobro son sensibles y tienen que ir
  // directo al backend (o al proveedor de pagos), nunca quedarse en la app.
  void enviarSolicitud() {
    _estadoVerificacion = EstadoVerificacion.pendiente;
    _motivoRechazo = '';
    notifyListeners();
  }

  // SOLO PARA PRUEBAS: simula la respuesta del equipo que revisa.
  // Cuando haya backend, esto se reemplaza por la respuesta real.
  void simularResultado({required bool aprobada, String motivo = ''}) {
    _estadoVerificacion = aprobada
        ? EstadoVerificacion.verificada
        : EstadoVerificacion.rechazada;
    _motivoRechazo = motivo;
    notifyListeners();
  }
}
