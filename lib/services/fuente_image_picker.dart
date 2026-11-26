import 'package:image_picker/image_picker.dart';
import 'package:streamtunes_demo/services/fuente_de_fotos.dart';

/// Fotos con el plugin image_picker (cámara o galería del sistema). No pide
/// el permiso CAMERA: usa la app de cámara del sistema, y en Android 13+ el
/// selector de fotos, que no necesitan permisos propios.
class FuenteImagePicker implements FuenteDeFotos {
  FuenteImagePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Las fotos se achican al tomarlas: alcanza para perfil y portada y no
  /// llena el celular.
  static const double ladoMaximo = 1600;
  static const int calidad = 85;

  @override
  Future<ResultadoFoto> tomar(OrigenFoto origen) async {
    try {
      final archivo = await _picker.pickImage(
        source: origen == OrigenFoto.camara
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: ladoMaximo,
        maxHeight: ladoMaximo,
        imageQuality: calidad,
      );
      return archivo == null ? const FotoCancelada() : FotoTomada(archivo.path);
    } catch (e) {
      return FotoFallida(e);
    }
  }

  @override
  Future<ResultadoFoto> recuperarPerdida() async {
    try {
      final perdida = await _picker.retrieveLostData();
      if (perdida.isEmpty) return const FotoCancelada();
      final archivo = perdida.file;
      if (archivo != null) return FotoTomada(archivo.path);
      return FotoFallida(perdida.exception ?? StateError('foto perdida'));
    } catch (e) {
      return FotoFallida(e);
    }
  }
}
