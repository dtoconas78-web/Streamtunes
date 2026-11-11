import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

// Home del invitado: solo escuchar gratis. Las funciones de cuenta (guardar,
// crear listas, comprar entradas, donar, subir música) le piden registrarse.
class ExplorarScreen extends StatelessWidget {
  const ExplorarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Salir',
            onPressed: cerrarSesion,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: catalogo,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(top: 8),
          children: [
            // Aviso claro de qué puede y qué no puede hacer un invitado.
            Tarjeta(
              bordeAcento: true,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.visibility, color: colorAcento, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Estás como invitado',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Podés escuchar toda la música gratis. Para guardar canciones, crear listas, comprar entradas o apoyar al artista, creá tu cuenta (es gratis).',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorAcento,
                          side: const BorderSide(color: colorAcento),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => irA(context, Rutas.registro),
                        child: const Text('Crear cuenta gratis'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'Canciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            for (int i = 0; i < catalogo.canciones.length; i++)
              ListTile(
                leading: PortadaCuadrada(
                  color: colorDe(catalogo.canciones[i].colorPortada),
                  tamano: 44,
                ),
                title: Text(catalogo.canciones[i].titulo),
                subtitle: Text(
                  catalogo.canciones[i].duracion,
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.play_circle, color: colorAcento),
                onTap: () => reproductor.reproducir(i),
              ),
          ],
        ),
      ),
    );
  }
}
