import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

Cancion _cancion(String titulo) => Cancion(
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
    final c = CatalogoViewModel();
    final antes = c.canciones.length;
    final albumesAntes = c.albumes.length;
    var notificaciones = 0;
    c.addListener(() => notificaciones++);

    c.publicar(
      nuevas: [_cancion('Nueva')],
      colorPortada: const Color(0xFFFF5500),
    );

    expect(c.canciones.length, antes + 1);
    expect(c.canciones.last.titulo, 'Nueva');
    expect(c.albumes.length, albumesAntes); // sin álbum nuevo
    expect(notificaciones, 1);
  });

  test('publicar un álbum agrega las canciones y el álbum con sus índices', () {
    final c = CatalogoViewModel();
    final antes = c.canciones.length;

    c.publicar(
      nuevas: [_cancion('Tema 1'), _cancion('Tema 2')],
      tituloAlbum: 'Mi álbum',
      anioAlbum: '2026',
      colorPortada: const Color(0xFF00BFA5),
    );

    expect(c.canciones.length, antes + 2);
    final album = c.albumes.last;
    expect(album.titulo, 'Mi álbum');
    expect(album.anio, '2026');
    expect(album.indices, [antes, antes + 1]);
  });
}
