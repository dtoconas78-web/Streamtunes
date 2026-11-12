import 'package:flutter/material.dart';
import 'package:streamtunes_demo/views/screens/biblioteca_screen.dart';
import 'package:streamtunes_demo/views/screens/buscar_screen.dart';
import 'package:streamtunes_demo/views/screens/comprar_entrada_screen.dart';
import 'package:streamtunes_demo/views/screens/donar_screen.dart';
import 'package:streamtunes_demo/views/screens/inicio_oyente_screen.dart';

// Shell del oyente: barra inferior con Inicio / Buscar / Donar / Entradas /
// Biblioteca. Donar y Entradas viven como pestañas (así la barra queda
// siempre visible). El mini-reproductor queda por encima de todo (main.dart).
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
    DonarScreen(),
    ComprarEntradaScreen(),
    BibliotecaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack: las cinco pestañas quedan vivas, cambia la visible.
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
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Donar',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Entradas',
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
