import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/metricas_cancion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/metricas_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/barra_proporcion.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

/// "Tu música en números": reproducciones de toda la música del artista,
/// las ciudades donde más lo escuchan y la franja horaria pico. Datos
/// reales (no hay valores de ejemplo acá).
class TuMusicaEnNumeros extends StatelessWidget {
  const TuMusicaEnNumeros({super.key, required this.metricas});

  final MetricasViewModel metricas;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: metricas,
      builder: (context, _) {
        final r = metricas.resumenArtista;
        final pico = r.franjaPico;
        return Tarjeta(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart, color: colorAcento, size: 18),
                    SizedBox(width: 8),
                    // Expanded: en pantallas angostas el título no desborda.
                    Expanded(
                      child: Text(
                        'Tu música en números',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (r.vacio)
                  Text(
                    metricas.calculando
                        ? 'Calculando…'
                        : 'Todavía no hay reproducciones contadas. Cuentan '
                              'cuando alguien escucha un tema al menos 30 segundos.',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else ...[
                  Text(
                    r.total == 1
                        ? '1 reproducción'
                        : '${formatearMiles(r.total)} reproducciones',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorAcento,
                    ),
                  ),
                  if (pico != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 10),
                      child: Text(
                        'Te escuchan más a la ${_franjaCorta(pico)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  for (final c in r.ciudades.take(3))
                    BarraProporcion(
                      etiqueta: c.ciudad,
                      cantidad: c.cantidad,
                      proporcion: c.cantidad / r.total,
                      destacada: c == r.ciudades.first,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static String _franjaCorta(FranjaHoraria f) => switch (f) {
    FranjaHoraria.madrugada => 'madrugada (0 a 6 hs)',
    FranjaHoraria.manana => 'mañana (6 a 12 hs)',
    FranjaHoraria.tarde => 'tarde (12 a 19 hs)',
    FranjaHoraria.noche => 'noche (19 a 24 hs)',
  };
}
