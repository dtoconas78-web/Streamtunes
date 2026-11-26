import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';

void main() {
  test(
    'los ids de un álbum del catálogo no se pueden modificar desde afuera',
    () {
      final vm = CatalogoViewModel(repositorio: RepositorioCatalogoMemoria());
      final album = vm.albumes.first;
      final antes = List.of(album.cancionIds);

      expect(() => album.cancionIds.add('intruso'), throwsUnsupportedError);
      expect(() => album.cancionIds.clear(), throwsUnsupportedError);
      expect(() => album.cancionIds[0] = 'otro', throwsUnsupportedError);
      expect(vm.albumes.first.cancionIds, antes);
    },
  );

  test('toMap entrega una copia: modificarla no cambia el álbum', () {
    final album = Album(
      id: 'a',
      titulo: 'T',
      anio: '2026',
      colorPortada: 0,
      cancionIds: ['x', 'y'],
    );
    (album.toMap()['cancionIds'] as List).add('z');
    expect(album.cancionIds, ['x', 'y']);
  });

  test('sigue teniendo constructor const e igualdad por valor', () {
    const a = Album(
      id: 'a',
      titulo: 'T',
      anio: '2026',
      colorPortada: 0,
      cancionIds: ['x'],
    );
    final b = Album(
      id: 'a',
      titulo: 'T',
      anio: '2026',
      colorPortada: 0,
      cancionIds: ['x'],
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
