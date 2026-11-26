import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:streamtunes_demo/data/playlists_dao.dart';
import 'package:streamtunes_demo/data/repositorio_playlists.dart';
import 'package:streamtunes_demo/data/repositorio_playlists_sqlite.dart';
import 'package:streamtunes_demo/models/playlist.dart';

import 'dobles_persistencia.dart';

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

  group('RepositorioPlaylistsSqlite', () {
    late Database db;
    late PlaylistsDao dao;

    setUp(() async {
      db = await baseEnMemoria();
      dao = PlaylistsDao(db);
    });
    tearDown(() => db.close());

    // Un repositorio nuevo sobre la misma base = reabrir la app.
    Future<RepositorioPlaylistsSqlite> abrir(String? uid) async {
      final r = RepositorioPlaylistsSqlite(dao: dao)..usarUsuario(uid);
      await r.listo;
      return r;
    }

    test('guarda y vuelve a cargar las playlists del usuario', () async {
      final r = await abrir('u1');
      final p = r.crear('Ruta');
      r.agregarCancion(p.id, 'ruta-7');
      r.agregarCancion(p.id, 'sin-senal');
      r.renombrar(p.id, 'Viaje');
      r.crear('Segunda');
      await r.escrituras;

      final reabierto = await abrir('u1');
      expect(reabierto.playlists.map((p) => p.nombre), ['Viaje', 'Segunda']);
      final cargada = reabierto.playlists.first;
      expect(cargada.id, p.id);
      expect(cargada.cancionIds, ['ruta-7', 'sin-senal']);
    });

    test('quitar canciones y eliminar también se guardan', () async {
      final r = await abrir('u1');
      final p = r.crear('Una');
      r.agregarCancion(p.id, 'a');
      r.agregarCancion(p.id, 'b');
      r.quitarCancion(p.id, 'a');
      final borrar = r.crear('Borrar');
      r.eliminar(borrar.id);
      await r.escrituras;

      final reabierto = await abrir('u1');
      expect(reabierto.playlists.single.cancionIds, ['b']);
      // ON DELETE CASCADE: no quedan canciones huérfanas.
      final huerfanas = await db.rawQuery(
        'SELECT * FROM playlist_canciones WHERE playlist_id = ?',
        [borrar.id],
      );
      expect(huerfanas, isEmpty);
    });

    test('separa los datos por usuario', () async {
      final r = await abrir('u1');
      r.crear('Solo de u1');

      r.usarUsuario('u2');
      expect(r.playlists, isEmpty); // se vacía en el acto
      await r.listo;
      expect(r.playlists, isEmpty);
      r.crear('Solo de u2');

      r.usarUsuario('u1');
      await r.listo;
      expect(r.playlists.map((p) => p.nombre), ['Solo de u1']);
    });

    test('sin usuario (invitado) no guarda nada', () async {
      final r = await abrir(null);
      r.crear('Temporal');
      expect(r.playlists.length, 1); // funciona en memoria
      await r.escrituras;
      expect(await db.query('playlists'), isEmpty); // pero no se persiste
    });

    test('mientras carga avisa "cargando" y al terminar notifica', () async {
      await dao.reemplazarDeUsuario('u1', [Playlist(id: 'p1', nombre: 'Uno')]);
      final r = RepositorioPlaylistsSqlite(dao: dao);
      var notificaciones = 0;
      r.addListener(() => notificaciones++);

      r.usarUsuario('u1');
      expect(r.cargando, isTrue);
      expect(r.playlists, isEmpty);
      await r.listo;
      expect(r.cargando, isFalse);
      expect(r.playlists.single.id, 'p1');
      expect(notificaciones, 2); // empieza a cargar + terminó
    });

    test(
      'si cambia de usuario a mitad de la carga, no mezcla cuentas',
      () async {
        await dao.reemplazarDeUsuario('u1', [
          Playlist(id: 'p1', nombre: 'De u1'),
        ]);
        final r = RepositorioPlaylistsSqlite(dao: dao)..usarUsuario('u1');
        r.usarUsuario('u2'); // antes de que termine la carga de u1
        await r.listo;
        expect(r.playlists, isEmpty);
      },
    );

    test('lo creado durante la carga se suma a lo guardado', () async {
      await dao.reemplazarDeUsuario('u1', [
        Playlist(id: 'p1', nombre: 'Vieja'),
      ]);
      final r = RepositorioPlaylistsSqlite(dao: dao)..usarUsuario('u1');
      r.crear('Nueva'); // antes de que llegue lo guardado
      await r.listo;
      await r.escrituras;
      expect(r.playlists.map((p) => p.nombre), ['Vieja', 'Nueva']);

      final reabierto = await abrir('u1');
      expect(reabierto.playlists.map((p) => p.nombre), ['Vieja', 'Nueva']);
    });

    group('migración desde shared_preferences (JSON)', () {
      test('importa las playlists viejas y borra la clave', () async {
        final prefs = preferenciasEnMemoria({
          RepositorioPlaylistsSqlite.claveVieja('u1'):
              '[{"id":"p1","nombre":"Vieja","cancionIds":["a","b"]}]',
        });
        final r = RepositorioPlaylistsSqlite(dao: dao, prefsViejas: prefs)
          ..usarUsuario('u1');
        await r.listo;

        expect(r.playlists.single.nombre, 'Vieja');
        expect(r.playlists.single.cancionIds, ['a', 'b']);
        expect(
          await prefs.getString(RepositorioPlaylistsSqlite.claveVieja('u1')),
          isNull,
        );
        // Quedaron en SQLite: sin la clave vieja se siguen leyendo.
        expect((await dao.deUsuario('u1')).single.id, 'p1');
      });

      test('si ya hay datos en SQLite no pisa con los viejos', () async {
        await dao.reemplazarDeUsuario('u1', [
          Playlist(id: 'nueva', nombre: 'Nueva'),
        ]);
        final prefs = preferenciasEnMemoria({
          RepositorioPlaylistsSqlite.claveVieja('u1'):
              '[{"id":"vieja","nombre":"Vieja"}]',
        });
        final r = RepositorioPlaylistsSqlite(dao: dao, prefsViejas: prefs)
          ..usarUsuario('u1');
        await r.listo;
        expect(r.playlists.single.id, 'nueva');
      });

      test('JSON corrupto o incompleto no rompe: se ignora', () async {
        final corrupto = preferenciasEnMemoria({
          RepositorioPlaylistsSqlite.claveVieja('u1'): '{no es json',
        });
        final r = RepositorioPlaylistsSqlite(dao: dao, prefsViejas: corrupto)
          ..usarUsuario('u1');
        await r.listo;
        expect(r.playlists, isEmpty);

        final incompleto = preferenciasEnMemoria({
          RepositorioPlaylistsSqlite.claveVieja('u2'): '[{"nombre":"sin id"},{"id":"p1","nombre":"Ok","cancionIds":["a",3]}]',
        });
        final r2 = RepositorioPlaylistsSqlite(dao: dao, prefsViejas: incompleto)
          ..usarUsuario('u2');
        await r2.listo;
        expect(r2.playlists.single.id, 'p1');
        expect(r2.playlists.single.cancionIds, ['a']);
      });
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
