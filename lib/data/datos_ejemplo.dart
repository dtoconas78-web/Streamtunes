import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/movimiento.dart';

// Lista de canciones del artista (datos de ejemplo, realistas).
// Cada una con un color de "portada" distinto para simular variedad visual.
final List<Cancion> canciones = [
  Cancion(
    titulo: 'Luces de la Ciudad',
    duracion: '3:24',
    reproducciones: '48.302',
    tendencia: '+12% esta semana',
    lugar: 'Buenos Aires, AR',
    horarioPico: '21hs - 23hs',
    colorPortada: Color(0xFFFF5500),
  ),
  Cancion(
    titulo: 'Otra Vuelta',
    duracion: '2:57',
    reproducciones: '31.750',
    tendencia: '+5% esta semana',
    lugar: 'Córdoba, AR',
    horarioPico: '18hs - 20hs',
    colorPortada: Color(0xFF3D5AFE),
  ),
  Cancion(
    titulo: 'Sin Señal',
    duracion: '4:02',
    reproducciones: '22.140',
    tendencia: '+21% esta semana',
    lugar: 'Mendoza, AR',
    horarioPico: '12hs - 14hs',
    colorPortada: Color(0xFF00BFA5),
  ),
  Cancion(
    titulo: 'Ruta 7',
    duracion: '3:11',
    reproducciones: '15.890',
    tendencia: '+3% esta semana',
    lugar: 'Rosario, AR',
    horarioPico: '08hs - 10hs',
    colorPortada: Color(0xFFD500F9),
  ),
];

// Álbumes del artista (datos de ejemplo).
final List<Album> albumes = [
  Album(
    titulo: 'Postales',
    anio: '2024',
    colorPortada: Color(0xFFFF5500),
    indices: [0, 1],
  ),
  Album(
    titulo: 'Sin Señal EP',
    anio: '2023',
    colorPortada: Color(0xFF00BFA5),
    indices: [2, 3],
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
