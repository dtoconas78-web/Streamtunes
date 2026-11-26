import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/utils/formatos.dart';

// Totales, filtro y lista de movimientos. Se muestra como pestaña
// dentro del perfil del artista.
class PanelVentasDonaciones extends StatefulWidget {
  // Espacio extra al final de la lista (por ejemplo, para no quedar tapada por un botón flotante).
  final double margenInferior;

  const PanelVentasDonaciones({super.key, this.margenInferior = 0});

  @override
  State<PanelVentasDonaciones> createState() => _PanelVentasDonacionesState();
}

class _PanelVentasDonacionesState extends State<PanelVentasDonaciones> {
  String filtro = 'Todos';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ventasViewModel,
      builder: (context, _) {
        final lista = ventasViewModel.movimientos
            .where(
              (m) =>
                  filtro == 'Todos' ||
                  m.tipo == (filtro == 'Ventas' ? 'Venta' : 'Donación'),
            )
            .toList()
            .reversed
            .toList();
        // Todo en una sola lista con scroll: así entra también en espacios
        // chicos, como la pestaña del perfil.
        return ListView.builder(
          padding: EdgeInsets.only(bottom: widget.margenInferior),
          itemCount: lista.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _encabezado();
            final m = lista[index - 1];
            return _filaMovimiento(m);
          },
        );
      },
    );
  }

  // Totales y filtros, arriba de la lista.
  Widget _encabezado() {
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
          // Wrap: si no entran en una línea, pasan a la siguiente.
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final nombre in ['Todos', 'Ventas', 'Donaciones'])
                  ChoiceChip(
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
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _filaMovimiento(Movimiento m) {
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
          '${m.tipo} · ${formatearFecha(m.fecha)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          '+${formatearPrecio(m.monto)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
