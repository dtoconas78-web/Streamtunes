import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';

Cancion _c(String id) => Cancion(
  id: id,
  titulo: id,
  duracionSegundos: 180,
  reproducciones: 0,
  tendencia: '',
  lugar: '',
  horarioPico: '',
  colorPortada: 0,
);

// Catálogo cuyo contenido se reemplaza a mano, como un snapshot de Firestore
// que llega con otro orden u otras canciones.
class _CatalogoCambiante extends RepositorioCatalogo {
  _CatalogoCambiante(this._canciones);

  List<Cancion> _canciones;

  void reemplazar(List<Cancion> nuevas) {
    _canciones = nuevas;
    notifyListeners();
  }

  @override
  List<Cancion> get canciones => List.unmodifiable(_canciones);

  @override
  List<Album> get albumes => const [];

  @override
  void agregarCanciones(List<Cancion> nuevas) {}

  @override
  void agregarAlbum(Album album) {}
}

void main() {
  test('el me gusta sigue a la canción por id aunque cambie el orden', () {
    final catalogo = _CatalogoCambiante([_c('a'), _c('b')]);
    final seguimiento = RepositorioSeguimientoMemoria();
    final r = ControladorReproduccion(
      repositorioCatalogo: catalogo,
      repositorioSeguimiento: seguimiento,
    );
    addTearDown(r.dispose);

    r.reproducir(0); // 'a'
    r.alternarMeGusta();
    expect(seguimiento.cancionesMeGusta, {'a'});

    // Llega una canción nueva al principio: el índice 0 ahora es otra.
    catalogo.reemplazar([_c('nueva'), _c('a'), _c('b')]);
    expect(r.cancion!.id, 'nueva');
    expect(r.leGusta, isFalse); // antes (por índice) habría dado true

    r.reproducir(1); // 'a' en su nueva posición
    expect(r.leGusta, isTrue);
  });

  test(
    'si el catálogo se achica, cancion no rompe con índice fuera de rango',
    () {
      final catalogo = _CatalogoCambiante([_c('a'), _c('b'), _c('c')]);
      final r = ControladorReproduccion(repositorioCatalogo: catalogo);
      addTearDown(r.dispose);

      r.reproducir(2);
      catalogo.reemplazar([_c('a')]);
      expect(r.cancion, isNull);
      expect(r.total, 0);
      expect(r.leGusta, isFalse);
      r.alternarMeGusta(); // sin canción válida: no hace nada
    },
  );

  test('leGusta refleja lo cargado del repositorio al cambiar de usuario', () {
    final catalogo = _CatalogoCambiante([_c('a')]);
    final seguimiento = RepositorioSeguimientoMemoria()..usarUsuario('u1');
    final r = ControladorReproduccion(
      repositorioCatalogo: catalogo,
      repositorioSeguimiento: seguimiento,
    );
    addTearDown(r.dispose);

    r.reproducir(0);
    r.alternarMeGusta();
    expect(r.leGusta, isTrue);

    seguimiento.usarUsuario('u2');
    expect(r.leGusta, isFalse);
  });

  test('alternarMeGusta notifica al reproductor', () {
    final r = ControladorReproduccion(
      repositorioCatalogo: _CatalogoCambiante([_c('a')]),
    );
    addTearDown(r.dispose);
    r.reproducir(0);
    var notificaciones = 0;
    r.addListener(() => notificaciones++);
    r.alternarMeGusta();
    expect(notificaciones, 1);
    expect(r.leGusta, isTrue);
  });
}
