import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/plataforma/plataforma.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/inyeccion.dart' as inyeccion;
import 'package:streamtunes_demo/viewmodels/configuracion_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Configuración del oyente: notificaciones, reproducción automática y
// si el modo aleatorio queda activo por defecto al reproducir una cola.
//
// Las dependencias son opcionales (por defecto, las globales de
// inyeccion.dart): los tests de widget inyectan un VM con dobles y
// capacidades activas.
class PantallaConfiguracion extends StatelessWidget {
  const PantallaConfiguracion({
    super.key,
    this.viewModel,
    this.capacidades,
    this.politicas,
  });

  final ConfiguracionViewModel? viewModel;
  final Capacidades? capacidades;
  final Politicas? politicas;

  // Subtítulo del switch de notificaciones según capacidad y estado.
  String _subtituloNotificaciones(
    ConfiguracionViewModel vm,
    Capacidades caps,
    Politicas pols,
  ) {
    if (!caps.notificacionesDisponibles) {
      return pols.avisoNotificacionesNoDisponibles;
    }
    if (vm.permisoDenegado) return pols.avisoPermisoNotificacionesDenegado;
    if (vm.ultimoError != null) {
      return 'No se pudo cambiar la preferencia. Probá de nuevo.';
    }
    return 'Recordatorios de tus conciertos y nuevos conciertos publicados';
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel ?? inyeccion.configuracionViewModel;
    final caps = capacidades ?? inyeccion.capacidades;
    final pols = politicas ?? inyeccion.politicas;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Tarjeta(
              child: Column(
                children: [
                  SwitchListTile(
                    // El estado visual se deriva en la vista: capacidad AND
                    // preferencia. Sin capacidad el switch queda apagado y
                    // deshabilitado, con el aviso de políticas como subtítulo.
                    // Mientras se pide el permiso también queda deshabilitado.
                    value: caps.notificacionesDisponibles && vm.notificaciones,
                    activeThumbColor: colorAcento,
                    title: const Text('Notificaciones'),
                    subtitle: Text(
                      _subtituloNotificaciones(vm, caps, pols),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged: caps.notificacionesDisponibles && !vm.cargando
                        ? (v) => unawaited(vm.cambiarNotificaciones(v))
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: vm.reproduccionAutomatica,
                    activeThumbColor: colorAcento,
                    title: const Text('Reproducción automática'),
                    subtitle: const Text(
                      'Al terminar una cola, seguir con más música',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged: vm.setReproduccionAutomatica,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: vm.modoAleatorioPorDefecto,
                    activeThumbColor: colorAcento,
                    title: const Text('Aleatoria por defecto'),
                    subtitle: const Text(
                      'Las playlists y álbumes arrancan en modo aleatorio',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onChanged: vm.setModoAleatorioPorDefecto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'La app es 100% gratuita: no hay suscripciones ni pagos para escuchar.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
