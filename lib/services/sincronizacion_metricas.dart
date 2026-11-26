import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:streamtunes_demo/data/repositorio_metricas.dart';
import 'package:streamtunes_demo/data/reproducciones_dao.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/utils/reloj.dart';

/// Suma un incremento a las métricas de una canción (Firestore o memoria).
typedef SumarMetricas = Future<void> Function(
  String cancionId,
  MetricasCancion incremento,
);

/// Agrupa reproducciones sueltas en UN incremento por canción (con los ids
/// de las filas que lo forman). Función pura.
Map<String, ({MetricasCancion incremento, List<int> ids})>
agruparReproducciones(Iterable<ReproduccionPendiente> reproducciones) {
  final grupos = <String, ({MetricasCancion incremento, List<int> ids})>{};
  for (final r in reproducciones) {
    final previo = grupos[r.cancionId];
    grupos[r.cancionId] = (
      incremento: (previo?.incremento ?? const MetricasCancion()).sumar(
        MetricasCancion.una(r.ciudad, r.franja),
      ),
      ids: [...?previo?.ids, r.id],
    );
  }
  return grupos;
}

/// Sube las reproducciones pendientes de [dao]: reserva un lote, suma un
/// incremento por canción con [sumar] y borra las que se sumaron. Lo que
/// falla vuelve a la cola para la próxima. Devuelve cuántas se sumaron.
///
/// La usan la app (al arrancar, al iniciar sesión y al ir a segundo plano) y
/// la tarea periódica de workmanager (otro isolate): la reserva del lote
/// evita que las dos sumen la misma reproducción.
Future<int> sincronizarMetricas({
  required ReproduccionesDao dao,
  required SumarMetricas sumar,
  required DateTime ahora,
}) async {
  final lote = await dao.tomarLote(ahora: ahora);
  if (lote.vacio) return 0;
  final sumadas = <int>[];
  Object? primerError;
  try {
    for (final e in agruparReproducciones(lote.reproducciones).entries) {
      try {
        await sumar(e.key, e.value.incremento);
        sumadas.addAll(e.value.ids);
      } catch (error) {
        primerError ??= error;
      }
    }
  } finally {
    await dao.confirmar(lote.id, sumadas);
    await dao.liberar(lote.id); // lo que no se pudo sumar
  }
  if (primerError != null) {
    debugPrint('Métricas: quedaron reproducciones sin subir: $primerError');
  }
  return sumadas.length;
}

/// Cuenta las reproducciones de la app: cada una se guarda en la cola local
/// (SQLite, si hay) con la ciudad del oyente y la franja horaria, y se sube
/// a las métricas con [sincronizar]. Sin base local (tests, escritorio) se
/// suma directo al repositorio.
class RegistroReproducciones {
  RegistroReproducciones({
    required this._metricas,
    required this._ciudad,
    this._dao,
    this._reloj = const RelojDelSistema(),
  });

  final RepositorioMetricas _metricas;
  final String Function() _ciudad;
  final ReproduccionesDao? _dao;
  final Reloj _reloj;
  Future<int>? _enCurso;

  /// Registra una reproducción de [cancion] (no lanza).
  void contar(Cancion cancion) {
    final ahora = _reloj.ahora();
    final franja = FranjaHoraria.de(ahora.hour);
    final ciudad = normalizarCiudad(_ciudad());
    final dao = _dao;
    final Future<void> guardado = dao == null
        ? _metricas.sumar(cancion.id, MetricasCancion.una(ciudad, franja))
        : dao.registrar(
            cancionId: cancion.id,
            ciudad: ciudad,
            franja: franja,
            fecha: ahora,
          );
    unawaited(
      guardado.catchError((Object e) {
        debugPrint('No se pudo registrar la reproducción: $e');
      }),
    );
  }

  /// Sube lo pendiente. Si ya hay una sincronización en curso, devuelve esa
  /// misma (no se lanzan dos a la vez). Nunca lanza: devuelve 0 ante error.
  Future<int> sincronizar() {
    final dao = _dao;
    if (dao == null) return Future.value(0);
    return _enCurso ??=
        sincronizarMetricas(
              dao: dao,
              sumar: _metricas.sumar,
              ahora: _reloj.ahora(),
            )
            .catchError((Object e) {
              debugPrint('Falló la sincronización de métricas: $e');
              return 0;
            })
            .whenComplete(() => _enCurso = null);
  }
}
