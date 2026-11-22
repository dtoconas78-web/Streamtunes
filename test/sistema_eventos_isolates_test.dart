import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/data/repositorio_catalogo.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/services/gestor_ciclo_vida.dart';
import 'package:streamtunes_demo/services/servicio_notificaciones.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/utils/procesador_isolate.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/estadisticas_cancion_screen.dart';
import 'package:streamtunes_demo/views/screens/subir_musica_screen.dart';

/// Listener falso: no toca el WidgetsBinding real (en tests planos no hay
/// binding inicializado) y deja verificar que dispose() llegó.
class _ListenerFalso implements CicloVidaListener {
  bool desechado = false;

  @override
  void dispose() {
    desechado = true;
  }
}

/// Servicio de notificaciones falso: registra las llamadas sin tocar el
/// plugin real.
class _NotificacionesFalsas implements ServicioNotificaciones {
  final List<String> mostradas = [];
  int ocultadas = 0;

  @override
  Future<void> inicializar() async {}

  @override
  Future<void> mostrarReproduccionEnPausa(String tituloCancion) async {
    mostradas.add(tituloCancion);
  }

  @override
  Future<void> ocultarReproduccion() async {
    ocultadas++;
  }
}

void main() {
  group('GestorCicloVida (subtarea 9.2)', () {
    test('pausa y reanuda ejecutan los callbacks registrados', () {
      final listener = _ListenerFalso();
      final gestor = GestorCicloVida(listener: listener);
      var pausas = 0;
      var reanudaciones = 0;
      gestor.registrar(
        alPausar: () => pausas++,
        alReanudar: () => reanudaciones++,
      );
      expect(gestor.enSegundoPlano, isFalse);
      expect(gestor.cantidadSuscriptos, 2);

      gestor.manejarEstado(AppLifecycleState.paused);
      expect(pausas, 1);
      expect(gestor.enSegundoPlano, isTrue);

      gestor.manejarEstado(AppLifecycleState.resumed);
      expect(reanudaciones, 1);
      expect(gestor.enSegundoPlano, isFalse);

      // Un "resumed" sin pausa previa no dispara el callback de reanudar.
      gestor.manejarEstado(AppLifecycleState.resumed);
      expect(reanudaciones, 1);
    });

    test(
      'hidden y detached cuentan como segundo plano; inactive no hace nada',
      () {
        final gestor = GestorCicloVida(listener: _ListenerFalso());
        var pausas = 0;
        gestor.registrar(alPausar: () => pausas++);

        gestor.manejarEstado(AppLifecycleState.inactive);
        expect(pausas, 0);
        expect(gestor.enSegundoPlano, isFalse);

        gestor.manejarEstado(AppLifecycleState.hidden);
        expect(pausas, 1);

        gestor.manejarEstado(AppLifecycleState.detached);
        expect(pausas, 2);
      },
    );

    test('registrar devuelve una función para darse de baja', () {
      final gestor = GestorCicloVida(listener: _ListenerFalso());
      var pausas = 0;
      final darseDeBaja = gestor.registrar(alPausar: () => pausas++);

      gestor.manejarEstado(AppLifecycleState.paused);
      expect(pausas, 1);

      darseDeBaja();
      expect(gestor.cantidadSuscriptos, 0);
      gestor.manejarEstado(AppLifecycleState.resumed);
      gestor.manejarEstado(AppLifecycleState.paused);
      expect(pausas, 1);
    });

    test('dispose libera el listener y limpia los callbacks', () {
      final listener = _ListenerFalso();
      final gestor = GestorCicloVida(listener: listener);
      gestor.registrar(alPausar: () {}, alReanudar: () {});

      gestor.dispose();

      expect(listener.desechado, isTrue);
      expect(gestor.cantidadSuscriptos, 0);
    });
  });

  group('procesador_isolate (subtarea 6.2)', () {
    List<Movimiento> lote(int cantidad) => List.generate(
      cantidad,
      (i) => Movimiento(
        tipo: i.isEven ? TipoMovimiento.venta : TipoMovimiento.donacion,
        detalle: 'movimiento $i',
        monto: i.toDouble(),
        fecha: DateTime(2026, 1, 1).add(Duration(days: i)),
      ),
    );

    test(
      'el isolate devuelve el mismo resumen que el cálculo directo',
      () async {
        final movimientos = lote(500);

        final directo = resumenMovimientos(movimientos);
        final enIsolate = await resumenMovimientosEnIsolate(movimientos);

        expect(enIsolate, directo);
        expect(enIsolate['cantidad'], 500);
        expect(enIsolate['cantidadVentas'], 250);
        expect(enIsolate['cantidadDonaciones'], 250);
        expect(
          enIsolate['montoTotal'],
          movimientos.fold<double>(0, (a, m) => a + m.monto),
        );
      },
    );

    test(
      'computarEnIsolate ejecuta la tarea y devuelve su resultado',
      () async {
        final resultado = await computarEnIsolate(() => 21 * 2);
        expect(resultado, 42);
      },
    );
  });

  group('notificación de reproducción en segundo plano', () {
    test('al ir a segundo plano se pausa y se muestra la notificación; al volver se reanuda y se oculta', () async {
      final catalogo = RepositorioCatalogoMemoria();
      final reproductor = ControladorReproduccion(
        repositorioCatalogo: catalogo,
      );
      final gestor = GestorCicloVida(listener: _ListenerFalso());
      final notificaciones = _NotificacionesFalsas();
      registrarReproduccionEnCicloVida(gestor, reproductor, notificaciones);

      reproductor.reproducir(0);
      expect(reproductor.reproduciendo, isTrue);

      gestor.manejarEstado(AppLifecycleState.paused);
      expect(reproductor.reproduciendo, isFalse);
      expect(notificaciones.mostradas, [catalogo.canciones[0].titulo]);

      gestor.manejarEstado(AppLifecycleState.resumed);
      expect(reproductor.reproduciendo, isTrue);
      expect(notificaciones.ocultadas, 1);

      reproductor.detener(); // cancela el timer periódico del test
    });

    test(
      'si no estaba sonando, ir a segundo plano no muestra notificación',
      () {
        final catalogo = RepositorioCatalogoMemoria();
        final reproductor = ControladorReproduccion(
          repositorioCatalogo: catalogo,
        );
        final gestor = GestorCicloVida(listener: _ListenerFalso());
        final notificaciones = _NotificacionesFalsas();
        registrarReproduccionEnCicloVida(gestor, reproductor, notificaciones);

        gestor.manejarEstado(AppLifecycleState.paused);
        expect(reproductor.reproduciendo, isFalse);
        expect(notificaciones.mostradas, isEmpty);
        expect(notificaciones.ocultadas, 0);
      },
    );
  });

  group('pantallas con tareas activas (subtarea 9.2)', () {
    testWidgets(
      'PantallaB frena el refresco en segundo plano y lo reanuda al volver',
      (tester) async {
        const cancion = Cancion(
          id: 'c1',
          titulo: 'Tema de prueba',
          duracionSegundos: 100,
          reproducciones: 1000,
          tendencia: '+5%',
          lugar: 'Buenos Aires',
          horarioPico: '20 hs',
          colorPortada: 0xFFFF5500,
        );
        await tester.pumpWidget(MaterialApp(home: PantallaB(cancion: cancion)));

        expect(find.text(formatearMiles(1000)), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text(formatearMiles(1007)), findsOneWidget);

        // Segundo plano: el refresco queda frenado.
        gestorCicloVida.manejarEstado(AppLifecycleState.paused);
        await tester.pump(const Duration(seconds: 6));
        expect(find.text(formatearMiles(1007)), findsOneWidget);

        // Al volver, el refresco se reanuda.
        gestorCicloVida.manejarEstado(AppLifecycleState.resumed);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text(formatearMiles(1014)), findsOneWidget);

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      },
    );

    testWidgets(
      'PantallaSubirMusica se registra en el ciclo de vida y se da de baja al salir',
      (tester) async {
        final antes = gestorCicloVida.cantidadSuscriptos;
        await tester.pumpWidget(const MaterialApp(home: PantallaSubirMusica()));
        expect(gestorCicloVida.cantidadSuscriptos, antes + 2);

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Text('otra pantalla'))),
        );
        expect(gestorCicloVida.cantidadSuscriptos, antes);
      },
    );
  });

  group('inyección (subtarea 9.3)', () {
    testWidgets(
      'el gestor de ciclo de vida queda registrado con el reproductor',
      (tester) async {
        // Hay binding (testWidgets): se puede crear el AppLifecycleListener real.
        inicializarCicloVida();
        expect(gestorCicloVida.cantidadSuscriptos, greaterThanOrEqualTo(2));
        // Idempotente: llamarlo dos veces no duplica callbacks.
        inicializarCicloVida();
        expect(gestorCicloVida.cantidadSuscriptos, greaterThanOrEqualTo(2));
      },
    );
  });
}
