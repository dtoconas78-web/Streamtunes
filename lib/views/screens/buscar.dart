// Pantalla Buscar: campo de búsqueda + explorar por género.
// Sin texto muestra los géneros; con texto filtra canciones, álbumes y playlists.

import 'package:flutter/material.dart';

import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/playlists_viewmodel.dart';
import 'package:streamtunes_demo/viewmodels/reproductor_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/album_screen.dart';
import 'package:streamtunes_demo/views/screens/detalle_playlist.dart';
import 'package:streamtunes_demo/views/widgets/componentes.dart';

class PantallaBuscar extends StatefulWidget {
  const PantallaBuscar({super.key});

  @override
  State<PantallaBuscar> createState() => _PantallaBuscarState();
}

class _PantallaBuscarState extends State<PantallaBuscar> {
  final TextEditingController _controlador = TextEditingController();
  String _consulta = '';

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  // Minúsculas y sin tildes, para que "senal" encuentre "Señal"... y "cordoba" a "Córdoba".
  String _normalizar(String texto) {
    const origen = 'áàäâéèëêíìïîóòöôúùüû';
    const destino = 'aaaaeeeeiiiioooouuuu';
    var resultado = texto.toLowerCase();
    for (int i = 0; i < origen.length; i++) {
      resultado = resultado.replaceAll(origen[i], destino[i]);
    }
    return resultado;
  }

  bool _coincide(String consulta, List<String> campos) =>
      campos.any((campo) => _normalizar(campo).contains(consulta));

  void _buscar(String texto) {
    _controlador.text = texto;
    _controlador.selection = TextSelection.collapsed(offset: texto.length);
    setState(() => _consulta = texto.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          // Campo de búsqueda.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: colorTarjeta,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _controlador,
                textInputAction: TextInputAction.search,
                onChanged: (texto) => setState(() => _consulta = texto.trim()),
                decoration: InputDecoration(
                  hintText: 'Canciones, álbumes, playlists...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  // El botón de borrar aparece solo si hay texto.
                  suffixIcon: _consulta.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          tooltip: 'Borrar',
                          onPressed: () => _buscar(''),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([reproductor, gestorPlaylists]),
              builder: (context, _) =>
                  _consulta.isEmpty ? _explorar() : _resultados(context),
            ),
          ),
        ],
      ),
    );
  }

  // Sin búsqueda: cuadrícula de géneros.
  Widget _explorar() {
    return ListView(
      children: [
        const TituloSeccion('Explorar por género'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (int i = 0; i < generos.length; i++)
              Material(
                color: coloresPortada[i % coloresPortada.length],
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _buscar(generos[i]),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        generos[i],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Con búsqueda: resultados por tipo.
  Widget _resultados(BuildContext context) {
    final q = _normalizar(_consulta);

    final cancionesHalladas = [
      for (int i = 0; i < canciones.length; i++)
        if (canciones[i].publica &&
            _coincide(q, [canciones[i].titulo, canciones[i].genero, canciones[i].lugar]))
          i,
    ];
    final albumesHallados =
        albumes.where((a) => _coincide(q, [a.titulo, a.anio])).toList();
    final playlistsHalladas =
        gestorPlaylists.lista.where((p) => _coincide(q, [p.nombre])).toList();

    if (cancionesHalladas.isEmpty && albumesHallados.isEmpty && playlistsHalladas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No encontramos resultados para “$_consulta”.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (cancionesHalladas.isNotEmpty) ...[
          const _SubtituloResultados('Canciones'),
          for (final indice in cancionesHalladas) FilaCancion(indice: indice),
        ],
        if (albumesHallados.isNotEmpty) ...[
          const _SubtituloResultados('Álbumes'),
          for (final album in albumesHallados)
            FilaColeccion(
              color: album.colorPortada,
              icono: Icons.album,
              titulo: album.titulo,
              subtitulo: '${etiquetaCanciones(album.indices.length)}, ${album.anio}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PantallaAlbum(album: album)),
                );
              },
            ),
        ],
        if (playlistsHalladas.isNotEmpty) ...[
          const _SubtituloResultados('Playlists'),
          for (final playlist in playlistsHalladas)
            FilaColeccion(
              color: playlist.color,
              icono: Icons.queue_music,
              titulo: playlist.nombre,
              subtitulo: etiquetaCanciones(playlist.indices.length),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PantallaDetallePlaylist(playlist: playlist),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}

class _SubtituloResultados extends StatelessWidget {
  final String texto;

  const _SubtituloResultados(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorAcento),
      ),
    );
  }
}
