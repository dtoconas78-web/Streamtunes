import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';

// Pantalla B: estadísticas de la canción seleccionada.
class PantallaB extends StatefulWidget {
  final Cancion cancion;

  const PantallaB({super.key, required this.cancion});

  @override
  State<PantallaB> createState() => _PantallaBState();
}

class _PantallaBState extends State<PantallaB> {
  late int reproduccionesLive;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    reproduccionesLive = int.parse(
      widget.cancion.reproducciones.replaceAll('.', ''),
    );
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        reproduccionesLive += 7; // simulado
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con la canción.
            Card(
              color: colorTarjeta,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cancion.colorPortada,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.black),
                    ),
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
        ),
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
    return Card(
      color: colorTarjeta,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
      ),
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
