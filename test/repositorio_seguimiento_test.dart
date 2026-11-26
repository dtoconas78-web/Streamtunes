import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento.dart';
import 'package:streamtunes_demo/data/repositorio_seguimiento_preferencias.dart';

Future<SharedPreferences> _prefs([Map<String, Object> valores = const {}]) {
  SharedPreferences.setMockInitialValues(valores);
  return SharedPreferences.getInstance();
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
      final prefs = await _prefs();
      RepositorioSeguimientoPreferencias(prefs: prefs)
        ..usarUsuario('u1')
        ..seguirArtista('mateo-cabral')
        ..alternarAlbum('postales')
        ..alternarMeGusta('ruta-7')
        ..alternarMeGusta('sin-senal')
        ..alternarMeGusta('sin-senal'); // se quita de nuevo

      final reabierto = RepositorioSeguimientoPreferencias(prefs: prefs)
        ..usarUsuario('u1');
      expect(reabierto.artistasSeguidos, {'mateo-cabral'});
      expect(reabierto.albumesSeguidos, {'postales'});
      expect(reabierto.cancionesMeGusta, {'ruta-7'});
    });

    test('separa por usuario y el invitado no guarda', () async {
      final prefs = await _prefs();
      final r = RepositorioSeguimientoPreferencias(prefs: prefs)
        ..usarUsuario('u1')
        ..alternarMeGusta('ruta-7');

      r.usarUsuario('u2');
      expect(r.meGusta('ruta-7'), isFalse);

      r.usarUsuario(null);
      r.seguirArtista('mateo-cabral');
      expect(prefs.getKeys(), {RepositorioSeguimientoPreferencias.clave('u1')});

      r.usarUsuario('u1');
      expect(r.meGusta('ruta-7'), isTrue);
      expect(r.sigueArtista('mateo-cabral'), isFalse);
    });

    test('JSON corrupto o con tipos raros no rompe', () async {
      final corrupto = await _prefs({
        RepositorioSeguimientoPreferencias.clave('u1'): 'xx',
      });
      final r = RepositorioSeguimientoPreferencias(prefs: corrupto)
        ..usarUsuario('u1');
      expect(r.artistasSeguidos, isEmpty);

      final raro = await _prefs({
        RepositorioSeguimientoPreferencias.clave('u1'):
            '{"artistas":"no-lista","meGusta":["a",1]}',
      });
      final r2 = RepositorioSeguimientoPreferencias(prefs: raro)
        ..usarUsuario('u1');
      expect(r2.artistasSeguidos, isEmpty);
      expect(r2.albumesSeguidos, isEmpty);
      expect(r2.cancionesMeGusta, {'a'});
    });
  });
}
