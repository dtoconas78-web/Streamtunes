import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';

class VentasDonacionesScreen extends StatelessWidget {
  const VentasDonacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas y donaciones'),
      ),
      body: ListenableBuilder(
        listenable: ventasViewModel,
        builder: (context, _) {
          final lista = ventasViewModel.movimientos;
                    return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ventas: \$${ventasViewModel.totalVentas.toStringAsFixed(0)}'),
                    Text('Donaciones: \$${ventasViewModel.totalDonaciones.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final m = lista[index];
                    return ListTile(
                      title: Text(m.detalle),
                      subtitle: Text('${m.tipo} · ${m.fecha.day}/${m.fecha.month}/${m.fecha.year}'),
                      trailing: Text('\$${m.monto.toStringAsFixed(0)}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}