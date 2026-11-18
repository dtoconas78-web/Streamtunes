import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';

// Presentación visual del estado de verificación: etiqueta, ícono y color.
// El ViewModel solo expone el estado; acá vive cómo se muestra.
extension EstadoVerificacionUI on EstadoVerificacion {
  String get etiqueta => switch (this) {
    EstadoVerificacion.noSolicitada => 'Verificar perfil',
    EstadoVerificacion.pendiente => 'En revisión',
    EstadoVerificacion.verificada => 'Verificado',
    EstadoVerificacion.rechazada => 'Verificación rechazada',
  };

  IconData get icono => switch (this) {
    EstadoVerificacion.noSolicitada => Icons.verified_outlined,
    EstadoVerificacion.pendiente => Icons.hourglass_top,
    EstadoVerificacion.verificada => Icons.verified,
    EstadoVerificacion.rechazada => Icons.error_outline,
  };

  Color get color => switch (this) {
    EstadoVerificacion.noSolicitada => colorAcento,
    EstadoVerificacion.pendiente => Colors.amber,
    EstadoVerificacion.verificada => colorVerificado,
    EstadoVerificacion.rechazada => Colors.redAccent,
  };
}
