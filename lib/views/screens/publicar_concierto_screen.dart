import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/utils/formatos.dart';
import 'package:streamtunes_demo/viewmodels/entradas_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';

// Publicar un concierto desde el artista: aparece al toque en
// "Comprar entrada" del oyente. Con backend, acá se valida que el
// perfil esté verificado antes de permitir publicar.
class PublicarConciertoScreen extends StatefulWidget {
  const PublicarConciertoScreen({super.key});

  @override
  State<PublicarConciertoScreen> createState() =>
      _PublicarConciertoScreenState();
}

class _PublicarConciertoScreenState extends State<PublicarConciertoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _disponiblesCtrl = TextEditingController();
  DateTime? _fecha;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _lugarCtrl.dispose();
    _precioCtrl.dispose();
    _disponiblesCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: hoy.add(const Duration(days: 30)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365 * 2)),
      helpText: 'Fecha del concierto',
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  void _publicar() {
    if (!_formKey.currentState!.validate() || _fecha == null) {
      if (_fecha == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elegí la fecha del concierto')),
        );
      }
      return;
    }
    entradasViewModel.publicarConcierto(
      nombre: _nombreCtrl.text.trim(),
      lugar: _lugarCtrl.text.trim(),
      fecha: _fecha!,
      precio: double.parse(_precioCtrl.text.replaceAll(',', '')),
      disponibles: int.parse(_disponiblesCtrl.text.trim()),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Concierto "${_nombreCtrl.text.trim()}" publicado: ya se puede comprar entrada',
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar concierto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu concierto, a la venta al instante',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Publicalo y los oyentes lo ven en "Comprar entrada". Vos ponés el precio y la cantidad de entradas.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                  decoration: decoracionFormulario('Nombre del concierto'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Escribí el nombre del concierto'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lugarCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: decoracionFormulario('Lugar (teatro, club...)'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Escribí el lugar'
                      : null,
                ),
                const SizedBox(height: 12),
                // Fecha: se elige con el selector de fecha del sistema.
                TarjetaFecha(fecha: _fecha, onTap: _elegirFecha),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  decoration: decoracionFormulario(
                    'Precio por entrada (\$ argentinos)',
                  ),
                  validator: (v) {
                    final valor = double.tryParse(
                      (v ?? '').replaceAll(',', ''),
                    );
                    if (valor == null || valor <= 0) {
                      return 'Escribí un precio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _disponiblesCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: decoracionFormulario('Entradas disponibles'),
                  validator: (v) {
                    final valor = int.tryParse(v ?? '');
                    if (valor == null || valor <= 0) {
                      return 'Escribí cuántas entradas vas a vender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                BotonPrincipal(
                  texto: 'Publicar concierto',
                  onPressed: _publicar,
                ),
                if (_fecha != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Fecha elegida: ${formatearFecha(_fecha!)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fila que muestra la fecha elegida (o el llamado a elegirla).
class TarjetaFecha extends StatelessWidget {
  final DateTime? fecha;
  final VoidCallback onTap;

  const TarjetaFecha({super.key, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // El ValueKey recrea el campo cuando cambia la fecha, así el
    // initialValue muestra siempre la fecha actual.
    return TextFormField(
      key: ValueKey(fecha),
      readOnly: true,
      onTap: onTap,
      initialValue: fecha == null ? '' : formatearFecha(fecha!),
      decoration: decoracionFormulario('Fecha del concierto').copyWith(
        hintText: fecha == null ? 'Tocá para elegir' : null,
        suffixIcon: const Icon(Icons.event, color: colorAcento),
      ),
      validator: (_) => fecha == null ? 'Elegí la fecha del concierto' : null,
    );
  }
}
