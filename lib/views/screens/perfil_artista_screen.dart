import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/album_screen.dart';
import 'package:streamtunes_demo/views/screens/editar_perfil_screen.dart';
import 'package:streamtunes_demo/views/screens/estadisticas_cancion_screen.dart';
import 'package:streamtunes_demo/views/screens/login_screen.dart';
import 'package:streamtunes_demo/views/screens/subir_musica_screen.dart';
import 'package:streamtunes_demo/views/screens/verificacion_screen.dart';
import 'package:streamtunes_demo/views/screens/ventas_donaciones_screen.dart';
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

  void _cerrarSesion() {
    authViewModel.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

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
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Ventas y donaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VentasDonacionesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
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
                  if (!authViewModel.esArtista)
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
                        label: const Text('Editar perfil', style: TextStyle(color: colorAcento)),
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
                          icon: Icon(perfil.iconoVerificacion, size: 16, color: perfil.colorVerificacion),
                          label: Text(perfil.etiquetaVerificacion, style: TextStyle(color: perfil.colorVerificacion)),
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
                        ),
                      );
                    },
                  ),
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
                  // Tab 3: Sobre mí (se actualiza al editar el perfil).
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}