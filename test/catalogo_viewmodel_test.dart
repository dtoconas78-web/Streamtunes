import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

Cancion _cancion(String titulo, {required String id}) => Cancion(
  id: id,
  titulo: titulo,
  duracionSegundos: 180,
  reproducciones: 0,
  tendencia: 'Recién publicada',
  lugar: 'Sin datos todavía',
  horarioPico: 'Sin datos todavía',
  colorPortada: 0xFFFF5500,
);

void main() {
  test('publicar una canción suelta la agrega y notifica', () {
    final c = CatalogoViewModel(repositorio: RepositorioCatalogoMemoria());
    final antes = c.canciones.length;
    final albumesAntes = c.albumes.length;
    var notificaciones = 0;
    c.addListener(() => notificaciones++);

    c.publicar(
      nuevas: [_cancion('Nueva', id: 'nueva')],
      colorPortada: 0xFFFF5500,
    );

    expect(c.canciones.length, antes + 1);
    expect(c.canciones.last.titulo, 'Nueva');
    expect(c.albumes.length, albumesAntes); // sin álbum nuevo
    expect(notificaciones, 1);
  });

  test('publicar un álbum agrega las canciones y el álbum con sus índices', () {
    final c = CatalogoViewModel(repositorio: RepositorioCatalogoMemoria());
    final antes = c.canciones.length;

    c.publicar(
      nuevas: [
        _cancion('Tema 1', id: 'tema-1'),
        _cancion('Tema 2', id: 'tema-2'),
      ],
      tituloAlbum: 'Mi álbum',
      anioAlbum: '2026',
      colorPortada: 0xFF00BFA5,
    );

    expect(c.canciones.length, antes + 2);
    final album = c.albumes.last;
    expect(album.titulo, 'Mi álbum');
    expect(album.anio, '2026');
    expect(album.cancionIds, ['tema-1', 'tema-2']);
  });

  test('los álbumes publicados tienen ids únicos, aun desde VMs nuevos', () {
    // Simula dos arranques de la app sobre el mismo catálogo: antes ambos
    // generaban 'album-publicado-1' y con Firestore el segundo pisaba al primero.
    final repo = RepositorioCatalogoMemoria();
    for (final (i, vm) in [
      CatalogoViewModel(repositorio: repo),
      CatalogoViewModel(repositorio: repo),
    ].indexed) {
      vm.publicar(
        nuevas: [_cancion('Tema $i', id: 'tema-unico-$i')],
        tituloAlbum: 'Álbum $i',
        colorPortada: 0xFFFF5500,
      );
    }
    final ids = repo.albumes.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.where((id) => id.startsWith('album-publicado-')).length, 2);
  });
}
