import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';

/// Una reproducción contada que todavía no se sumó a Firestore.
class ReproduccionPendiente {
  const ReproduccionPendiente({
    required this.id,
    required this.cancionId,
    required this.ciudad,
    required this.franja,
  });

  final int id;
  final String cancionId;
  final String ciudad;
  final FranjaHoraria franja;
}

/// Lote de reproducciones reservado para sincronizar.
class LoteReproducciones {
  const LoteReproducciones(this.id, this.reproducciones);

  final String id;
  final List<ReproduccionPendiente> reproducciones;

  bool get vacio => reproducciones.isEmpty;
}

/// Acceso a la tabla `reproducciones` (cola local de reproducciones
/// contadas, ver data/services/base_datos_local.dart). Consultas con `?` /
/// `whereArgs`.
///
/// Para que la app y la tarea de workmanager (otro isolate, otra conexión a
/// la misma base) no suban dos veces la misma fila, quien sincroniza primero
/// RESERVA un lote ([tomarLote], en una transacción) y después lo confirma
/// (se borran las filas) o lo libera. Una reserva que quedó colgada (la app
/// se cerró en el medio) se libera sola después de [vencimientoLote].
class ReproduccionesDao {
  ReproduccionesDao(this._db);

  final Database _db;
  final Random _azar = Random();

  static const Duration vencimientoLote = Duration(minutes: 10);

  /// Agrega una reproducción a la cola.
  Future<void> registrar({
    required String cancionId,
    required String ciudad,
    required FranjaHoraria franja,
    required DateTime fecha,
  }) => _db.insert('reproducciones', {
    'cancion_id': cancionId,
    'ciudad': normalizarCiudad(ciudad),
    'franja': franja.name,
    'fecha': fecha.millisecondsSinceEpoch,
  });

  /// Cantidad de reproducciones sin sincronizar (reservadas o no).
  Future<int> pendientes() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM reproducciones'),
      ) ??
      0;

  /// Reserva hasta [limite] reproducciones libres y las devuelve.
  Future<LoteReproducciones> tomarLote({
    required DateTime ahora,
    int limite = 500,
  }) {
    final lote =
        'lote-${ahora.microsecondsSinceEpoch}-${_azar.nextInt(1 << 32)}';
    return _db.transaction((txn) async {
      // Reservas vencidas: quien las tomó no terminó (se cerró la app).
      await txn.update(
        'reproducciones',
        {'lote': null, 'lote_fecha': null},
        where: 'lote IS NOT NULL AND lote_fecha < ?',
        whereArgs: [ahora.subtract(vencimientoLote).millisecondsSinceEpoch],
      );
      final filas = await txn.query(
        'reproducciones',
        where: 'lote IS NULL',
        orderBy: 'id',
        limit: limite,
      );
      if (filas.isEmpty) return LoteReproducciones(lote, const []);
      final ids = [for (final f in filas) f['id']! as int];
      await txn.rawUpdate(
        'UPDATE reproducciones SET lote = ?, lote_fecha = ? '
        'WHERE id IN (${List.filled(ids.length, '?').join(',')})',
        [lote, ahora.millisecondsSinceEpoch, ...ids],
      );
      return LoteReproducciones(lote, [
        for (final f in filas)
          ReproduccionPendiente(
            id: f['id']! as int,
            cancionId: f['cancion_id']! as String,
            ciudad: f['ciudad']! as String,
            franja:
                FranjaHoraria.values.asNameMap()[f['franja']] ??
                FranjaHoraria.noche,
          ),
      ]);
    });
  }

  /// Las reproducciones [ids] del [lote] ya se sumaron: se borran.
  Future<void> confirmar(String lote, List<int> ids) async {
    if (ids.isEmpty) return;
    await _db.rawDelete(
      'DELETE FROM reproducciones WHERE lote = ? '
      'AND id IN (${List.filled(ids.length, '?').join(',')})',
      [lote, ...ids],
    );
  }

  /// Devuelve a la cola lo que quede reservado en [lote] (no se pudo subir).
  Future<void> liberar(String lote) => _db.update(
    'reproducciones',
    {'lote': null, 'lote_fecha': null},
    where: 'lote = ?',
    whereArgs: [lote],
  );
}
