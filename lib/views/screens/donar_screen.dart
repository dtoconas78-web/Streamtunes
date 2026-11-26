import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/views/widgets/boton_perfil.dart';
import 'package:streamtunes_demo/views/widgets/hoja_donacion.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Donar al artista. Regla de la app: solo se le puede donar a un artista
// que seguís. Acá se ve a quiénes seguís (donación directa) y a quiénes
// no (con el botón "Seguir para donar").
class DonarScreen extends StatelessWidget {
  const DonarScreen({super.key});

  void _error(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donar al artista'),
        actions: [const BotonPerfil()],
      ),
      body: ListenableBuilder(
        listenable: seguimientoViewModel,
        builder: (context, _) {
          final seguidos = seguimientoViewModel.seguidos;
          final noSeguidos = seguimientoViewModel.noSeguidos;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // La regla, siempre visible para que no haya confusión.
              Tarjeta(
                bordeAcento: true,
                margin: const EdgeInsets.only(bottom: 16),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: colorAcento, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'En StreamTunes le donás directo al artista. Regla: para donarle, primero tenés que seguirlo.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (seguidos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Todavía no seguís a ningún artista. Seguí a uno abajo para poder donarle.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else ...[
                const Text(
                  'A quiénes podés donar hoy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final artista in seguidos)
                  Tarjeta(
                    child: ListTile(
                      leading: PortadaCuadrada(
                        color: colorAcento,
                        icono: Icons.person,
                      ),
                      title: Text(
                        artista.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Lo seguís · 100% va directo',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.volunteer_activism,
                        color: colorAcento,
                      ),
                      onTap: () => abrirDonacion(context, artista),
                    ),
                  ),
              ],
              if (noSeguidos.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Otros artistas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final artista in noSeguidos)
                  Tarjeta(
                    child: ListTile(
                      leading: PortadaCuadrada(
                        color: colorTarjeta,
                        icono: Icons.person_outline,
                      ),
                      title: Text(artista.nombre),
                      subtitle: const Text(
                        'No lo seguís: seguílo para poder donarle',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorAcento,
                          side: const BorderSide(color: colorAcento),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          seguimientoViewModel.seguir(artista.id);
                          _error(
                            context,
                            'Ahora seguís a ${artista.nombre}. Ya podés donarle.',
                          );
                        },
                        child: const Text('Seguir'),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
