import 'dart:async';

import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/services/servicio_recordatorios.dart';
import 'package:streamtunes_demo/services/tareas_segundo_plano.dart';

// Dobles compartidos por los tests de notificaciones (no es un archivo de
// test: no termina en _test.dart, flutter test no lo ejecuta solo).

/// Doble del servicio de recordatorios: el permiso se controla con
/// [concederPermiso] (o un Completer para dejarlo pendiente).
class RecordatoriosFalsos implements ServicioRecordatorios {
  RecordatoriosFalsos({this.concederPermiso = true});

  bool concederPermiso;
  Completer<bool>? permisoPendiente;
  int pedidosDePermiso = 0;
  int cancelaciones = 0;
  final List<Concierto> programados = [];
  final List<List<String>> avisos = [];

  @override
  Future<bool> solicitarPermisos() {
    pedidosDePermiso++;
    return permisoPendiente?.future ?? Future.value(concederPermiso);
  }

  @override
  Future<void> programarRecordatorioConcierto(Concierto concierto) async {
    programados.add(concierto);
  }

  @override
  Future<void> cancelarRecordatorios() async => cancelaciones++;

  @override
  Future<void> mostrarNuevosConciertos(List<String> nombres) async {
    avisos.add(nombres);
  }

  final List<({double monto, String donante})> donaciones = [];

  @override
  Future<void> mostrarDonacionRecibida({
    required double monto,
    required String donante,
  }) async {
    donaciones.add((monto: monto, donante: donante));
  }
}

/// Doble del servicio de tareas en segundo plano.
class TareasFalsas implements ServicioTareasSegundoPlano {
  int registros = 0;
  int cancelaciones = 0;
  Object? errorAlRegistrar;

  bool get registrada => registros > cancelaciones;

  @override
  Future<void> registrarVerificacionPeriodica() async {
    if (errorAlRegistrar != null) throw errorAlRegistrar!;
    registros++;
  }

  @override
  Future<void> cancelar() async => cancelaciones++;
}
