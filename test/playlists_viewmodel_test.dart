import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';

void main() {
  test('crear, agregar, quitar y eliminar playlists notifican', () {
    final vm = PlaylistsViewModel();
    var notificaciones = 0;
    vm.addListener(() => notificaciones++);

    final p = vm.crear('  Mis favoritas  ');
    expect(p.nombre, 'Mis favoritas'); // se recorta el texto
    expect(vm.playlists.length, 1);
    expect(notificaciones, 1);

    vm.agregarCancion(p.id, 'c1');
    vm.agregarCancion(p.id, 'c2');
    vm.agregarCancion(p.id, 'c1'); // duplicado: no se agrega dos veces
    expect(p.cancionIds, ['c1', 'c2']);
    expect(notificaciones, 3);

    vm.quitarCancion(p.id, 'c1');
    expect(p.cancionIds, ['c2']);
    expect(notificaciones, 4);

    // Quitar una que no está no notifica.
    vm.quitarCancion(p.id, 'c999');
    expect(notificaciones, 4);

    vm.eliminar(p.id);
    expect(vm.playlists, isEmpty);
    expect(notificaciones, 5);
  });

  test('renombrar actualiza el nombre y notifica una sola vez', () {
    final vm = PlaylistsViewModel();
    final p = vm.crear('Viejo');
    var notificaciones = 0;
    vm.addListener(() => notificaciones++);

    vm.renombrar(p.id, 'Nuevo');
    expect(p.nombre, 'Nuevo');
    expect(notificaciones, 1);

    // Mismo nombre: no hay cambio, no notifica.
    vm.renombrar(p.id, 'Nuevo');
    expect(notificaciones, 1);
  });

  test('porId encuentra la playlist o devuelve null', () {
    final vm = PlaylistsViewModel();
    expect(vm.porId('no-existe'), isNull);
    final p = vm.crear('Una');
    expect(vm.porId(p.id), same(p));
  });
}
