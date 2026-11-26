import 'package:flutter/material.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/models/concierto.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/views/widgets/boton_perfil.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

class ComprarEntradaScreen extends StatefulWidget {
  const ComprarEntradaScreen({super.key});

  @override
  State<ComprarEntradaScreen> createState() => _ComprarEntradaScreenState();
}

class _ComprarEntradaScreenState extends State<ComprarEntradaScreen> {
  // true mientras hay una compra en curso: evita compras simultáneas por
  // doble pulsación (cada compra es una transacción atómica idempotente).
  bool _comprando = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprar entrada'),
        // Donar y Mis entradas ya viven en la barra inferior.
        actions: [const BotonPerfil()],
      ),
      body: Column(
        children: [
          if (_comprando) const LinearProgressIndicator(),
          Expanded(
            child: ListenableBuilder(
              listenable: entradasViewModel,
              builder: (context, _) {
                final lista = entradasViewModel.conciertosDisponibles;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final concierto = lista[index];
                    return Tarjeta(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 10,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: PortadaCuadrada(
                          color: coloresPortada[index % coloresPortada.length],
                        ),
                        title: Text(
                          concierto.nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${concierto.lugar}\n${formatearFecha(concierto.fecha)} · ${concierto.disponibles} disponibles',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            if (concierto.disponibles <= 100)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: concierto.disponibles == 0
                                      ? Colors.grey
                                      : colorAcento,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  concierto.disponibles == 0
                                      ? 'Agotado'
                                      : 'Últimas entradas',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          formatearPrecio(concierto.precio),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorAcento,
                          ),
                        ),
                        onTap: () => _elegirCantidad(context, concierto),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _elegirCantidad(
    BuildContext context,
    Concierto concierto,
  ) async {
    if (concierto.disponibles == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este concierto está agotado')),
      );
      return;
    }
    int cantidad = 1;
    // El fondo y las esquinas salen del bottomSheetTheme del tema.
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concierto.nombre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    concierto.lugar,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    politicas.textoComisionFan,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: cantidad > 1
                            ? () => setStateSheet(() => cantidad--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: cantidad < concierto.disponibles
                            ? () => setStateSheet(() => cantidad++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorAcento,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: Text(
                        'Confirmar · ${formatearPrecio(concierto.precio * cantidad)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmado != true || !context.mounted) return;
    // La lógica de negocio vive en el ViewModel/repositorio: acá sólo se
    // espera el resultado del flujo async (memoria o transacción Firestore).
    if (_comprando) return; // evita compras simultáneas por doble pulsación
    setState(() => _comprando = true);
    final ok = await entradasViewModel.comprarAsync(concierto, cantidad);
    if (!context.mounted) return;
    setState(() => _comprando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Compraste $cantidad entrada(s)' : 'No hay entradas disponibles',
        ),
      ),
    );
  }
}
