import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento_preferencias.dart';

import 'dobles_persistencia.dart';

// Un repositorio nuevo sobre las mismas preferencias = reabrir la app.
Future<RepositorioSeguimientoPreferencias> _abrir(
  SharedPreferencesAsync prefs,
  String? uid,
) async {
  final r = RepositorioSeguimientoPreferencias(prefs: prefs)..usarUsuario(uid);
  await r.listo;
  return r;
}

void main() {
  group('RepositorioSeguimientoMemoria', () {
    test('seguir, álbumes y me gusta notifican solo con cambios reales', () {
      final r = RepositorioSeguimientoMemoria();
      var notificaciones = 0;
      r.addListener(() => notificaciones++);

      r.seguirArtista('mateo-cabral');
      r.seguirArtista('mateo-cabral'); // repetido: no notifica
      expect(r.sigueArtista('mateo-cabral'), isTrue);
      expect(notificaciones, 1);

      r.alternarAlbum('postales');
      r.alternarMeGusta('ruta-7');
      expect(r.sigueAlbum('postales'), isTrue);
      expect(r.meGusta('ruta-7'), isTrue);
      expect(notificaciones, 3);

      r.dejarDeSeguirArtista('mateo-cabral');
      r.dejarDeSeguirArtista('mateo-cabral'); // ya no estaba: no notifica
      expect(notificaciones, 4);
    });

    test('cambiar de usuario descarta lo del anterior', () {
      final r = RepositorioSeguimientoMemoria()..usarUsuario('u1');
      r.seguirArtista('mateo-cabral');
      r.alternarMeGusta('ruta-7');

      r.usarUsuario(null);
      expect(r.artistasSeguidos, isEmpty);
      expect(r.cancionesMeGusta, isEmpty);
    });
  });

  group('RepositorioSeguimientoPreferencias', () {
    test('guarda y vuelve a cargar artistas, álbumes y me gusta', () async {
      final prefs = preferenciasEnMemoria();
      final r = await _abrir(prefs, 'u1');
      r
        ..seguirArtista('mateo-cabral')
        ..alternarAlbum('postales')
        ..alternarMeGusta('ruta-7')
        ..alternarMeGusta('sin-senal')
        ..alternarMeGusta('sin-senal'); // se quita de nuevo
      await r.escrituras;

      final reabierto = await _abrir(prefs, 'u1');
      expect(reabierto.artistasSeguidos, {'mateo-cabral'});
      expect(reabierto.albumesSeguidos, {'postales'});
      expect(reabierto.cancionesMeGusta, {'ruta-7'});
    });

    test('separa por usuario y el invitado no guarda', () async {
      final prefs = preferenciasEnMemoria();
      final r = await _abrir(prefs, 'u1');
      r.alternarMeGusta('ruta-7');

      r.usarUsuario('u2');
      expect(r.meGusta('ruta-7'), isFalse);
      await r.listo;

      r.usarUsuario(null);
      r.seguirArtista('mateo-cabral');
      await r.escrituras;
      expect(await prefs.getKeys(), {
        RepositorioSeguimientoPreferencias.clave('u1'),
      });

      r.usarUsuario('u1');
      await r.listo;
      expect(r.meGusta('ruta-7'), isTrue);
      expect(r.sigueArtista('mateo-cabral'), isFalse);
    });

    test(
      'si cambia de usuario a mitad de la carga, no mezcla cuentas',
      () async {
        final prefs = preferenciasEnMemoria({
          RepositorioSeguimientoPreferencias.clave('u1'): '{"meGusta":["a"]}',
        });
        final r = RepositorioSeguimientoPreferencias(prefs: prefs)
          ..usarUsuario('u1')
          ..usarUsuario('u2');
        await r.listo;
        expect(r.cancionesMeGusta, isEmpty);
      },
    );

    test('lo marcado durante la carga se suma a lo guardado', () async {
      final prefs = preferenciasEnMemoria({
        RepositorioSeguimientoPreferencias.clave('u1'): '{"meGusta":["a"]}',
      });
      final r = RepositorioSeguimientoPreferencias(prefs: prefs)
        ..usarUsuario('u1')
        ..alternarMeGusta('b'); // antes de que llegue lo guardado
      await r.listo;
      await r.escrituras;
      expect(r.cancionesMeGusta, {'a', 'b'});
      expect((await _abrir(prefs, 'u1')).cancionesMeGusta, {'a', 'b'});
    });

    test('JSON corrupto o con tipos raros no rompe', () async {
      final corrupto = preferenciasEnMemoria({
        RepositorioSeguimientoPreferencias.clave('u1'): 'xx',
      });
      expect((await _abrir(corrupto, 'u1')).artistasSeguidos, isEmpty);

      final raro = preferenciasEnMemoria({
        RepositorioSeguimientoPreferencias.clave('u1'):
            '{"artistas":"no-lista","meGusta":["a",1]}',
      });
      final r2 = await _abrir(raro, 'u1');
      expect(r2.artistasSeguidos, isEmpty);
      expect(r2.albumesSeguidos, isEmpty);
      expect(r2.cancionesMeGusta, {'a'});
    });
  });
}
