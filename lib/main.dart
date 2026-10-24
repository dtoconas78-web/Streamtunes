// StreamTunes - Demo de navegación (versión "full", solo front, sin lógica real)
// Pantalla A: perfil del artista con banner, botón Seguir, tabs y lista de canciones.
// Pantalla B: estadísticas de la canción con grid de métricas y progreso.

import 'package:flutter/material.dart';
import 'dart:async';

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
      navigatorKey: navegadorKey,
      navigatorObservers: [ObservadorReproductor()],
      // builder envuelve TODAS las pantallas: el mini-player queda abajo siempre.
      builder: (context, child) {
        return Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: reproductor,
                builder: (context, _) {
                  final miniVisible = reproductor.hayCancion &&
                      !reproductor.pantallaCompletaAbierta;
                  // Si el mini-player está visible, las pantallas no deben
                  // dejar margen inferior (ya lo ocupa el mini-player).
                  return MediaQuery.removePadding(
                    context: context,
                    removeBottom: miniVisible,
                    child: child!,
                  );
                },
              ),
            ),
            const MiniReproductor(),
          ],
        );
      },
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

// Modelo simple para representar un álbum.
// "indices" son las posiciones de sus canciones en la lista `canciones`.
class Album {
  final String titulo;
  final String anio;
  final Color colorPortada;
  final List<int> indices;

  const Album({
    required this.titulo,
    required this.anio,
    required this.colorPortada,
    required this.indices,
  });
}

