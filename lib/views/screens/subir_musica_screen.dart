import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/data/datos_ejemplo.dart';
import 'package:streamtunes_demo/models/album.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';

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
          duracion: formatoTiempo(pista.segundos),
          reproducciones: '0',
          tendencia: 'Recién publicada',
          lugar: 'Sin datos todavía',
          horarioPico: 'Sin datos todavía',
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
            '${pista.archivo}, ${formatoTiempo(pista.segundos)}, ${pista.mb.toStringAsFixed(1)} MB',
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
                      BotonPrincipal(texto: 'Publicar', onPressed: _publicar),
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