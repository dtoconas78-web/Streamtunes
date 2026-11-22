import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/cancion.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';
import 'package:streamtunes_demo/views/widgets/seccion_audio.dart';

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
  final List<PistaBorrador> _pistas = [];
  int _contadorArchivos = 0;

  bool _esAlbum = false;
  Color _colorPortada = coloresPortada.first;
  String _genero = generos.first;
  bool _publica = true;
  bool _errorAudio = false; // muestra el error si falta audio
  bool _subiendo = false;
  double _progreso = 0;
  Timer? _timer;
  VoidCallback? _cancelarCicloVida;

  @override
  void initState() {
    super.initState();
    // Si hay una subida en curso, su avance se frena al ir a segundo plano y
    // se reanuda al volver (subtarea 9.2, ver gestor_ciclo_vida.dart).
    _cancelarCicloVida = gestorCicloVida.registrar(
      alPausar: _pausarSubida,
      alReanudar: _reanudarSubida,
    );
  }

  void _pausarSubida() {
    if (!_subiendo) return;
    _timer?.cancel();
    _timer = null;
  }

  void _reanudarSubida() {
    if (_subiendo) _iniciarAvance();
  }

  @override
  void dispose() {
    _cancelarCicloVida?.call();
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
  void _descartar(PistaBorrador pista) {
    WidgetsBinding.instance.addPostFrameCallback((_) => pista.titulo.dispose());
  }

  void _cambiarModo(bool esAlbum) {
    if (esAlbum == _esAlbum) return;
    final descartadas = List<PistaBorrador>.from(_pistas);
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
      _pistas.add(
        PistaBorrador(
          archivo: 'audio_$_contadorArchivos.mp3',
          segundos: 120 + _azar.nextInt(181),
          mb: 3 + _azar.nextDouble() * 6,
        ),
      );
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
    _iniciarAvance();
  }

  void _iniciarAvance() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 120), (timer) {
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
      for (var i = 0; i < _pistas.length; i++)
        Cancion(
          id: 'pista-${DateTime.now().millisecondsSinceEpoch}-$i',
          titulo: _esAlbum ? _pistas[i].titulo.text.trim() : titulo,
          duracionSegundos: _pistas[i].segundos,
          reproducciones: 0,
          tendencia: 'Recién publicada',
          lugar: 'Sin datos todavía',
          horarioPico: 'Sin datos todavía',
          colorPortada: _colorPortada.toARGB32(),
          genero: _genero,
          descripcion: descripcion,
          publica: _publica,
        ),
    ];

    // El catálogo es el dueño de las listas: publica y notifica solo.
    catalogo.publicar(
      nuevas: nuevas,
      tituloAlbum: _esAlbum ? titulo : null,
      anioAlbum: _anioCtrl.text.trim(),
      colorPortada: _colorPortada.toARGB32(),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _esAlbum ? 'Álbum "$titulo" publicado' : '"$titulo" publicada',
        ),
      ),
    );
    Navigator.pop(context);
  }

  Widget _tituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _error(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 6),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
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
                            icon: Icon(Icons.music_note),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Álbum'),
                            icon: Icon(Icons.album),
                          ),
                        ],
                        selected: {_esAlbum},
                        onSelectionChanged: (seleccion) =>
                            _cambiarModo(seleccion.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: colorAcento,
                          selectedForegroundColor: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _tituloSeccion(_esAlbum ? 'Canciones del álbum' : 'Audio'),
                    _esAlbum
                        ? AudioAlbum(
                            pistas: _pistas,
                            onAgregar: _agregarPista,
                            onQuitar: _quitarPista,
                          )
                        : AudioCancion(
                            pista: _pistas.isEmpty ? null : _pistas.first,
                            onSeleccionar: _agregarPista,
                            onQuitar: () => _quitarPista(0),
                          ),
                    if (_errorAudio)
                      _error(
                        _esAlbum
                            ? 'Sumá al menos 2 canciones'
                            : 'Seleccioná el archivo de audio',
                      ),
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
                        _esAlbum ? 'Título del álbum' : 'Título de la canción',
                      ),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                          ? 'Escribí un título'
                          : null,
                    ),
                    if (_esAlbum) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _anioCtrl,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: decoracionFormulario('Año')
                            .copyWith(counterText: ''),
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
                      initialValue: _genero,
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
                      decoration: decoracionFormulario(
                        'Descripción (opcional)',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: colorAcento,
                      title: const Text('Pública'),
                      subtitle: Text(
                        _publica
                            ? 'Cualquiera puede escucharla'
                            : 'Solo vos la vas a ver',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
