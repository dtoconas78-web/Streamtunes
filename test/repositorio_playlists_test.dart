import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/data/repositorio_playlists_preferencias.dart';
import 'package:streamtunes_demo/models/playlist.dart';

Future<SharedPreferences> _prefs([Map<String, Object> valores = const {}]) {
  SharedPreferences.setMockInitialValues(valores);
  return SharedPreferences.getInstance();
}

void main() {
  group('RepositorioPlaylistsMemoria', () {
    test('ids únicos aunque se creen varias seguidas', () {
      final r = RepositorioPlaylistsMemoria();
      final ids = {for (var i = 0; i < 20; i++) r.crear('P$i').id};
      expect(ids.length, 20);
    });

    test('cambiar de usuario descarta las playlists del anterior', () {
      final r = RepositorioPlaylistsMemoria()..usarUsuario('u1');
      r.crear('De u1');
      var notificaciones = 0;
      r.addListener(() => notificaciones++);

      r.usarUsuario('u2');
      expect(r.playlists, isEmpty);
      expect(notificaciones, 1);

      // Mismo usuario: no hace nada ni notifica.
      r.usarUsuario('u2');
      expect(notificaciones, 1);
    });
  });

  group('RepositorioPlaylistsPreferencias', () {
    test('guarda y vuelve a cargar las playlists del usuario', () async {
      final prefs = await _prefs();
      final r = RepositorioPlaylistsPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      final p = r.crear('Ruta');
      r.agregarCancion(p.id, 'ruta-7');
      r.agregarCancion(p.id, 'sin-senal');
      r.renombrar(p.id, 'Viaje');

      // Un repositorio nuevo (como al reabrir la app) lee lo guardado.
      final reabierto = RepositorioPlaylistsPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      expect(reabierto.playlists.length, 1);
      final cargada = reabierto.playlists.single;
      expect(cargada.id, p.id);
      expect(cargada.nombre, 'Viaje');
      expect(cargada.cancionIds, ['ruta-7', 'sin-senal']);
    });

    test('separa los datos por usuario', () async {
      final prefs = await _prefs();
      final r = RepositorioPlaylistsPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      r.crear('Solo de u1');

      r.usarUsuario('u2');
      expect(r.playlists, isEmpty);
      r.crear('Solo de u2');

      r.usarUsuario('u1');
      expect(r.playlists.map((p) => p.nombre), ['Solo de u1']);
    });

    test('sin usuario (invitado) no guarda nada', () async {
      final prefs = await _prefs();
      final r = RepositorioPlaylistsPreferencias(prefs: prefs);
      r.crear('Temporal');
      expect(r.playlists.length, 1); // funciona en memoria
      expect(prefs.getKeys(), isEmpty); // pero no se persiste
    });

    test('eliminar también se guarda', () async {
      final prefs = await _prefs();
      final r = RepositorioPlaylistsPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      final p = r.crear('Borrar');
      r.eliminar(p.id);

      final reabierto = RepositorioPlaylistsPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      expect(reabierto.playlists, isEmpty);
    });

    test('JSON corrupto o incompleto no rompe: se ignora', () async {
      final corrupto = await _prefs({
        RepositorioPlaylistsPreferencias.clave('u1'): '{no es json',
      });
      final r = RepositorioPlaylistsPreferencias(prefs: corrupto)
        ..usarUsuario('u1');
      expect(r.playlists, isEmpty);

      final incompleto = await _prefs({
        RepositorioPlaylistsPreferencias.clave('u1'): '[{"nombre":"sin id"},{"id":"p1","nombre":"Ok","cancionIds":["a",3]}]',
      });
      final r2 = RepositorioPlaylistsPreferencias(prefs: incompleto)
        ..usarUsuario('u1');
      expect(r2.playlists.single.id, 'p1');
      expect(r2.playlists.single.cancionIds, ['a']);
    });
  });

  test('Playlist: ida y vuelta toMap/fromMap', () {
    final p = Playlist(id: 'p1', nombre: 'Una', cancionIds: ['a', 'b']);
    final copia = Playlist.fromMap(p.toMap())!;
    expect(copia.id, 'p1');
    expect(copia.nombre, 'Una');
    expect(copia.cancionIds, ['a', 'b']);
    expect(Playlist.fromMap('no es un mapa'), isNull);
  });
}