// Álbumes del artista (datos de ejemplo).
const List<Album> albumes = [
  Album(
    titulo: 'Postales',
    anio: '2024',
    colorPortada: Color(0xFFFF5500),
    indices: [0, 1],
  ),
  Album(
    titulo: 'Sin Señal EP',
    anio: '2023',
    colorPortada: Color(0xFF00BFA5),
    indices: [2, 3],
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
                  // Tab 2: lista de álbumes.
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: albumes.length,
                    itemBuilder: (context, index) {
                      final album = albumes[index];
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
                              color: album.colorPortada,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.album, color: Colors.black),
                          ),
                          title: Text(album.titulo),
                          subtitle: Text(
                            '${album.indices.length} canciones, ${album.anio}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaAlbum(album: album),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
class PantallaB extends StatefulWidget {
  final Cancion cancion;

  const PantallaB({super.key, required this.cancion});

  @override 
  State<PantallaB> createState() => _PantallaBState();
}

class _PantallaBState extends State<PantallaB> {
  late int reproduccionesLive;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    reproduccionesLive = int.parse(widget.cancion.reproducciones.replaceAll('.', ''));
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        reproduccionesLive += 7; // simulado
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cancion = widget.cancion;
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
              reproduccionesLive.toString(),
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

// Convierte "3:24" en segundos (204).
int _aSegundos(String duracion) {
  final partes = duracion.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

// Convierte segundos en "m:ss" (204 -> "3:24").
String _formatoTiempo(int segundos) {
  final minutos = segundos ~/ 60;
  final resto = (segundos % 60).toString().padLeft(2, '0');
  return '$minutos:$resto';
}

// ---------------------------------------------------------------------------
// ESTADO GLOBAL DE LA REPRODUCCIÓN
// ---------------------------------------------------------------------------

// Controlador de reproducción: guarda qué suena, en qué segundo y si está en pausa.
// Vive fuera de las pantallas, por eso la música sigue al navegar.
// Cuando se conecte audio real (just_audio), solo hay que tocar esta clase.
class ControladorReproduccion extends ChangeNotifier {
  int? indiceActual; // null = todavía no se eligió ninguna canción
  int posicion = 0; // segundos reproducidos de la canción actual
  bool reproduciendo = false;
  bool pantallaCompletaAbierta = false; // true cuando está abierto el reproductor grande
  final Set<int> meGustas = {}; // índices de canciones guardadas
  Timer? _timer;

  bool get hayCancion => indiceActual != null;
  Cancion? get cancion => indiceActual == null ? null : canciones[indiceActual!];
  int get total => cancion == null ? 0 : _aSegundos(cancion!.duracion);
  bool get leGusta => indiceActual != null && meGustas.contains(indiceActual);

  // Pone a sonar una canción. Si ya era la actual, sigue desde donde estaba.
  void reproducir(int indice) {
    if (indiceActual != indice) {
      indiceActual = indice;
      posicion = 0;
    }
    reproduciendo = true;
    // El reloj se crea una sola vez y avanza cada segundo mientras suena.
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _avanzar());
    notifyListeners();
  }

  void _avanzar() {
    if (!reproduciendo || !hayCancion) return;
    posicion++;
    // Al terminar la canción, pasa a la siguiente.
    if (posicion >= total) {
      _irA((indiceActual! + 1) % canciones.length);
    }
    notifyListeners();
  }

  void _irA(int nuevoIndice) {
    indiceActual = nuevoIndice;
    posicion = 0;
  }

  void alternarPausa() {
    if (!hayCancion) return;
    reproduciendo = !reproduciendo;
    notifyListeners();
  }

  void siguiente() {
    if (!hayCancion) return;
    _irA((indiceActual! + 1) % canciones.length);
    notifyListeners();
  }

  // Si ya pasaron más de 3 segundos, "anterior" vuelve al inicio de la misma
  // canción; si no, va a la anterior (como en la mayoría de los reproductores).
  void anterior() {
    if (!hayCancion) return;
    if (posicion > 3) {
      posicion = 0;
    } else {
      _irA((indiceActual! - 1 + canciones.length) % canciones.length);
    }
    notifyListeners();
  }

  void saltarA(int segundos) {
    posicion = segundos;
    notifyListeners();
  }

  void alternarMeGusta() {
    if (!hayCancion) return;
    if (!meGustas.remove(indiceActual)) meGustas.add(indiceActual!);
    notifyListeners();
  }

  // Lo llama el observador de navegación para ocultar el mini-player
  // mientras está abierto el reproductor grande.
  void marcarPantallaCompleta(bool abierta) {
    if (pantallaCompletaAbierta == abierta) return;
    pantallaCompletaAbierta = abierta;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Una única instancia compartida por toda la app.
final ControladorReproduccion reproductor = ControladorReproduccion();

// Llave del Navigator: permite abrir pantallas desde el mini-player,
// que está por encima del Navigator y no tiene su propio contexto de navegación.
final GlobalKey<NavigatorState> navegadorKey = GlobalKey<NavigatorState>();

// Abre el reproductor grande.
void abrirReproductor() {
  navegadorKey.currentState?.push(
    MaterialPageRoute(
      settings: const RouteSettings(name: '/reproductor'),
      builder: (context) => const PantallaReproductor(),
    ),
  );
}

// Avisa al controlador cuando el reproductor grande se abre o se cierra.
class ObservadorReproductor extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(route.settings.name == '/reproductor');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    reproductor.marcarPantallaCompleta(previousRoute?.settings.name == '/reproductor');
  }
}

// ---------------------------------------------------------------------------
// MINI-PLAYER
// ---------------------------------------------------------------------------

// Barra chica que acompaña en todas las pantallas mientras haya una canción
// elegida. Tocarla abre el reproductor grande.
class MiniReproductor extends StatelessWidget {
  const MiniReproductor({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final cancion = reproductor.cancion;
        // Se oculta si no hay canción o si ya está abierto el reproductor grande.
        if (cancion == null || reproductor.pantallaCompletaAbierta) {
          return const SizedBox.shrink();
        }
        final progreso =
        reproductor.total == 0 ? 0.0 : reproductor.posicion / reproductor.total;

        return Material(
          color: colorTarjeta,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Línea fina de progreso arriba del mini-player.
                LinearProgressIndicator(
                  value: progreso.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: colorFondo,
                  color: colorAcento,
                ),
                InkWell(
                  onTap: abrirReproductor,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cancion.colorPortada,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.black),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cancion.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Mateo Cabral',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            reproductor.reproduciendo ? Icons.pause : Icons.play_arrow,
                            color: colorAcento,
                            size: 30,
                          ),
                          tooltip: reproductor.reproduciendo ? 'Pausar' : 'Reproducir',
                          onPressed: reproductor.alternarPausa,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 28),
                          tooltip: 'Siguiente',
                          onPressed: reproductor.siguiente,
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// REPRODUCTOR GRANDE
// ---------------------------------------------------------------------------

// Pantalla Reproductor: portada, controles y barra de progreso.
// No guarda estado propio: lee_todo del controlador global.
class PantallaReproductor extends StatelessWidget {
  const PantallaReproductor({super.key});

  void _avisar(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reproductor,
      builder: (context, _) {
        final cancion = reproductor.cancion;
        if (cancion == null) return const Scaffold();
        final total = reproductor.total;
        final posicion = reproductor.posicion;
        final leGusta = reproductor.leGusta;

        return Scaffold(
          appBar: AppBar(
            // Flecha hacia abajo: cierra el reproductor y vuelve a donde estabas.
            // La música sigue sonando en el mini-player.
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 30),
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Reproduciendo'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: colorAcento),
                tooltip: 'Compartir',
                onPressed: () => _avisar(context, 'Compartiendo "${cancion.titulo}"...'),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  // Portada grande: es lo más importante de la pantalla.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cancion.colorPortada,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.music_note, size: 96, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Título, artista y botón de "me gusta".
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cancion.titulo,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mateo Cabral',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          leGusta ? Icons.favorite : Icons.favorite_border,
                          color: colorAcento,
                          size: 28,
                        ),
                        tooltip: leGusta ? 'Quitar de guardados' : 'Guardar',
                        onPressed: reproductor.alternarMeGusta,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Barra de progreso: se puede arrastrar para saltar a otro momento.
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorAcento,
                      inactiveTrackColor: colorTarjeta,
                      thumbColor: colorAcento,
                      overlayColor: colorAcento.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      min: 0,
                      max: total.toDouble(),
                      value: posicion.clamp(0, total).toDouble(),
                      onChanged: (valor) => reproductor.saltarA(valor.round()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatoTiempo(posicion),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(_formatoTiempo(total),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controles: anterior, play/pausa, siguiente.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_previous),
                        tooltip: 'Anterior',
                        onPressed: reproductor.anterior,
                      ),
                      const SizedBox(width: 20),
                      Container(
                        decoration: const BoxDecoration(
                          color: colorAcento,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 44,
                          padding: const EdgeInsets.all(14),
                          color: Colors.black,
                          icon: Icon(reproductor.reproduciendo ? Icons.pause : Icons.play_arrow),
                          tooltip: reproductor.reproduciendo ? 'Pausar' : 'Reproducir',
                          onPressed: reproductor.alternarPausa,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.skip_next),
                        tooltip: 'Siguiente',
                        onPressed: reproductor.siguiente,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Apoyo directo al artista (el pago real se conecta en la fase 2).
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorAcento,
                        side: const BorderSide(color: colorAcento),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Apoyar a Mateo Cabral'),
                      onPressed: () => _avisar(context, 'Las donaciones llegan pronto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Pantalla Detalle de álbum: portada, datos y lista de canciones.
class PantallaAlbum extends StatelessWidget {
  final Album album;

  const PantallaAlbum({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.titulo)),
      // ListenableBuilder: resalta la canción que está sonando.
      body: ListenableBuilder(
        listenable: reproductor,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: album.colorPortada,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.album, size: 72, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                album.titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mateo Cabral',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                '${album.anio}, ${album.indices.length} canciones',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Botón que reproduce el álbum desde la primera canción.
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorAcento,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproducir'),
                  onPressed: () => reproductor.reproducir(album.indices.first),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < album.indices.length; i++)
                _FilaCancionAlbum(numero: i + 1, indice: album.indices[i]),
            ],
          );
        },
      ),
    );
  }
}

// Una fila de la lista de canciones del álbum.
class _FilaCancionAlbum extends StatelessWidget {
  final int numero;
  final int indice; // posición en la lista `canciones`

  const _FilaCancionAlbum({required this.numero, required this.indice});

  @override
  Widget build(BuildContext context) {
    final cancion = canciones[indice];
    final sonando = reproductor.indiceActual == indice;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 28,
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(color: sonando ? colorAcento : Colors.grey),
          ),
        ),
      ),
      title: Text(
        cancion.titulo,
        style: TextStyle(
          color: sonando ? colorAcento : Colors.white,
          fontWeight: sonando ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: sonando
          ? const Icon(Icons.graphic_eq, color: colorAcento)
          : Text(cancion.duracion, style: const TextStyle(color: Colors.grey)),
      // Reproduce y se queda en la pantalla: aparece el mini-player abajo.
      onTap: () => reproductor.reproducir(indice),
    );
  }
}