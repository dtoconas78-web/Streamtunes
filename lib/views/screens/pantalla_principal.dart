// Contenedor con la barra de navegación inferior: Inicio / Buscar / Biblioteca.
// IndexedStack mantiene el estado de cada pestaña (por ejemplo, el texto buscado).

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/views/screens/biblioteca.dart';
import 'package:streamtunes_demo/views/screens/buscar.dart';
import 'package:streamtunes_demo/views/screens/inicio.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: const [
          PantallaInicio(),
          PantallaBuscar(),
          PantallaBiblioteca(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: colorFondo,
        indicatorColor: colorAcento.withValues(alpha: 0.25),
        selectedIndex: _indice,
        onDestinationSelected: (nuevo) => setState(() => _indice = nuevo),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: colorAcento),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: colorAcento),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music, color: colorAcento),
            label: 'Biblioteca',
          ),
        ],
      ),
    );
  }
}
