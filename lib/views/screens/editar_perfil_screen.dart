import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/constantes.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';

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