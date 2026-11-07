import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/entradas_screen.dart';
import 'package:streamtunes_demo/views/screens/ventas_donaciones_screen.dart';

class ComprarEntradaScreen extends StatelessWidget {
  const ComprarEntradaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Comprar entrada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EntradasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VentasDonacionesScreen()),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: entradasViewModel,
        builder: (context, _) {
          final lista = entradasViewModel.conciertosDisponibles;
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final concierto = lista[index];
              return ListTile(
                title: Text(concierto.nombre),
                subtitle: Text('${concierto.lugar}\n${concierto.fecha.day}/${concierto.fecha.month}/${concierto.fecha.year} · ${concierto.disponibles} disponibles'),
                isThreeLine: true,
                trailing: Text('\$${concierto.precio.toStringAsFixed(0)}'),
                  onTap: () {
                  final ok = entradasViewModel.comprar(concierto, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Compraste 1 entrada' : 'No hay entradas disponibles'),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}