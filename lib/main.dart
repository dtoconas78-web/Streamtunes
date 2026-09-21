// StreamTunes - Demo de navegación (versión "full", solo front, sin lógica real)
// Pantalla A: perfil del artista con banner, botón Seguir, tabs y lista de canciones.
// Pantalla B: estadísticas de la canción con grid de métricas y progreso.

import 'package:flutter/material.dart';

void main() => runApp(const MiApp());

// Colores reutilizables en toda la app (paleta naranja/rojo, tipo SoundCloud).
const Color colorFondo = Color(0xFF181818);
const Color colorTarjeta = Color(0xFF262626);
const Color colorAcento = Color(0xFFFF5500);

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: colorFondo,
          elevation: 0,
        ),
      ),
      home: const PantallaA(),
    );
  }
}

// Modelo simple para representar una canción.
class Cancion {
  final String titulo;
  final String duracion;
  final String reproducciones;
  final String tendencia;
  final String lugar;
  final Color colorPortada;

  const Cancion({
    required this.titulo,
    required this.duracion,
    required this.reproducciones,
    required this.tendencia,
    required this.lugar,
    required this.colorPortada,
  });
}

// Lista de canciones del artista (datos de ejemplo, realistas).
// Cada una con un color de "portada" distinto para simular variedad visual.
const List<Cancion> canciones = [
  Cancion(
    titulo: 'Luces de la Ciudad',
    duracion: '3:24',
    reproducciones: '48.302',
    tendencia: '+12% esta semana',
    lugar: 'Buenos Aires, AR',
    colorPortada: Color(0xFFFF5500),
  ),
  Cancion(
    titulo: 'Otra Vuelta',
    duracion: '2:57',
    reproducciones: '31.750',
    tendencia: '+5% esta semana',
    lugar: 'Córdoba, AR',
    colorPortada: Color(0xFF3D5AFE),
  ),
  Cancion(
    titulo: 'Sin Señal',
    duracion: '4:02',
    reproducciones: '22.140',
    tendencia: '+21% esta semana',
    lugar: 'Mendoza, AR',
    colorPortada: Color(0xFF00BFA5),
  ),
  Cancion(
    titulo: 'Ruta 7',
    duracion: '3:11',
    reproducciones: '15.890',
    tendencia: '+3% esta semana',
    lugar: 'Rosario, AR',
    colorPortada: Color(0xFFD500F9),
  ),
];

// Pantalla A: perfil del artista + tabs + lista de canciones.
// Es Stateful porque el botón "Seguir" cambia de estado al tocarlo.
class PantallaA extends StatefulWidget {
  const PantallaA({super.key});

  @override
  State<PantallaA> createState() => _PantallaAState();
}

class _PantallaAState extends State<PantallaA> with SingleTickerProviderStateMixin {
  bool siguiendo = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Banner con gradiente detrás del avatar.
            Container(
              width: double.infinity,
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5500), Color(0xFF8A2C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Avatar superpuesto al banner (con margen negativo simulado).
            Transform.translate(
              offset: const Offset(0, -50),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorFondo, width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: colorTarjeta,
                      child: Icon(Icons.person, size: 45, color: colorAcento),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mateo Cabral',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '8.4K seguidores',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  // Botón "Seguir" con estado: cambia al tocarlo.
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: siguiendo ? colorTarjeta : colorAcento,
                      foregroundColor: siguiendo ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: siguiendo
                            ? const BorderSide(color: colorAcento)
                            : BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    ),
                    onPressed: () {
                      setState(() {
                        siguiendo = !siguiendo;
                      });
                      // SnackBar: confirma la acción sin interrumpir al usuario.
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            siguiendo
                                ? 'Ahora seguís a Mateo Cabral'
                                : 'Dejaste de seguir a Mateo Cabral',
                          ),
                        ),
                      );
                    },
                    child: Text(siguiendo ? 'Siguiendo' : 'Seguir'),
                  ),
                ],
              ),
            ),
            // Barra de búsqueda (solo visual, sin lógica).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorTarjeta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: 'Buscar canciones...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tabs: Canciones / Álbumes / Sobre mí.
            TabBar(
              controller: _tabController,
              labelColor: colorAcento,
              unselectedLabelColor: Colors.grey,
              indicatorColor: colorAcento,
              tabs: const [
                Tab(text: 'Canciones'),
                Tab(text: 'Álbumes'),
                Tab(text: 'Sobre mí'),
              ],
            ),
            // Contenido de cada tab.
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: lista de canciones.
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: canciones.length,
                    itemBuilder: (context, index) {
                      final cancion = canciones[index];
                      // Card: agrupa cada canción con esquinas redondeadas.
                      return Card(
                        color: colorTarjeta,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cancion.colorPortada,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.black),
                          ),
                          title: Text(cancion.titulo),
                          subtitle: Text(cancion.duracion,
                              style: const TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.bar_chart, color: colorAcento),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaB(cancion: cancion),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  // Tab 2: Álbumes (placeholder visual).
                  const Center(
                    child: Text('Todavía no hay álbumes', style: TextStyle(color: Colors.grey)),
                  ),
                  // Tab 3: Sobre mí (placeholder visual).
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Artista independiente de Mendoza. Hace música desde 2019, mezclando rock alternativo con sonidos electrónicos.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla B: estadísticas de la canción seleccionada.
class PantallaB extends StatelessWidget {
  final Cancion cancion;

  const PantallaB({super.key, required this.cancion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          // IconButton: acción secundaria (compartir) sin tanto peso visual.
          IconButton(
            icon: const Icon(Icons.share, color: colorAcento),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Compartiendo "${cancion.titulo}"...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta con la canción.
            Card(
              color: colorTarjeta,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cancion.colorPortada,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cancion.titulo,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mateo Cabral',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Reproducciones',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              cancion.reproducciones,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorAcento,
              ),
            ),
            const SizedBox(height: 8),
            // Barra de progreso simulando crecimiento vs. semana pasada.
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.68,
                      backgroundColor: colorTarjeta,
                      color: colorAcento,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(cancion.tendencia, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            // Grid 2x2 de métricas adicionales.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: const [
                _TarjetaMetrica(icono: Icons.headphones, valor: '9.120', etiqueta: 'Oyentes únicos'),
                _TarjetaMetrica(icono: Icons.favorite, valor: '3.402', etiqueta: 'Guardados'),
                _TarjetaMetrica(icono: Icons.share, valor: '812', etiqueta: 'Compartidos'),
                _TarjetaMetrica(icono: Icons.repeat, valor: '5.6', etiqueta: 'Repeticiones prom.'),
              ],
            ),
            const SizedBox(height: 24),
            _FilaEstadistica(icono: Icons.place, texto: 'Lugar más frecuente: ${cancion.lugar}'),
          ],
        ),
      ),
    );
  }
}

// Tarjeta chica para el grid de métricas.
class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const _TarjetaMetrica({required this.icono, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorTarjeta,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorAcento.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: colorAcento, size: 22),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// Widget chico reutilizable para cada fila de estadística.
class _FilaEstadistica extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _FilaEstadistica({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: colorAcento, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 15))),
      ],
    );
  }
}