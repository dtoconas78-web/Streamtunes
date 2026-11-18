import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/utils/tiempo.dart';

// Un audio elegido que todavía no se publicó. Los datos del archivo son
// simulados hasta conectar un selector de archivos real.
//
// Vive en la capa de presentación (no en lib/models/) porque guarda un
// TextEditingController del formulario.
class PistaBorrador {
  final String archivo;
  final int segundos;
  final double mb;
  final TextEditingController titulo = TextEditingController();

  PistaBorrador({
    required this.archivo,
    required this.segundos,
    required this.mb,
  });
}

// Nombre del archivo, duración y peso.
class InfoArchivo extends StatelessWidget {
  const InfoArchivo({super.key, required this.pista});

  final PistaBorrador pista;

  @override
  Widget build(BuildContext context) {
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
}

// Sección de audio cuando se sube una sola canción: botón para elegir el
// archivo o la tarjeta con el archivo elegido y botón para quitarlo.
class AudioCancion extends StatelessWidget {
  const AudioCancion({
    super.key,
    required this.pista,
    required this.onSeleccionar,
    required this.onQuitar,
  });

  final PistaBorrador? pista; // null = todavía no se eligió audio
  final VoidCallback onSeleccionar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    if (pista == null) {
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
          onPressed: onSeleccionar,
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
          Expanded(child: InfoArchivo(pista: pista!)),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quitar audio',
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}

// Sección de audio cuando se sube un álbum: una tarjeta por canción.
class AudioAlbum extends StatelessWidget {
  const AudioAlbum({
    super.key,
    required this.pistas,
    required this.onAgregar,
    required this.onQuitar,
  });

  final List<PistaBorrador> pistas;
  final VoidCallback onAgregar;
  final void Function(int indice) onQuitar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < pistas.length; i++)
          Container(
            key: ObjectKey(pistas[i]),
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
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: pistas[i].titulo,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: decoracionFormulario(
                          'Título de la canción',
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                            ? 'Escribí el título'
                            : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Quitar canción',
                      onPressed: () => onQuitar(i),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InfoArchivo(pista: pistas[i]),
              ],
            ),
          ),
        if (pistas.length < 20)
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
              onPressed: onAgregar,
            ),
          ),
      ],
    );
  }
}
