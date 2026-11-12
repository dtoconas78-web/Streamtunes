import 'package:flutter/material.dart';
import 'package:streamtunes_demo/views/screens/biblioteca_screen.dart';
import 'package:streamtunes_demo/views/screens/buscar_screen.dart';
import 'package:streamtunes_demo/views/screens/inicio_oyente_screen.dart';

// Shell del oyente: barra inferior con Inicio / Buscar / Biblioteca.
// El mini-reproductor queda por encima de todo (viene de main.dart).
class OyenteShell extends StatefulWidget {
  const OyenteShell({super.key});

  @override
  State<OyenteShell> createState() => _OyenteShellState();
}

class _OyenteShellState extends State<OyenteShell> {
  int _indice = 0;

  final List<Widget> _paginas = const [
    InicioOyenteScreen(),
    BuscarScreen(),
    BibliotecaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: las tres pestañas quedan vivas, cambia la visible.
      body: IndexedStack(index: _indice, children: _paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Biblioteca',
          ),
        ],
      ),
    );
  }
}
