import 'package:flutter/material.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';

class EntradasScreen extends StatelessWidget {
  const EntradasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entradas'),
      ),
      body: ListenableBuilder(
        listenable: entradasViewModel,
        builder: (context, _) {
          final lista = entradasViewModel.entradasCompradas;
          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final entrada = lista[index];
              return ListTile(
                title: Text(entrada.concierto),
                subtitle: Text('${entrada.lugar}\n${entrada.fecha.day}/${entrada.fecha.month}/${entrada.fecha.year}'),
                isThreeLine: true,
                trailing: Text('x${entrada.cantidad}'),
              );
            },
          );
        },
      ),
    );
  }
}