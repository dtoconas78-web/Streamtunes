import 'package:flutter/material.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/models/artista.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/utils/formularios.dart';

/// Lo que eligió el fan en la hoja de donación.
typedef EleccionDonacion = ({double monto, bool anonima});

/// Abre la hoja para donarle a [artista] y, si el fan confirma, registra la
/// donación (con su nombre o anónima) y agradece con un SnackBar. Se usa
/// desde Donar y desde el reproductor (donar sin dejar de escuchar).
///
/// Con backend real, acá va la pasarela de pago (Mercado Pago, etc.); el
/// flujo queda igual.
Future<void> abrirDonacion(BuildContext context, Artista artista) async {
  final nombreFan = authViewModel.usuario?.nombre.trim() ?? '';
  final eleccion = await showModalBottomSheet<EleccionDonacion>(
    context: context,
    // La hoja puede ser más alta que 9/16 de pantalla (con el teclado
    // abierto o texto grande) sin overflow.
    isScrollControlled: true,
    builder: (sheetContext) => HojaDonacion(
      nombreArtista: artista.nombre,
      nombreFan: nombreFan,
      alConfirmar: (e) => Navigator.pop(sheetContext, e),
    ),
  );
  if (eleccion == null || !context.mounted) return;

  ventasViewModel.registrarDonacion(
    'Donación a ${artista.nombre}',
    eleccion.monto,
    donante: eleccion.anonima ? '' : nombreFan,
    artistaId: artista.id,
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Donaste ${formatearPrecio(eleccion.monto)} a ${artista.nombre}'
          '${eleccion.anonima ? ' en forma anónima' : ''}. ¡Gracias!',
        ),
      ),
    );
}

/// Hoja inferior para elegir el monto y si la donación es anónima.
///
/// Es StatefulWidget aparte para que el TextEditingController viva y muera
/// con la hoja: si el padre lo hiciera dispose() apenas se cierra el sheet
/// (mientras el TextField todavía está montado durante la animación de
/// salida), el framework revienta con "_dependents.isEmpty" / "attached is
/// not true".
class HojaDonacion extends StatefulWidget {
  const HojaDonacion({
    super.key,
    required this.nombreArtista,
    required this.nombreFan,
    required this.alConfirmar,
  });

  final String nombreArtista;

  /// Nombre que verá el artista si la donación no es anónima ('' = no hay
  /// nombre: la donación solo puede ser anónima).
  final String nombreFan;
  final void Function(EleccionDonacion eleccion) alConfirmar;

  @override
  State<HojaDonacion> createState() => _HojaDonacionState();
}

class _HojaDonacionState extends State<HojaDonacion> {
  static const _rapidos = [500.0, 1000.0, 2000.0, 5000.0];
  final _controlador = TextEditingController();
  double? _montoElegido;
  late bool _anonima = widget.nombreFan.isEmpty;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sinNombre = widget.nombreFan.isEmpty;
    return SafeArea(
      child: Padding(
        // Deja lugar al teclado (la hoja es isScrollControlled).
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donar a ${widget.nombreArtista}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'El 100% va directo al artista.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final monto in _rapidos)
                    ChoiceChip(
                      label: Text(formatearPrecio(monto)),
                      selected: _montoElegido == monto,
                      onSelected: (_) => setState(() {
                        _montoElegido = monto;
                        _controlador.clear();
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controlador,
                keyboardType: TextInputType.number,
                decoration: decoracionFormulario('Otro monto (\$ argentinos)'),
                onChanged: (texto) {
                  final valor = double.tryParse(texto);
                  setState(
                    () => _montoElegido = (valor != null && valor > 0)
                        ? valor
                        : null,
                  );
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _anonima,
                activeThumbColor: colorAcento,
                title: const Text('Donar en forma anónima'),
                subtitle: Text(
                  sinNombre
                      ? 'Tu cuenta no tiene nombre: la donación va anónima'
                      : _anonima
                      ? 'El artista no va a ver tu nombre'
                      : 'El artista va a ver que fuiste vos: ${widget.nombreFan}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onChanged: sinNombre
                    ? null
                    : (v) => setState(() => _anonima = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorAcento,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _montoElegido == null
                      ? null
                      : () => widget.alConfirmar((
                          monto: _montoElegido!,
                          anonima: _anonima,
                        )),
                  child: Text(
                    _montoElegido == null
                        ? 'Elegí un monto'
                        : 'Donar ${formatearPrecio(_montoElegido!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
