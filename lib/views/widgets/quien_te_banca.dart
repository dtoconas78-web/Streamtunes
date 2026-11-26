import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/ventas_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

/// "Quién te banca": los fans que más donaron al artista (las donaciones
/// anónimas van juntas en una fila). Solo lo ve el propio artista.
class QuienTeBanca extends StatelessWidget {
  const QuienTeBanca({
    super.key,
    required this.ventas,
    this.maximo = 3,
    this.alVerTodo,
  });

  final VentasViewModel ventas;
  final int maximo;
  final VoidCallback? alVerTodo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ventas,
      builder: (context, _) {
        final bancadores = ventas.quienesTeBancan;
        return Tarjeta(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite, color: colorMagenta, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Quién te banca',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (alVerTodo != null && bancadores.isNotEmpty)
                      TextButton(
                        onPressed: alVerTodo,
                        child: const Text(
                          'Ver todo',
                          style: TextStyle(color: colorAcento),
                        ),
                      ),
                  ],
                ),
                if (bancadores.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8, right: 8),
                    child: Text(
                      'Todavía nadie te donó. Cuando alguien lo haga, lo vas a ver acá.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                else
                  for (final b in bancadores.take(maximo))
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.only(right: 8),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: colorTarjeta,
                        child: Icon(
                          b.anonimo ? Icons.visibility_off : Icons.person,
                          size: 16,
                          color: colorMagenta,
                        ),
                      ),
                      title: Text(
                        b.anonimo ? 'Anónimos' : b.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        b.cantidad == 1
                            ? '1 donación'
                            : '${b.cantidad} donaciones',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        formatearPrecio(b.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorMagenta,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}
