import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/theme/colores.dart';

// Lista de canciones del artista (datos de ejemplo, realistas).
// Cada una con un color de "portada" distinto para simular variedad visual.
final List<Cancion> canciones = [
  Cancion(
    id: 'luces-de-la-ciudad',
    titulo: 'Luces de la Ciudad',
    duracionSegundos: 204,
    reproducciones: 48302,
    tendencia: '+12% esta semana',
    lugar: 'Buenos Aires, AR',
    horarioPico: '21hs - 23hs',
    colorPortada: colorAcento.toARGB32(),
  ),
  Cancion(
    id: 'otra-vuelta',
    titulo: 'Otra Vuelta',
    duracionSegundos: 177,
    reproducciones: 31750,
    tendencia: '+5% esta semana',
    lugar: 'Córdoba, AR',
    horarioPico: '18hs - 20hs',
    colorPortada: colorAzul.toARGB32(),
  ),
  Cancion(
    id: 'sin-senal',
    titulo: 'Sin Señal',
    duracionSegundos: 242,
    reproducciones: 22140,
    tendencia: '+21% esta semana',
    lugar: 'Mendoza, AR',
    horarioPico: '12hs - 14hs',
    colorPortada: colorVerificado.toARGB32(),
  ),
  Cancion(
    id: 'ruta-7',
    titulo: 'Ruta 7',
    duracionSegundos: 191,
    reproducciones: 15890,
    tendencia: '+3% esta semana',
    lugar: 'Rosario, AR',
    horarioPico: '08hs - 10hs',
    colorPortada: colorMagenta.toARGB32(),
  ),
];

// Álbumes del artista (datos de ejemplo).
final List<Album> albumes = [
  Album(
    titulo: 'Postales',
    anio: '2024',
    colorPortada: colorAcento.toARGB32(),
    cancionIds: ['luces-de-la-ciudad', 'otra-vuelta'],
  ),
  Album(
    titulo: 'Sin Señal EP',
    anio: '2023',
    colorPortada: colorVerificado.toARGB32(),
    cancionIds: ['sin-senal', 'ruta-7'],
  ),
];

final List<Entrada> entradas = [
  Entrada(
    concierto: 'Mateo Cabral en vivo',
    lugar: 'Teatro Independencia, Mendoza',
    fecha: DateTime(2026, 12, 5),
    precio: 15000,
    cantidad: 2,
  ),
  Entrada(
    concierto: 'Luna Roja Tour',
    lugar: 'Arena Maipú, Mendoza',
    fecha: DateTime(2027, 1, 18),
    precio: 22000,
    cantidad: 1,
  ),
  Entrada(
    concierto: 'Noche de Rock Local',
    lugar: 'Club Cervantes, Mendoza',
    fecha: DateTime(2027, 2, 6),
    precio: 9000,
    cantidad: 4,
  ),
];

final List<Concierto> conciertos = [
  Concierto(
    nombre: 'Mateo Cabral en vivo',
    lugar: 'Teatro Independencia, Mendoza',
    fecha: DateTime(2026, 12, 5),
    precio: 15000,
    disponibles: 120,
  ),
  Concierto(
    nombre: 'Luna Roja Tour',
    lugar: 'Arena Maipú, Mendoza',
    fecha: DateTime(2027, 1, 18),
    precio: 22000,
    disponibles: 80,
  ),
  Concierto(
    nombre: 'Noche de Rock Local',
    lugar: 'Club Cervantes, Mendoza',
    fecha: DateTime(2027, 2, 6),
    precio: 9000,
    disponibles: 200,
  ),
  Concierto(
    nombre: 'Festival Cuyo Sound',
    lugar: 'Estadio Malvinas Argentinas, Mendoza',
    fecha: DateTime(2027, 3, 20),
    precio: 18000,
    disponibles: 0,
  ),
];

final List<Movimiento> movimientos = [
  Movimiento(
    tipo: 'Venta',
    detalle: 'Mateo Cabral en vivo x2',
    monto: 30000,
    fecha: DateTime(2026, 11, 2),
  ),
  Movimiento(
    tipo: 'Donación',
    detalle: 'Donación de un fan',
    monto: 5000,
    fecha: DateTime(2026, 11, 4),
  ),
  Movimiento(
    tipo: 'Venta',
    detalle: 'Luna Roja Tour x1',
    monto: 22000,
    fecha: DateTime(2026, 11, 5),
  ),
];
