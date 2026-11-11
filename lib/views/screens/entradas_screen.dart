import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

class EntradasScreen extends StatelessWidget {
  const EntradasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: entradasViewModel,
        builder: (context, _) {
          final lista = List.of(entradasViewModel.entradasCompradas)
            ..sort((a, b) => a.fecha.compareTo(b.fecha));
          if (lista.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Todavía no tenés entradas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Comprá una desde Comprar entrada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final entrada = lista[index];
              final hoy = DateTime.now();
              final dias = DateTime(
                entrada.fecha.year,
                entrada.fecha.month,
                entrada.fecha.day,
              ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
              final faltan = dias > 1
                  ? 'Faltan $dias días'
                  : dias == 1
                  ? 'Es mañana'
                  : dias == 0
                  ? 'Es hoy'
                  : 'Finalizado';
              final nombreCorto = entrada.concierto.replaceAll(' ', '');
              final letras = nombreCorto.length < 3
                  ? nombreCorto
                  : nombreCorto.substring(0, 3);
              final codigo =
                  'ST-${letras.toUpperCase()}-${entrada.fecha.day.toString().padLeft(2, '0')}${entrada.fecha.month.toString().padLeft(2, '0')}';
              return Tarjeta(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: PortadaCuadrada(
                    color: coloresPortada[index % coloresPortada.length],
                    icono: Icons.confirmation_number,
                  ),
                  title: Text(
                    entrada.concierto,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entrada.lugar}\n${formatearFecha(entrada.fecha)}\n$faltan',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorFondo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          codigo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x${entrada.cantidad}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorAcento,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatearPrecio(entrada.precio * entrada.cantidad),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
