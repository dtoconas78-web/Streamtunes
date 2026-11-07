// StreamTunes - Demo de navegación (versión unificada, solo front, sin lógica real)
// Pantalla A: perfil del artista con banner, botón Seguir animado, tabs y lista de canciones.
// Pantalla B: estadísticas de la canción con contador en vivo, grid de métricas y progreso.
// Pantalla C: editar perfil (se abre desde el ícono de ajustes de la Pantalla A).

import 'dart:async';
import 'dart:math';

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
                  final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
                  final miniVisible = reproductor.hayCancion &&
                      !reproductor.pantallaCompletaAbierta &&
                      !tecladoAbierto;
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
  final String horarioPico;
  final Color colorPortada;
  final String genero;
  final String descripcion;
  final bool publica;

  const Cancion({
    required this.titulo,
    required this.duracion,
    required this.reproducciones,
    required this.tendencia,
    required this.lugar,
    required this.horarioPico,
    required this.colorPortada,
    this.genero = '',
    this.descripcion = '',
    this.publica = true,
  });
}

// Lista de canciones del artista (datos de ejemplo).
// Cada una con un color de "portada" distinto para simular variedad visual.
final List<Cancion> canciones = [
  Cancion(
    titulo: 'Luces de la Ciudad',
    duracion: '3:24',
    reproducciones: '48.302',
    tendencia: '+12% esta semana',
    lugar: 'Buenos Aires, AR',
    horarioPico: '21hs - 23hs',
    colorPortada: Color(0xFFFF5500),
  ),
  Cancion(
    titulo: 'Otra Vuelta',
    duracion: '2:57',
    reproducciones: '31.750',
    tendencia: '+5% esta semana',
    lugar: 'Córdoba, AR',
    horarioPico: '18hs - 20hs',
    colorPortada: Color(0xFF3D5AFE),
  ),
  Cancion(
    titulo: 'Sin Señal',
    duracion: '4:02',
    reproducciones: '22.140',
    tendencia: '+21% esta semana',
    lugar: 'Mendoza, AR',
    horarioPico: '12hs - 14hs',
    colorPortada: Color(0xFF00BFA5),
  ),
  Cancion(
    titulo: 'Ruta 7',
    duracion: '3:11',
    reproducciones: '15.890',
    tendencia: '+3% esta semana',
    lugar: 'Rosario, AR',
    horarioPico: '08hs - 10hs',
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
final List<Album> albumes = [
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

class _PantallaAState extends State<PantallaA>
    with SingleTickerProviderStateMixin {
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

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorAcento,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload),
        label: const Text('Subir música'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PantallaSubirMusica()),
          );
          // Al volver, refresca las listas por si se publicó algo nuevo.
          if (mounted) setState(() {});
        },
      ),
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
      appBar: AppBar(
        actions: [
          // Ajustes: abre la pantalla de editar perfil.
          IconButton(
            icon: const Icon(Icons.settings, color: colorAcento),
            tooltip: 'Editar perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaC(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Logotipo de StreamTunes como fondo, sutil y detrás de todo el contenido.
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/images/streamtunes_logo.jpg',
                fit: BoxFit.contain,
                // Si el asset no está declarado en pubspec.yaml, no rompe la pantalla.
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
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
                  const SizedBox(height: 10),
                  // Se actualiza solo cuando se edita el perfil.
                  ListenableBuilder(
                    listenable: perfil,
                    builder: (context, _) => Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              perfil.nombre,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            // La insignia aparece solo si el perfil está verificado.
                            if (perfil.esVerificado) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: colorVerificado, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${perfil.pais}, 8.4K seguidores',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PantallaEditarPerfil(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16, color: colorAcento),
                        label: const Text('Editar perfil',
                            style: TextStyle(color: colorAcento)),
                      ),
                      // El texto, ícono y color cambian según el estado.
                      ListenableBuilder(
                        listenable: perfil,
                        builder: (context, _) => TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PantallaVerificacion(),
                              ),
                            );
                          },
                          icon: Icon(perfil.iconoVerificacion,
                              size: 16, color: perfil.colorVerificacion),
                          label: Text(perfil.etiquetaVerificacion,
                              style: TextStyle(color: perfil.colorVerificacion)),
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Mateo Cabral',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '8.4K seguidores',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón "Seguir" con estado y animación de color.
                      AnimatedContainer(
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: siguiendo ? colorTarjeta : colorAcento,
                          borderRadius: BorderRadius.circular(20),
                          border: siguiendo
                              ? Border.all(color: colorAcento)
                              : null,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                siguiendo ? colorTarjeta : colorAcento,
                            foregroundColor:
                                siguiendo ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: siguiendo
                                  ? const BorderSide(color: colorAcento)
                                  : BorderSide.none,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 10,
                            ),
                          ),
                          title: Text(cancion.titulo),
                          subtitle: Text(
                            cancion.publica
                                ? cancion.duracion
                                : '${cancion.duracion}, privada',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.bar_chart, color: colorAcento),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PantallaB(cancion: cancion),
                              ),
                            );
                          },
                          child: Text(
                            siguiendo ? 'Siguiendo' : 'Seguir',
                          ),
                        ),
                      );
                    },
                  ),
                  // Tab 2: Álbumes (placeholder visual).
                  // Tab 2: lista de álbumes.
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
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
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: ListenableBuilder(
                      listenable: perfil,
                      builder: (context, _) => Text(
                        perfil.bio,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                              side: BorderSide(
                                color: colorAcento.withValues(alpha: 0.35),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cancion.colorPortada,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.black,
                                ),
                              ),
                              title: Text(cancion.titulo),
                              subtitle: Text(
                                cancion.duracion,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: const Icon(
                                Icons.bar_chart,
                                color: colorAcento,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PantallaB(cancion: cancion),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      // Tab 2: Álbumes (placeholder visual).
                      const Center(
                        child: Text(
                          'Todavía no hay álbumes',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                      // Tab 3: Sobre mí + géneros.
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Artista independiente de Mendoza, Argentina. Hago música desde 2019, mezclando rock alternativo con sonidos electrónicos.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text('Rock')),
                                Chip(label: Text('Rock alternativo')),
                                Chip(label: Text('Electrónica')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla B: estadísticas de la canción seleccionada.
// Es Stateful porque el contador de reproducciones se actualiza solo (simulado).
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
    reproduccionesLive =
        int.parse(widget.cancion.reproducciones.replaceAll('.', ''));
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
            icon: const Icon(
              Icons.share,
              color: colorAcento,
            ),
            tooltip: 'Compartir',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Compartiendo "${cancion.titulo}"...',
                  ),
                ),
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
                side: BorderSide(
                  color: colorAcento.withValues(alpha: 0.35),
                ),
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
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cancion.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mateo Cabral',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),

            // Contador en vivo (simulado).
            Text(
              formatearMiles(reproduccionesLive),
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
                Text(
                  cancion.tendencia,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Grid 2 columnas de métricas adicionales.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                const _TarjetaMetrica(
                  icono: Icons.headphones,
                  valor: '9.120',
                  etiqueta: 'Oyentes únicos',
                ),
                const _TarjetaMetrica(
                  icono: Icons.favorite,
                  valor: '3.402',
                  etiqueta: 'Guardados',
                ),
                const _TarjetaMetrica(
                  icono: Icons.share,
                  valor: '812',
                  etiqueta: 'Compartidos',
                ),
                const _TarjetaMetrica(
                  icono: Icons.repeat,
                  valor: '5.6',
                  etiqueta: 'Repeticiones prom.',
                ),
                _TarjetaMetrica(
                  icono: Icons.access_time,
                  valor: cancion.horarioPico,
                  etiqueta: 'Horario pico',
                ),
              ],
            ),

            const SizedBox(height: 24),

            _FilaEstadistica(
              icono: Icons.place,
              texto: 'Lugar más frecuente: ${cancion.lugar}',
            ),
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

  const _TarjetaMetrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorTarjeta,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorAcento.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: colorAcento,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
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

  const _FilaEstadistica({
    required this.icono,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: colorAcento,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 15),
          ),
        ),
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
        final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
        if (cancion == null || reproductor.pantallaCompletaAbierta || tecladoAbierto) {
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
// Estados por los que pasa una solicitud de verificación.
enum EstadoVerificacion { noSolicitada, pendiente, verificada, rechazada }

// Color de la insignia de verificado.
const Color colorVerificado = Color(0xFF00BFA5);

class PerfilUsuario extends ChangeNotifier {
  String nombre = 'Mateo Cabral';
  String pais = 'Argentina';
  String bio =
      'Artista independiente de Mendoza. Hace música desde 2019, mezclando rock alternativo con sonidos electrónicos.';

  void guardar({required String nombre, required String pais, required String bio}) {
    this.nombre = nombre;
    this.pais = pais;
    this.bio = bio;
    notifyListeners();
  }

  EstadoVerificacion estadoVerificacion = EstadoVerificacion.noSolicitada;
  String motivoRechazo = '';

  bool get esVerificado => estadoVerificacion == EstadoVerificacion.verificada;

  // Texto, ícono y color del botón de verificación en el perfil.
  String get etiquetaVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => 'Verificar perfil',
    EstadoVerificacion.pendiente => 'En revisión',
    EstadoVerificacion.verificada => 'Verificado',
    EstadoVerificacion.rechazada => 'Verificación rechazada',
  };

  IconData get iconoVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => Icons.verified_outlined,
    EstadoVerificacion.pendiente => Icons.hourglass_top,
    EstadoVerificacion.verificada => Icons.verified,
    EstadoVerificacion.rechazada => Icons.error_outline,
  };

  Color get colorVerificacion => switch (estadoVerificacion) {
    EstadoVerificacion.noSolicitada => colorAcento,
    EstadoVerificacion.pendiente => Colors.amber,
    EstadoVerificacion.verificada => colorVerificado,
    EstadoVerificacion.rechazada => Colors.redAccent,
  };

  // Se llama al enviar el formulario. Los datos del formulario NO se guardan
  // acá a propósito: documento y cuenta de cobro son sensibles y tienen que ir
  // directo al backend (o al proveedor de pagos), nunca quedarse en la app.
  void enviarSolicitud() {
    estadoVerificacion = EstadoVerificacion.pendiente;
    motivoRechazo = '';
    notifyListeners();
  }

  // SOLO PARA PRUEBAS: simula la respuesta del equipo que revisa.
  // Cuando haya backend, esto se reemplaza por la respuesta real.
  void simularResultado({required bool aprobada, String motivo = ''}) {
    estadoVerificacion =
    aprobada ? EstadoVerificacion.verificada : EstadoVerificacion.rechazada;
    motivoRechazo = motivo;
    notifyListeners();
  }


}

final PerfilUsuario perfil = PerfilUsuario();

const List<String> paises = [
  'Argentina',
  'Chile',
  'Uruguay',
  'Paraguay',
  'Bolivia',
  'Brasil',
  'Colombia',
  'México',
  'España',
  'Otro',
];

// Pantalla Editar perfil: foto, nombre, país y "sobre mí".
class PantallaEditarPerfil extends StatefulWidget {
  const PantallaEditarPerfil({super.key});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl =
  TextEditingController(text: perfil.nombre);
  late final TextEditingController _bioCtrl =
  TextEditingController(text: perfil.bio);
  late String _pais = perfil.pais;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // Estilo común de los campos del formulario.
  InputDecoration _decoracion(String etiqueta) {
    return InputDecoration(
      labelText: etiqueta,
      filled: true,
      fillColor: colorTarjeta,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _cambiarFoto() {
    // Elegir una foto real necesita el paquete image_picker.
    // Por ahora solo avisa.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cambiar la foto se conecta más adelante')),
    );
  }

  void _guardar() {
    // Si algún campo no cumple las reglas, muestra el error y no guarda.
    if (!_formKey.currentState!.validate()) return;

    perfil.guardar(
      nombre: _nombreCtrl.text.trim(),
      pais: _pais,
      bio: _bioCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Avatar con ícono de cámara para cambiar la foto.
                GestureDetector(
                  onTap: _cambiarFoto,
                  child: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: colorTarjeta,
                        child: Icon(Icons.person, size: 50, color: colorAcento),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorAcento,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorFondo, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nombreCtrl,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoracion('Nombre'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Escribí tu nombre';
                    }
                    if (valor.trim().length < 2) {
                      return 'Tiene que tener al menos 2 letras';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: paises.contains(_pais) ? _pais : null,
                  dropdownColor: colorTarjeta,
                  decoration: _decoracion('País'),
                  items: [
                    for (final pais in paises)
                      DropdownMenuItem(value: pais, child: Text(pais)),
                  ],
                  onChanged: (valor) {
                    if (valor != null) setState(() => _pais = valor);
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bioCtrl,
                  maxLength: 200,
                  maxLines: 4,
                  decoration: _decoracion('Sobre mí'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorAcento,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _guardar,
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Estilo común para los campos de los formularios.
InputDecoration decoracionFormulario(String etiqueta) {
  return InputDecoration(
    labelText: etiqueta,
    filled: true,
    fillColor: colorTarjeta,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

// Pantalla Verificación: muestra una vista distinta según el estado.
class PantallaVerificacion extends StatelessWidget {
  const PantallaVerificacion({super.key});

  void _abrirFormulario(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaSolicitudVerificacion()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: perfil,
          builder: (context, _) {
            switch (perfil.estadoVerificacion) {
              case EstadoVerificacion.noSolicitada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Verificá tu perfil',
                  mensaje:
                  'Para publicar conciertos y cobrar entradas necesitamos confirmar tu identidad y dónde vas a cobrar. Subir música sigue siendo libre.',
                  hijos: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorTarjeta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Paso(numero: 1, texto: 'Tus datos y tu documento'),
                          _Paso(numero: 2, texto: 'Tu cuenta de cobro'),
                          _Paso(numero: 3, texto: 'Revisión de nuestro equipo'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _BotonPrincipal(
                      texto: 'Empezar verificación',
                      onPressed: () => _abrirFormulario(context),
                    ),
                  ],
                );

              case EstadoVerificacion.pendiente:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Solicitud en revisión',
                  mensaje:
                  'Recibimos tus datos. Te vamos a avisar cuando haya una respuesta.',
                  hijos: [
                    // Caja de pruebas: se borra cuando exista el backend.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Solo para pruebas',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Todavía no hay backend: simulá la respuesta del equipo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      perfil.simularResultado(aprobada: true),
                                  child: const Text('Aprobar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => perfil.simularResultado(
                                    aprobada: false,
                                    motivo:
                                    'La foto del documento no se ve con claridad.',
                                  ),
                                  child: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case EstadoVerificacion.rechazada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Solicitud rechazada',
                  mensaje: 'Motivo: ${perfil.motivoRechazo}',
                  hijos: [
                    _BotonPrincipal(
                      texto: 'Volver a intentar',
                      onPressed: () => _abrirFormulario(context),
                    ),
                  ],
                );

              case EstadoVerificacion.verificada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Perfil verificado',
                  mensaje:
                  'Tu perfil tiene la insignia de verificado. Vas a poder publicar conciertos y cobrar entradas cuando esa sección esté disponible.',
                );
            }
          },
        ),
      ),
    );
  }
}

// Diseño común de todas las vistas de estado: ícono, título, mensaje y extras.
class _VistaEstado extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String mensaje;
  final List<Widget> hijos;

  const _VistaEstado({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.mensaje,
    this.hijos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 56, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...hijos,
        ],
      ),
    );
  }
}

// Un paso numerado de la lista "cómo funciona".
class _Paso extends StatelessWidget {
  final int numero;
  final String texto;

  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorAcento,
            child: Text('$numero',
                style: const TextStyle(fontSize: 12, color: Colors.black)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

// Botón naranja de ancho completo, igual al de Editar perfil.
class _BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const _BotonPrincipal({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorAcento,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onPressed,
        child: Text(texto),
      ),
    );
  }
}

// Pantalla Solicitar verificación: datos, documento y cuenta de cobro.
class PantallaSolicitudVerificacion extends StatefulWidget {
  const PantallaSolicitudVerificacion({super.key});

  @override
  State<PantallaSolicitudVerificacion> createState() =>
      _PantallaSolicitudVerificacionState();
}

class _PantallaSolicitudVerificacionState
    extends State<PantallaSolicitudVerificacion> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _numeroDocCtrl = TextEditingController();
  final _cuentaCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _tipoDoc = 'DNI';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _numeroDocCtrl.dispose();
    _cuentaCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;

    perfil.enviarSolicitud();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitud enviada')),
    );
    // Vuelve a la pantalla de Verificación, que ahora muestra "en revisión".
    Navigator.pop(context);
  }

  // Texto de error en rojo para los campos personalizados (documento y términos).
  Widget _error(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar verificación')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tus datos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: decoracionFormulario('Nombre completo (como en el documento)'),
                  validator: (valor) {
                    if (valor == null || valor.trim().length < 3) {
                      return 'Escribí tu nombre completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _tipoDoc,
                        dropdownColor: colorTarjeta,
                        decoration: decoracionFormulario('Tipo'),
                        items: const [
                          DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                          DropdownMenuItem(value: 'Pasaporte', child: Text('Pasaporte')),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (valor) {
                          if (valor != null) setState(() => _tipoDoc = valor);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _numeroDocCtrl,
                        decoration: decoracionFormulario('Número'),
                        validator: (valor) {
                          final texto = (valor ?? '').trim();
                          if (texto.length < 6 || texto.length > 15) {
                            return 'Entre 6 y 15 caracteres';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Foto del documento (simulada: adjuntar una real necesita image_picker).
                FormField<bool>(
                  initialValue: false,
                  validator: (valor) =>
                  valor == true ? null : 'Adjuntá una foto de tu documento',
                  builder: (campo) {
                    final adjunta = campo.value == true;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: adjunta ? colorVerificado : colorAcento,
                              side: BorderSide(
                                  color: adjunta ? colorVerificado : colorAcento),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(adjunta ? Icons.check_circle : Icons.upload_file),
                            label: Text(adjunta
                                ? 'Foto adjuntada (simulado)'
                                : 'Adjuntar foto del documento'),
                            onPressed: () => campo.didChange(!adjunta),
                          ),
                        ),
                        if (campo.hasError) _error(campo.errorText!),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text('Dónde vas a cobrar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cuentaCtrl,
                  decoration: decoracionFormulario('CBU, CVU o alias'),
                  validator: (valor) {
                    final texto = (valor ?? '').trim();
                    if (texto.isEmpty) return 'Ingresá tu CBU, CVU o alias';
                    final soloNumeros = RegExp(r'^\d+$').hasMatch(texto);
                    if (soloNumeros) {
                      return texto.length == 22
                          ? null
                          : 'El CBU o CVU tiene 22 números';
                    }
                    if (texto.length < 6 || texto.length > 20) {
                      return 'El alias tiene entre 6 y 20 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                const Text('Tu música',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: decoracionFormulario('Link a tu música o redes (opcional)'),
                ),
                const SizedBox(height: 20),
                // Aceptación obligatoria.
                FormField<bool>(
                  initialValue: false,
                  validator: (valor) =>
                  valor == true ? null : 'Tenés que aceptar para continuar',
                  builder: (campo) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: colorAcento,
                        checkColor: Colors.black,
                        value: campo.value ?? false,
                        onChanged: (valor) => campo.didChange(valor),
                        title: const Text(
                          'Confirmo que los datos son verdaderos y que soy titular de la cuenta de cobro.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      if (campo.hasError) _error(campo.errorText!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _BotonPrincipal(texto: 'Enviar solicitud', onPressed: _enviar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Límites sugeridos para contener el costo de almacenamiento y ancho de banda.
// Por ahora solo se muestran como texto. Con un selector de archivos real,
// se validan al elegir cada audio.
const int maxMbPorArchivo = 50;
const int maxMinutosPorCancion = 10;

const List<String> generos = [
  'Rock',
  'Pop',
  'Electrónica',
  'Hip hop',
  'Folklore',
  'Indie',
  'Otro',
];

// Colores entre los que se elige la portada (la imagen real se conecta después).
const List<Color> coloresPortada = [
  Color(0xFFFF5500),
  Color(0xFF3D5AFE),
  Color(0xFF00BFA5),
  Color(0xFFD500F9),
  Color(0xFFFFC107),
  Color(0xFFE91E63),
];

// Un audio elegido que todavía no se publicó. Los datos del archivo son
// simulados hasta conectar un selector de archivos real.
class _PistaBorrador {
  final String archivo;
  final int segundos;
  final double mb;
  final TextEditingController titulo = TextEditingController();

  _PistaBorrador({required this.archivo, required this.segundos, required this.mb});
}

// Pantalla Subir música: una canción suelta o un álbum.
class PantallaSubirMusica extends StatefulWidget {
  const PantallaSubirMusica({super.key});

  @override
  State<PantallaSubirMusica> createState() => _PantallaSubirMusicaState();
}

class _PantallaSubirMusicaState extends State<PantallaSubirMusica> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _descripcionCtrl = TextEditingController();
  final _azar = Random();
  final List<_PistaBorrador> _pistas = [];
  int _contadorArchivos = 0;

  bool _esAlbum = false;
  Color _colorPortada = coloresPortada.first;
  String _genero = generos.first;
  bool _publica = true;
  bool _errorAudio = false; // muestra el error si falta audio
  bool _subiendo = false;
  double _progreso = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _tituloCtrl.dispose();
    _anioCtrl.dispose();
    _descripcionCtrl.dispose();
    for (final pista in _pistas) {
      pista.titulo.dispose();
    }
    super.dispose();
  }

  // Libera el controlador después del próximo frame, cuando el campo
  // de texto ya salió de pantalla.
  void _descartar(_PistaBorrador pista) {
    WidgetsBinding.instance.addPostFrameCallback((_) => pista.titulo.dispose());
  }

  void _cambiarModo(bool esAlbum) {
    if (esAlbum == _esAlbum) return;
    final descartadas = List<_PistaBorrador>.from(_pistas);
    setState(() {
      _esAlbum = esAlbum;
      // Al cambiar de modo se vacía la lista de audios para no mezclarlos.
      _pistas.clear();
      _errorAudio = false;
    });
    for (final pista in descartadas) {
      _descartar(pista);
    }
  }

  // SIMULADO: crea un archivo falso con duración y peso al azar.
  // Con el paquete file_picker, acá se abre el selector de archivos de audio
  // y se validan el peso y la duración máximos.
  void _agregarPista() {
    _contadorArchivos++;
    setState(() {
      _pistas.add(_PistaBorrador(
        archivo: 'audio_$_contadorArchivos.mp3',
        segundos: 120 + _azar.nextInt(181),
        mb: 3 + _azar.nextDouble() * 6,
      ));
      _errorAudio = false;
    });
  }

  void _quitarPista(int indice) {
    final pista = _pistas[indice];
    setState(() => _pistas.removeAt(indice));
    _descartar(pista);
  }

  void _publicar() {
    final formularioOk = _formKey.currentState!.validate();
    final audioOk = _esAlbum ? _pistas.length >= 2 : _pistas.length == 1;
    setState(() => _errorAudio = !audioOk);
    if (!formularioOk || !audioOk) return;

    // Simula la subida: la barra avanza hasta completarse.
    setState(() {
      _subiendo = true;
      _progreso = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() => _progreso = min(1.0, _progreso + 0.05));
      if (_progreso >= 1) {
        timer.cancel();
        _terminar();
      }
    });
  }

  // Agrega lo subido a las listas de la app y vuelve al perfil.
  void _terminar() {
    final titulo = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();

    final nuevas = [
      for (final pista in _pistas)
        Cancion(
          titulo: _esAlbum ? pista.titulo.text.trim() : titulo,
          duracion: _formatoTiempo(pista.segundos),
          reproducciones: '0',
          tendencia: 'Recién publicada',
          lugar: 'Sin datos todavía',
          colorPortada: _colorPortada,
          genero: _genero,
          descripcion: descripcion,
          publica: _publica,
        ),
    ];

    final primero = canciones.length; // posición de la primera canción nueva
    canciones.addAll(nuevas);
    if (_esAlbum) {
      albumes.add(Album(
        titulo: titulo,
        anio: _anioCtrl.text.trim(),
        colorPortada: _colorPortada,
        indices: [for (int i = 0; i < nuevas.length; i++) primero + i],
      ));
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_esAlbum ? 'Álbum "$titulo" publicado' : '"$titulo" publicada'),
      ),
    );
    Navigator.pop(context);
  }

  Widget _tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  // Nombre del archivo, duración y peso.
  Widget _infoArchivo(_PistaBorrador pista) {
    return Row(
      children: [
        const Icon(Icons.audio_file, color: colorAcento, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${pista.archivo}, ${_formatoTiempo(pista.segundos)}, ${pista.mb.toStringAsFixed(1)} MB',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _error(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  // Sección de audio cuando se sube una sola canción.
  Widget _audioCancion() {
    if (_pistas.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorAcento,
            side: const BorderSide(color: colorAcento),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.upload_file),
          label: const Text('Seleccionar audio'),
          onPressed: _agregarPista,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: colorTarjeta,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _infoArchivo(_pistas.first)),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quitar audio',
            onPressed: () => _quitarPista(0),
          ),
        ],
      ),
    );
  }

  // Sección de audio cuando se sube un álbum: una tarjeta por canción.
  Widget _audioAlbum() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _pistas.length; i++)
          Container(
            key: ObjectKey(_pistas[i]),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: colorAcento,
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 12, color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pistas[i].titulo,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: decoracionFormulario('Título de la canción'),
                        validator: (valor) => (valor == null || valor.trim().isEmpty)
                            ? 'Escribí el título'
                            : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Quitar canción',
                      onPressed: () => _quitarPista(i),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoArchivo(_pistas[i]),
              ],
            ),
          ),
        if (_pistas.length < 20)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorAcento,
                side: const BorderSide(color: colorAcento),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar canción'),
              onPressed: _agregarPista,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // No deja salir de la pantalla mientras se está subiendo.
    return PopScope(
      canPop: !_subiendo,
      child: Scaffold(
        appBar: AppBar(title: const Text('Subir música')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            // Mientras sube, no se puede tocar nada del formulario.
            child: AbsorbPointer(
              absorbing: _subiendo,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: false,
                              label: Text('Canción'),
                              icon: Icon(Icons.music_note)),
                          ButtonSegment(
                              value: true,
                              label: Text('Álbum'),
                              icon: Icon(Icons.album)),
                        ],
                        selected: {_esAlbum},
                        onSelectionChanged: (seleccion) => _cambiarModo(seleccion.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: colorAcento,
                          selectedForegroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _tituloSeccion(_esAlbum ? 'Canciones del álbum' : 'Audio'),
                    _esAlbum ? _audioAlbum() : _audioCancion(),
                    if (_errorAudio)
                      _error(_esAlbum
                          ? 'Sumá al menos 2 canciones'
                          : 'Seleccioná el archivo de audio'),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'MP3, WAV o FLAC. Hasta $maxMbPorArchivo MB y $maxMinutosPorCancion minutos por canción.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _tituloSeccion('Portada'),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final color in coloresPortada)
                          GestureDetector(
                            onTap: () => setState(() => _colorPortada = color),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _colorPortada == color
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: _colorPortada == color
                                  ? const Icon(Icons.check, color: Colors.black)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Por ahora la portada es un color. Subir una imagen se conecta más adelante.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _tituloSeccion('Datos'),
                    TextFormField(
                      controller: _tituloCtrl,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: decoracionFormulario(
                          _esAlbum ? 'Título del álbum' : 'Título de la canción'),
                      validator: (valor) => (valor == null || valor.trim().isEmpty)
                          ? 'Escribí un título'
                          : null,
                    ),
                    if (_esAlbum) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _anioCtrl,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration:
                        decoracionFormulario('Año').copyWith(counterText: ''),
                        validator: (valor) {
                          final anio = int.tryParse((valor ?? '').trim());
                          if (anio == null ||
                              anio < 1950 ||
                              anio > DateTime.now().year + 1) {
                            return 'Ingresá un año válido';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _genero,
                      dropdownColor: colorTarjeta,
                      decoration: decoracionFormulario('Género'),
                      items: [
                        for (final genero in generos)
                          DropdownMenuItem(value: genero, child: Text(genero)),
                      ],
                      onChanged: (valor) {
                        if (valor != null) setState(() => _genero = valor);
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _descripcionCtrl,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: decoracionFormulario('Descripción (opcional)'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: colorAcento,
                      title: const Text('Pública'),
                      subtitle: Text(
                        _publica
                            ? 'Cualquiera puede escucharla'
                            : 'Solo vos la vas a ver',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: _publica,
                      onChanged: (valor) => setState(() => _publica = valor),
                    ),
                    const SizedBox(height: 16),

                    // Mientras sube muestra el progreso; si no, el botón.
                    if (_subiendo)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _progreso,
                            minHeight: 6,
                            color: colorAcento,
                            backgroundColor: colorTarjeta,
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Subiendo... ${(_progreso * 100).round()}%',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    else
                      _BotonPrincipal(texto: 'Publicar', onPressed: _publicar),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
