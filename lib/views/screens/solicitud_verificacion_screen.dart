import 'dart:async';

import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/viewmodels/foto_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';
import 'package:streamtunes_demo/views/widgets/selector_foto.dart';

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

  // Foto del documento: dato sensible. Va a la carpeta TEMPORAL y se borra
  // al enviar la solicitud o al salir de la pantalla (nunca queda guardada
  // en la app; con backend se subiría directo, ver PerfilUsuario).
  late final FotoViewModel _documento = FotoViewModel(
    fuente: fuenteFotos,
    almacen: almacenFotos,
    prefijo: 'documento',
    temporal: true,
  );

  @override
  void dispose() {
    unawaited(_documento.descartar());
    _documento.dispose();
    _nombreCtrl.dispose();
    _numeroDocCtrl.dispose();
    _cuentaCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;

    perfil.enviarSolicitud();
    // Con backend la foto se subiría acá; en la app no se conserva.
    unawaited(_documento.descartar());
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Solicitud enviada')));
    // Vuelve a la pantalla de Verificación, que ahora muestra "en revisión".
    Navigator.pop(context);
  }

  // Texto de error en rojo para los campos personalizados (documento y términos).
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
                const Text(
                  'Tus datos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: decoracionFormulario(
                    'Nombre completo (como en el documento)',
                  ),
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
                        initialValue: _tipoDoc,
                        dropdownColor: colorTarjeta,
                        decoration: decoracionFormulario('Tipo'),
                        items: const [
                          DropdownMenuItem(value: 'DNI', child: Text('DNI')),
                          DropdownMenuItem(
                            value: 'Pasaporte',
                            child: Text('Pasaporte'),
                          ),
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
                // Foto del documento (cámara o galería).
                FormField<bool>(
                  validator: (_) => _documento.tieneFoto
                      ? null
                      : 'Adjuntá una foto de tu documento',
                  builder: (campo) => ListenableBuilder(
                    listenable: _documento,
                    builder: (context, _) {
                      final adjunta = _documento.tieneFoto;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: adjunta
                                    ? colorVerificado
                                    : colorAcento,
                                side: BorderSide(
                                  color: adjunta
                                      ? colorVerificado
                                      : colorAcento,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: Icon(
                                adjunta
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                              ),
                              label: Text(
                                _documento.cargando
                                    ? 'Cargando foto…'
                                    : adjunta
                                    ? 'Foto adjuntada · tocá para cambiarla'
                                    : 'Adjuntar foto del documento',
                              ),
                              onPressed: _documento.cargando
                                  ? null
                                  : () async {
                                      await cambiarFoto(
                                        context,
                                        _documento,
                                        titulo: 'Foto del documento',
                                      );
                                      campo.didChange(_documento.tieneFoto);
                                    },
                            ),
                          ),
                          if (campo.hasError) _error(campo.errorText!),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Dónde vas a cobrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                const Text(
                  'Tu música',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: decoracionFormulario(
                    'Link a tu música o redes (opcional)',
                  ),
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
                BotonPrincipal(texto: 'Enviar solicitud', onPressed: _enviar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
