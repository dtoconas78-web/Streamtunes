import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/entrada.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
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