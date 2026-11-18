import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Estados por los que pasa una solicitud de verificación.
enum EstadoVerificacion { noSolicitada, pendiente, verificada, rechazada }

class PerfilUsuario extends ChangeNotifier {
  String _nombre = 'Mateo Cabral';
  String _pais = 'Argentina';
  String _bio =
      'Artista independiente de Mendoza. Hace música desde 2019, mezclando rock alternativo con sonidos electrónicos.';

  // Getters de solo lectura: los cambios pasan por [guardar],
  // [enviarSolicitud] y [simularResultado] (que notifican).
  String get nombre => _nombre;
  String get pais => _pais;
  String get bio => _bio;

  void guardar({
    required String nombre,
    required String pais,
    required String bio,
  }) {
    _nombre = nombre;
    _pais = pais;
    _bio = bio;
    notifyListeners();
  }

  EstadoVerificacion _estadoVerificacion = EstadoVerificacion.noSolicitada;
  String _motivoRechazo = '';

  EstadoVerificacion get estadoVerificacion => _estadoVerificacion;
  String get motivoRechazo => _motivoRechazo;

  bool get esVerificado => _estadoVerificacion == EstadoVerificacion.verificada;

  // Texto, ícono y color del botón de verificación en el perfil.
  String get etiquetaVerificacion => switch (_estadoVerificacion) {
    EstadoVerificacion.noSolicitada => 'Verificar perfil',
    EstadoVerificacion.pendiente => 'En revisión',
    EstadoVerificacion.verificada => 'Verificado',
    EstadoVerificacion.rechazada => 'Verificación rechazada',
  };

  IconData get iconoVerificacion => switch (_estadoVerificacion) {
    EstadoVerificacion.noSolicitada => Icons.verified_outlined,
    EstadoVerificacion.pendiente => Icons.hourglass_top,
    EstadoVerificacion.verificada => Icons.verified,
    EstadoVerificacion.rechazada => Icons.error_outline,
  };

  Color get colorVerificacion => switch (_estadoVerificacion) {
    EstadoVerificacion.noSolicitada => colorAcento,
    EstadoVerificacion.pendiente => Colors.amber,
    EstadoVerificacion.verificada => colorVerificado,
    EstadoVerificacion.rechazada => Colors.redAccent,
  };

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

final PerfilUsuario perfil = PerfilUsuario();
