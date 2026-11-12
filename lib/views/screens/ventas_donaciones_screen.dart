import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/models/movimiento.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

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
              .where(
                (m) =>
                    filtro == 'Todos' ||
                    m.tipo ==
                        (filtro == 'Ventas'
                            ? TipoMovimiento.venta
                            : TipoMovimiento.donacion),
              )
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
                        colorAcento,
                        Icons.confirmation_number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _tarjetaTotal(
                        'Donaciones',
                        ventasViewModel.totalDonaciones,
                        colorMagenta,
                        Icons.favorite,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                // Wrap en vez de Row: en pantallas angostas los filtros no
                // deben empujar un overflow horizontal (se acomodan en
                // varias filas solos).
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final nombre in ['Todos', 'Ventas', 'Donaciones'])
                      ChoiceChip(
                        label: Text(nombre),
                        selected: filtro == nombre,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: filtro == nombre ? Colors.black : Colors.white,
                        ),
                        onSelected: (_) => setState(() => filtro = nombre),
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
                    final esVenta = m.tipo == TipoMovimiento.venta;
                    final color = esVenta ? colorAcento : colorMagenta;
                    return Tarjeta(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 10,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: PortadaCuadrada(
                          color: color,
                          icono: esVenta
                              ? Icons.confirmation_number
                              : Icons.favorite,
                        ),
                        title: Text(
                          m.detalle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${m.tipo.etiqueta} · ${formatearFecha(m.fecha)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
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
  return Tarjeta(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortadaCuadrada(
            color: color,
            tamano: 36,
            icono: icono,
            tamanoIcono: 20,
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
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
    ),
  );
}
