import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/views/screens/album_screen.dart';
import 'package:streamtunes_demo/views/screens/donar_screen.dart';
import 'package:streamtunes_demo/views/screens/editar_perfil_screen.dart';
import 'package:streamtunes_demo/views/screens/entradas_screen.dart';
import 'package:streamtunes_demo/views/screens/estadisticas_cancion_screen.dart';
import 'package:streamtunes_demo/views/screens/publicar_concierto_screen.dart';
import 'package:streamtunes_demo/views/screens/registro_screen.dart';
import 'package:streamtunes_demo/views/screens/reproductor_screen.dart';
import 'package:streamtunes_demo/views/screens/solicitud_verificacion_screen.dart';
import 'package:streamtunes_demo/views/screens/subir_musica_screen.dart';
import 'package:streamtunes_demo/views/screens/verificacion_screen.dart';
import 'package:streamtunes_demo/views/screens/ventas_donaciones_screen.dart';

// Nombres de ruta de toda la app, en un solo lugar.
class Rutas {
  static const reproductor = '/reproductor';
  static const album = '/album';
  static const estadisticas = '/estadisticas';
  static const editarPerfil = '/editar-perfil';
  static const verificacion = '/verificacion';
  static const solicitudVerificacion = '/verificacion/solicitud';
  static const ventas = '/ventas-donaciones';
  static const subirMusica = '/subir-musica';
  static const registro = '/registro';
  static const entradas = '/entradas';
  static const donar = '/donar';
  static const publicarConcierto = '/publicar-concierto';
}

// Cada ruta sabe qué pantalla construir y con qué argumentos.
// Se enchufa en MaterialApp(onGenerateRoute: generarRuta).
Route<dynamic> generarRuta(RouteSettings settings) {
  switch (settings.name) {
    case Rutas.reproductor:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PantallaReproductor(),
      );
    case Rutas.album:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PantallaAlbum(album: settings.arguments as Album),
      );
    case Rutas.estadisticas:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => PantallaB(cancion: settings.arguments as Cancion),
      );
    case Rutas.editarPerfil:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PantallaEditarPerfil(),
      );
    case Rutas.verificacion:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PantallaVerificacion(),
      );
    case Rutas.solicitudVerificacion:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PantallaSolicitudVerificacion(),
      );
    case Rutas.ventas:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const VentasDonacionesScreen(),
      );
    case Rutas.subirMusica:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PantallaSubirMusica(),
      );
    case Rutas.registro:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RegistroScreen(),
      );
    case Rutas.entradas:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const EntradasScreen(),
      );
    case Rutas.donar:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const DonarScreen(),
      );
    case Rutas.publicarConcierto:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PublicarConciertoScreen(),
      );
    default:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => Scaffold(
          body: Center(child: Text('Ruta desconocida: ${settings.name}')),
        ),
      );
  }
}

// Navega a una ruta nombrada (más legible que MaterialPageRoute inline).
void irA(BuildContext context, String ruta, {Object? argumentos}) {
  Navigator.pushNamed(context, ruta, arguments: argumentos);
}
