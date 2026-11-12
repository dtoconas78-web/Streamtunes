import 'package:flutter_test/flutter_test.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';

void main() {
  test('publicarConcierto agrega el concierto y notifica', () {
    final e = entradasViewModel;
    final antes = e.conciertosDisponibles.length;
    var notificaciones = 0;
    e.addListener(() => notificaciones++);

    e.publicarConcierto(
      nombre: 'Concierto de prueba',
      lugar: 'Teatro de prueba',
      fecha: DateTime(2027, 6, 10),
      precio: 10000,
      disponibles: 50,
    );

    expect(e.conciertosDisponibles.length, antes + 1);
    final nuevo = e.conciertosDisponibles.last;
    expect(nuevo.nombre, 'Concierto de prueba');
    expect(nuevo.disponibles, 50);
    expect(notificaciones, 1);
  });

  test('comprar descuenta entradas sin mutar el concierto original', () {
    final e = entradasViewModel;
    e.publicarConcierto(
      nombre: 'Compra de prueba',
      lugar: 'Lugar de prueba',
      fecha: DateTime(2027, 7, 10),
      precio: 5000,
      disponibles: 10,
    );
    final concierto = e.conciertosDisponibles.last;
    final entradasAntes = e.entradasCompradas.length;

    final ok = e.comprar(concierto, 3);

    expect(ok, isTrue);
    expect(e.entradasCompradas.length, entradasAntes + 1);
    // El objeto original queda intacto (inmutable); la lista tiene la copia.
    expect(concierto.disponibles, 10);
    expect(e.conciertosDisponibles.last.disponibles, 7);

    // No se puede comprar más de lo disponible.
    expect(e.comprar(e.conciertosDisponibles.last, 8), isFalse);
    expect(e.conciertosDisponibles.last.disponibles, 7);
  });
}
