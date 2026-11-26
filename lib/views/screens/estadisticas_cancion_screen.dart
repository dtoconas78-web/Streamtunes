import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/metricas_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/barra_proporcion.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Pantalla B: estadísticas de la canción seleccionada.
//
// Con métricas reales (Firestore, o reproducciones contadas en este celular)
// muestra reproducciones, franjas horarias y ciudades. En modo demo (sin
// Firebase y sin reproducciones contadas) muestra los valores de ejemplo de
// la canción, avisando que son de ejemplo, con un contador "en vivo"
// simulado que se frena en segundo plano (subtarea 9.2).
class PantallaB extends StatefulWidget {
  final Cancion cancion;

  /// Por defecto, el global de inyeccion.dart (los tests pueden inyectar uno).
  final MetricasViewModel? metricas;

  const PantallaB({super.key, required this.cancion, this.metricas});

  @override
  State<PantallaB> createState() => _PantallaBState();
}

class _PantallaBState extends State<PantallaB> {
  late int reproduccionesLive;
  Timer? _timer;
  VoidCallback? _cancelarCicloVida;

  MetricasViewModel get _metricas => widget.metricas ?? metricasViewModel;

  // Demo: no hay datos reales de esta canción ni fuente remota.
  bool get _esDemo =>
      !_metricas.esRemoto && _metricas.resumenDe(widget.cancion.id) == null;

  @override
  void initState() {
    super.initState();
    reproduccionesLive = widget.cancion.reproducciones;
    _iniciarTimer();
    // El refresco de estadísticas se frena al ir a segundo plano y se
    // reanuda al volver (subtarea 9.2, ver gestor_ciclo_vida.dart).
    _cancelarCicloVida = gestorCicloVida.registrar(
      alPausar: _pausarTimer,
      alReanudar: _reanudarTimer,
    );
  }

  void _iniciarTimer() {
    _timer ??= Timer.periodic(const Duration(seconds: 3), (timer) {
      // Solo en modo demo: con datos reales los cambios llegan solos.
      if (!_esDemo) return;
      setState(() {
        reproduccionesLive += 7; // simulado (datos de ejemplo)
      });
    });
  }

  void _pausarTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _reanudarTimer() => _iniciarTimer();

  @override
  void dispose() {
    _cancelarCicloVida?.call();
    _pausarTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancion = widget.cancion;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          // IconButton: acción secundaria (compartir) sin tanto peso visual.
          IconButton(
            icon: const Icon(Icons.share, color: colorAcento),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compartiendo "${cancion.titulo}"...')),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _metricas,
        builder: (context, _) => _cuerpo(cancion, demo: _esDemo),
      ),
    );
  }

  Widget _cuerpo(Cancion cancion, {required bool demo}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta con la canción.
          Tarjeta(
            bordeAcento: true,
            margin: EdgeInsets.zero,
            radio: 16,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PortadaCuadrada(color: colorDe(cancion.colorPortada)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancion.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mateo Cabral',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!demo)
            ..._metricasReales(_metricas.resumenDe(cancion.id))
          else ...[
            const _AvisoEjemplo(),
            const Text(
              'Reproducciones',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              formatearMiles(reproduccionesLive),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorAcento,
              ),
            ),
            const SizedBox(height: 8),
            // Barra de progreso simulando crecimiento vs. semana pasada.
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.68,
                      backgroundColor: colorTarjeta,
                      color: colorAcento,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  cancion.tendencia,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Grid 2x2 de métricas adicionales.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                const _TarjetaMetrica(
                  icono: Icons.headphones,
                  valor: '9.120',
                  etiqueta: 'Oyentes únicos',
                ),
                const _TarjetaMetrica(
                  icono: Icons.favorite,
                  valor: '3.402',
                  etiqueta: 'Guardados',
                ),
                const _TarjetaMetrica(
                  icono: Icons.share,
                  valor: '812',
                  etiqueta: 'Compartidos',
                ),
                const _TarjetaMetrica(
                  icono: Icons.repeat,
                  valor: '5.6',
                  etiqueta: 'Repeticiones prom.',
                ),
                _TarjetaMetrica(
                  icono: Icons.access_time,
                  valor: cancion.horarioPico,
                  etiqueta: 'Horario pico',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FilaEstadistica(
              icono: Icons.place,
              texto: 'Lugar más frecuente: ${cancion.lugar}',
            ),
          ],
        ],
      ),
    );
  }

  // Métricas reales: reproducciones, franjas horarias y ciudades.
  List<Widget> _metricasReales(ResumenMetricas? resumen) {
    if (resumen == null) {
      return const [
        _FilaEstadistica(
          icono: Icons.hourglass_empty,
          texto:
              'Todavía no hay reproducciones de esta canción. Se cuentan cuando '
              'alguien la escucha al menos $segundosParaContar segundos.',
        ),
      ];
    }
    final pico = resumen.franjaPico;
    return [
      const Text(
        'Reproducciones',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 4),
      Text(
        formatearMiles(resumen.total),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorAcento,
        ),
      ),
      const SizedBox(height: 24),
      const _TituloSeccion('¿A qué hora la escuchan?'),
      for (final f in FranjaHoraria.values)
        BarraProporcion(
          etiqueta: f.etiqueta,
          cantidad: resumen.franjas[f] ?? 0,
          proporcion: resumen.proporcion(f),
          destacada: f == pico,
        ),
      const SizedBox(height: 24),
      const _TituloSeccion('¿Dónde la escuchan?'),
      for (final c in resumen.ciudades.take(5))
        BarraProporcion(
          etiqueta: c.ciudad,
          cantidad: c.cantidad,
          proporcion: c.cantidad / resumen.total,
          destacada: c == resumen.ciudades.first,
        ),
      if (resumen.ciudades.length > 5)
        Text(
          'y ${resumen.ciudades.length - 5} ciudades más',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
    ];
  }
}

// Aviso de que lo que se ve son datos de ejemplo (modo demo).
class _AvisoEjemplo extends StatelessWidget {
  const _AvisoEjemplo();

  @override
  Widget build(BuildContext context) {
    return const _FilaEstadistica(
      icono: Icons.info_outline,
      texto:
          'Datos de ejemplo: todavía no hay reproducciones reales de esta '
          'canción en este celular.',
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Tarjeta chica para el grid de métricas.
class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _TarjetaMetrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Tarjeta(
      bordeAcento: true,
      margin: EdgeInsets.zero,
      radio: 14,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: colorAcento, size: 22),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget chico reutilizable para cada fila de estadística.
class _FilaEstadistica extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FilaEstadistica({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: colorAcento, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}
