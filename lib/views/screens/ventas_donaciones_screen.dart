import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';

class VentasDonacionesScreen extends StatefulWidget {
  const VentasDonacionesScreen({super.key});

  @override
  State<VentasDonacionesScreen> createState() => _VentasDonacionesScreenState();
}

class _VentasDonacionesScreenState extends State<VentasDonacionesScreen> {
  String filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas y donaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ventasViewModel,
        builder: (context, _) {
          final lista = ventasViewModel.movimientos
              .where((m) => filtro == 'Todos' || m.tipo == (filtro == 'Ventas' ? 'Venta' : 'Donación'))
              .toList()
              .reversed
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _tarjetaTotal(
                        'Ventas',
                        ventasViewModel.totalVentas,
                        const Color(0xFFFF5500),
                        Icons.confirmation_number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tarjetaTotal(
                        'Donaciones',
                        ventasViewModel.totalDonaciones,
                        const Color(0xFFD500F9),
                        Icons.favorite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    for (final nombre in ['Todos', 'Ventas', 'Donaciones'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(nombre),
                          selected: filtro == nombre,
                          showCheckmark: false,
                          selectedColor: const Color(0xFFFF5500),
                          backgroundColor: const Color(0xFF262626),
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: filtro == nombre ? Colors.black : Colors.white,
                          ),
                          onSelected: (_) => setState(() => filtro = nombre),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final m = lista[index];
                    final esVenta = m.tipo == 'Venta';
                    final color = esVenta ? const Color(0xFFFF5500) : const Color(0xFFD500F9);
                    return Card(
                      color: const Color(0xFF262626),
                      clipBehavior: Clip.antiAlias,
                      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            esVenta ? Icons.confirmation_number : Icons.favorite,
                            color: Colors.black,
                          ),
                        ),
                        title: Text(
                          m.detalle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${m.tipo} · ${formatearFecha(m.fecha)}',                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        trailing: Text(
                          '+${formatearPrecio(m.monto)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                        ),
                      ),
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

Widget _tarjetaTotal(String titulo, double monto, Color color, IconData icono) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF262626),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 20, color: Colors.black),
        ),
        const SizedBox(height: 12),
        Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          formatearPrecio(monto),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    ),
  );
}