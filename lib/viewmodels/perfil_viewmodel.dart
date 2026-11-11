import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Estados por los que pasa una solicitud de verificación.
enum EstadoVerificacion { noSolicitada, pendiente, verificada, rechazada }

class PerfilUsuario extends ChangeNotifier {
  String nombre = 'Mateo Cabral';
  String pais = 'Argentina';
  String bio =
      'Artista independiente de Mendoza. Hace música desde 2019, mezclando rock alternativo con sonidos electrónicos.';

  void guardar({required String nombre, required String pais, required String bio}) {
    this.nombre = nombre;
    this.pais = pais;
    this.bio = bio;
    notifyListeners();
  }

  EstadoVerificacion estadoVerificacion = EstadoVerificacion.noSolicitada;
  String motivoRechazo = '';

  bool get esVerificado => estadoVerificacion == EstadoVerificacion.verificada;

  // Texto, ícono y color del botón de verificación en el perfil.
  String get etiquetaVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => 'Verificar perfil',
    EstadoVerificacion.pendiente => 'En revisión',
    EstadoVerificacion.verificada => 'Verificado',
    EstadoVerificacion.rechazada => 'Verificación rechazada',
  };

  IconData get iconoVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => Icons.verified_outlined,
    EstadoVerificacion.pendiente => Icons.hourglass_top,
    EstadoVerificacion.verificada => Icons.verified,
    EstadoVerificacion.rechazada => Icons.error_outline,
  };

  Color get colorVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => colorAcento,
    EstadoVerificacion.pendiente => Colors.amber,
    EstadoVerificacion.verificada => colorVerificado,
    EstadoVerificacion.rechazada => Colors.redAccent,
  };

  // Se llama al enviar el formulario. Los datos del formulario NO se guardan
  // acá a propósito: documento y cuenta de cobro son sensibles y tienen que ir
  // directo al backend (o al proveedor de pagos), nunca quedarse en la app.
  void enviarSolicitud() {
    estadoVerificacion = EstadoVerificacion.pendiente;
    motivoRechazo = '';
    notifyListeners();
  }

  // SOLO PARA PRUEBAS: simula la respuesta del equipo que revisa.
  // Cuando haya backend, esto se reemplaza por la respuesta real.
  void simularResultado({required bool aprobada, String motivo = ''}) {
    estadoVerificacion =
        aprobada ? EstadoVerificacion.verificada : EstadoVerificacion.rechazada;
    motivoRechazo = motivo;
    notifyListeners();
  }
}

final PerfilUsuario perfil = PerfilUsuario();