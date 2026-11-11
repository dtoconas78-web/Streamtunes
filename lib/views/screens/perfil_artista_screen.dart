import 'package:flutter/material.dart';
import 'package:streamtunes_demo/navigation/navegacion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/catalogo_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/portada.dart';
import 'package:streamtunes_demo/views/widgets/tarjeta.dart';

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
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            tooltip: 'Ventas y donaciones',
            onPressed: () => irA(context, Rutas.ventas),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: colorAcento),
            tooltip: 'Cerrar sesión',
            onPressed: cerrarSesion,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorAcento,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload),
        label: const Text('Subir música'),
        // Al volver no hace falta setState: el catálogo notifica solo.
        onPressed: () => irA(context, Rutas.subirMusica),
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
                  colors: [colorAcento, colorAcentoOscuro],
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
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // La insignia aparece solo si el perfil está verificado.
                            if (perfil.esVerificado) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: colorVerificado,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${perfil.pais}, 8.4K seguidores',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
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
                        foregroundColor: siguiendo
                            ? Colors.white
                            : Colors.black,
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
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => irA(context, Rutas.editarPerfil),
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
                          color: colorAcento,
                        ),
                        label: const Text(
                          'Editar perfil',
                          style: TextStyle(color: colorAcento),
                        ),
                      ),
                      // El texto, ícono y color cambian según el estado.
                      ListenableBuilder(
                        listenable: perfil,
                        builder: (context, _) => TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => irA(context, Rutas.verificacion),
                          icon: Icon(
                            perfil.iconoVerificacion,
                            size: 16,
                            color: perfil.colorVerificacion,
                          ),
                          label: Text(
                            perfil.etiquetaVerificacion,
                            style: TextStyle(color: perfil.colorVerificacion),
                          ),
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
              child: ListenableBuilder(
                listenable: catalogo,
                builder: (context, _) => TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: lista de canciones.
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: catalogo.canciones.length,
                      itemBuilder: (context, index) {
                        final cancion = catalogo.canciones[index];
                        // Tarjeta estándar con borde de acento.
                        return Tarjeta(
                          bordeAcento: true,
                          child: ListTile(
                            leading: PortadaCuadrada(
                              color: cancion.colorPortada,
                              tamano: 44,
                            ),
                            title: Text(cancion.titulo),
                            subtitle: Text(
                              cancion.publica
                                  ? cancion.duracion
                                  : '${cancion.duracion}, privada',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(
                              Icons.bar_chart,
                              color: colorAcento,
                            ),
                            onTap: () => irA(
                              context,
                              Rutas.estadisticas,
                              argumentos: cancion,
                            ),
                          ),
                        );
                      },
                    ),
                    // Tab 2: lista de álbumes.
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: catalogo.albumes.length,
                      itemBuilder: (context, index) {
                        final album = catalogo.albumes[index];
                        return Tarjeta(
                          bordeAcento: true,
                          child: ListTile(
                            leading: PortadaCuadrada(
                              color: album.colorPortada,
                              tamano: 44,
                              icono: Icons.album,
                            ),
                            title: Text(album.titulo),
                            subtitle: Text(
                              '${album.indices.length} canciones, ${album.anio}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () =>
                                irA(context, Rutas.album, argumentos: album),
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
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
