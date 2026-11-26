import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/data/repositorio_foto_perfil.dart';
import 'package:streamtunes_demo/data/repositorio_portadas.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/services/almacen_fotos.dart';
import 'package:streamtunes_demo/services/fuente_de_fotos.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/foto_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/selector_foto.dart';

import 'dobles_persistencia.dart';

/// Fuente de fotos controlada por el test.
class _FuenteFalsa implements FuenteDeFotos {
  ResultadoFoto proximo = const FotoCancelada();
  ResultadoFoto perdida = const FotoCancelada();
  final List<OrigenFoto> pedidos = [];

  @override
  Future<ResultadoFoto> tomar(OrigenFoto origen) async {
    pedidos.add(origen);
    return proximo;
  }

  @override
  Future<ResultadoFoto> recuperarPerdida() async => perdida;
}

void main() {
  late Directory raiz;
  late Directory documentos;
  late Directory temporales;
  late AlmacenFotosLocal almacen;
  late _FuenteFalsa fuente;

  // Archivo que "devuelve la cámara" (temporal del sistema).
  String fotoDeCamara(String nombre) {
    final f = File('${raiz.path}/$nombre')..writeAsBytesSync([1, 2, 3]);
    return f.path;
  }

  setUp(() {
    raiz = Directory.systemTemp.createTempSync('streamtunes-fotos');
    documentos = Directory('${raiz.path}/docs')..createSync();
    temporales = Directory('${raiz.path}/tmp')..createSync();
    almacen = AlmacenFotosLocal(
      documentos: () async => documentos,
      temporales: () async => temporales,
    );
    fuente = _FuenteFalsa();
  });
  tearDown(() => raiz.deleteSync(recursive: true));

  group('AlmacenFotosLocal', () {
    test('copia a documentos (o temporales) con prefijo y extensión', () async {
      final origen = fotoDeCamara('IMG_1.PNG');
      final ruta = await almacen.guardar(origen, prefijo: 'perfil');
      expect(ruta, startsWith('${documentos.path}/fotos/perfil-'));
      expect(ruta, endsWith('.png'));
      expect(File(ruta).readAsBytesSync(), [1, 2, 3]);

      final tmp = await almacen.guardar(
        origen,
        prefijo: 'documento',
        temporal: true,
      );
      expect(tmp, startsWith(temporales.path));
    });

    test('borrar no falla si el archivo ya no existe', () async {
      await almacen.borrar('${raiz.path}/no-existe.jpg');
      expect(almacen.existe('${raiz.path}/no-existe.jpg'), isFalse);
    });
  });

  group('FotoViewModel', () {
    late List<String?> guardadas;
    late List<bool> pendientes;
    late FotoViewModel vm;

    setUp(() {
      guardadas = [];
      pendientes = [];
      vm = FotoViewModel(
        fuente: fuente,
        almacen: almacen,
        prefijo: 'perfil',
        alGuardar: (r) async => guardadas.add(r),
        alPendiente: (p) async => pendientes.add(p),
      );
    });

    test('foto: la copia, guarda la ruta y borra la anterior', () async {
      fuente.proximo = FotoTomada(fotoDeCamara('a.jpg'));
      final r1 = await vm.elegir(OrigenFoto.galeria);
      expect(r1, isA<FotoTomada>());
      final primera = vm.ruta!;
      expect(File(primera).existsSync(), isTrue);

      fuente.proximo = FotoTomada(fotoDeCamara('b.jpg'));
      await vm.elegir(OrigenFoto.galeria);
      expect(vm.ruta, isNot(primera));
      expect(File(primera).existsSync(), isFalse); // no se acumulan
      expect(guardadas, [primera, vm.ruta]); // se guarda la RUTA
      expect(vm.cargando, isFalse);
    });

    test('cancelar no cambia nada', () async {
      fuente.proximo = FotoTomada(fotoDeCamara('a.jpg'));
      await vm.elegir(OrigenFoto.galeria);
      final antes = vm.ruta;
      fuente.proximo = const FotoCancelada();
      expect(await vm.elegir(OrigenFoto.galeria), isA<FotoCancelada>());
      expect(vm.ruta, antes);
      expect(vm.ultimoError, isNull);
      expect(guardadas, hasLength(1));
    });

    test('error (p. ej. sin permiso): queda en ultimoError', () async {
      fuente.proximo = FotoFallida(StateError('camera_access_denied'));
      expect(await vm.elegir(OrigenFoto.camara), isA<FotoFallida>());
      expect(vm.ultimoError, isA<StateError>());
      expect(vm.ruta, isNull);
      expect(guardadas, isEmpty);
    });

    test(
      'con la cámara marca pendiente y lo desmarca; con galería no',
      () async {
        await vm.elegir(OrigenFoto.camara);
        expect(pendientes, [true, false]);
        await vm.elegir(OrigenFoto.galeria);
        expect(pendientes, [true, false]);
        expect(fuente.pedidos, [OrigenFoto.camara, OrigenFoto.galeria]);
      },
    );

    test('recupera la foto perdida si Android cerró la app', () async {
      fuente.perdida = FotoTomada(fotoDeCamara('perdida.jpg'));
      await vm.recuperarPerdida();
      expect(vm.ruta, isNotNull);
      expect(guardadas, [vm.ruta]);
      expect(pendientes, [false]);
    });

    test('quitar borra el archivo y guarda null', () async {
      fuente.proximo = FotoTomada(fotoDeCamara('a.jpg'));
      await vm.elegir(OrigenFoto.galeria);
      final ruta = vm.ruta!;
      await vm.quitar();
      expect(vm.ruta, isNull);
      expect(File(ruta).existsSync(), isFalse);
      expect(guardadas.last, isNull);
    });

    test('descartar borra sin guardar nada', () async {
      fuente.proximo = FotoTomada(fotoDeCamara('a.jpg'));
      await vm.elegir(OrigenFoto.galeria);
      final ruta = vm.ruta!;
      await vm.descartar();
      expect(File(ruta).existsSync(), isFalse);
      expect(guardadas, [ruta]); // solo el guardado al elegir
    });

    test('mostrar una ruta cuyo archivo ya no existe deja sin foto', () {
      vm.mostrar('${raiz.path}/borrada.jpg');
      expect(vm.ruta, isNull);
      final existente = fotoDeCamara('ok.jpg');
      vm.mostrar(existente);
      expect(vm.ruta, existente);
      expect(guardadas, isEmpty); // mostrar no persiste
    });

    test('temporal: la foto del documento va a la carpeta temporal', () async {
      final doc = FotoViewModel(
        fuente: fuente,
        almacen: almacen,
        prefijo: 'documento',
        temporal: true,
      );
      fuente.proximo = FotoTomada(fotoDeCamara('dni.jpg'));
      await doc.elegir(OrigenFoto.camara);
      expect(doc.ruta, startsWith(temporales.path));
    });
  });

  group('repositorios', () {
    test('portadas en SQLite: se guardan y se vuelven a cargar', () async {
      final db = await baseEnMemoria();
      final repo = RepositorioPortadasSqlite(db);
      await repo.asignar(['album-1', 'c1', 'c2'], '/fotos/portada.jpg');
      expect(repo.rutaDe('c1'), '/fotos/portada.jpg');

      final reabierto = RepositorioPortadasSqlite(db);
      expect(reabierto.rutaDe('c2'), isNull);
      await reabierto.cargar();
      expect(reabierto.rutaDe('album-1'), '/fotos/portada.jpg');
      expect(reabierto.rutaDe('otra'), isNull);
      await db.close();
    });

    test('foto de perfil por usuario y marca de pendiente', () async {
      final prefs = preferenciasEnMemoria();
      final repo = RepositorioFotoPerfilPreferencias(prefs: prefs);
      await repo.guardar('u1', '/fotos/perfil.jpg');
      expect(await repo.leer('u1'), '/fotos/perfil.jpg');
      expect(await repo.leer('u2'), isNull);
      await repo.guardar('u1', null);
      expect(await repo.leer('u1'), isNull);

      expect(await repo.pendiente(), isFalse);
      await repo.marcarPendiente(true);
      expect(await repo.pendiente(), isTrue);
    });
  });

  test('publicar un álbum devuelve su id (para la portada)', () {
    final vm = CatalogoViewModel(repositorio: RepositorioCatalogoMemoria());
    const c = Cancion(
      id: 'nueva',
      titulo: 'Nueva',
      duracionSegundos: 100,
      reproducciones: 0,
      tendencia: '',
      lugar: '',
      horarioPico: '',
      colorPortada: 0,
    );
    final id = vm.publicar(nuevas: [c], tituloAlbum: 'Disco', colorPortada: 0);
    expect(vm.albumes.any((a) => a.id == id), isTrue);
    expect(
      vm.publicar(
        nuevas: [
          const Cancion(
            id: 'suelta',
            titulo: 'Suelta',
            duracionSegundos: 100,
            reproducciones: 0,
            tendencia: '',
            lugar: '',
            horarioPico: '',
            colorPortada: 0,
          ),
        ],
        colorPortada: 0,
      ),
      isNull,
    );
  });

  group('cambiarFoto (hoja cámara / galería)', () {
    Future<FotoViewModel> abrir(
      WidgetTester tester, {
      required bool camara,
    }) async {
      final vm = FotoViewModel(
        fuente: fuente,
        almacen: almacen,
        prefijo: 'perfil',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => cambiarFoto(
                  context,
                  vm,
                  titulo: 'Foto de perfil',
                  capacidades: Capacidades(camara: camara),
                  politicas: Politicas(),
                ),
                child: const Text('cambiar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('cambiar'));
      await tester.pumpAndSettle();
      return vm;
    }

    testWidgets('sin cámara disponible avisa y no abre nada', (tester) async {
      await abrir(tester, camara: false);
      expect(find.text(Politicas().avisoCamaraNoDisponible), findsOneWidget);
      expect(find.text('Sacar una foto'), findsNothing);
      expect(fuente.pedidos, isEmpty);
    });

    testWidgets('ofrece cámara y galería; si falla, avisa', (tester) async {
      await abrir(tester, camara: true);
      expect(find.text('Sacar una foto'), findsOneWidget);
      expect(find.text('Elegir de la galería'), findsOneWidget);
      expect(find.text('Quitar foto'), findsNothing); // todavía no hay foto

      fuente.proximo = FotoFallida(StateError('photo_access_denied'));
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(fuente.pedidos, [OrigenFoto.galeria]);
      expect(find.text(Politicas().avisoFotoFallida), findsOneWidget);
    });

    testWidgets('cancelar la cámara no muestra ningún aviso', (tester) async {
      await abrir(tester, camara: true);
      await tester.tap(find.text('Sacar una foto'));
      await tester.pumpAndSettle();
      expect(fuente.pedidos, [OrigenFoto.camara]);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
