/// De dónde sale la foto.
enum OrigenFoto { camara, galeria }

/// Resultado de pedir una foto: hay foto, el usuario canceló, o falló (p. ej.
/// sin permiso de cámara). Sellado: quien lo usa contempla los tres casos.
sealed class ResultadoFoto {
  const ResultadoFoto();
}

/// Se obtuvo una foto. [ruta] es un archivo TEMPORAL del sistema: hay que
/// copiarlo (ver AlmacenFotos) para conservarlo.
class FotoTomada extends ResultadoFoto {
  const FotoTomada(this.ruta);
  final String ruta;
}

/// El usuario cerró la cámara o la galería sin elegir nada.
class FotoCancelada extends ResultadoFoto {
  const FotoCancelada();
}

/// No se pudo obtener la foto ([error] crudo; la vista lo traduce).
class FotoFallida extends ResultadoFoto {
  const FotoFallida(this.error);
  final Object error;
}

/// Contrato para sacar o elegir fotos. Sin plugins: los ViewModels dependen
/// de esta interfaz y los tests inyectan una falsa. La real (image_picker)
/// está en fuente_image_picker.dart y se elige en lib/inyeccion.dart.
abstract class FuenteDeFotos {
  Future<ResultadoFoto> tomar(OrigenFoto origen);

  /// En Android el sistema puede cerrar la app mientras la cámara está
  /// abierta; al volver a abrirla, la foto se recupera con esto. Sin nada
  /// pendiente devuelve [FotoCancelada].
  Future<ResultadoFoto> recuperarPerdida();
}
