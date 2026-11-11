import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  RolUsuario rolSeleccionado = RolUsuario.oyente;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // El home de main.dart reacciona solo al login: acá no se navega a mano,
  // así el stack del Navigator no queda con pantallas duplicadas.
  void ingresar() {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;
    if (email.isEmpty) return _mostrarError('Ingresá tu email');
    if (password.length < 6) {
      return _mostrarError('La contraseña tiene al menos 6 caracteres');
    }
    authViewModel.login(
      Usuario(
        id: 'usuario_1',
        nombre: email.split('@').first,
        email: email,
        rol: rolSeleccionado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note, size: 80, color: colorAcento),
                const SizedBox(height: 24),
                const Text(
                  'StreamTunes',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresá para continuar',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: decoracionFormulario('Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: decoracionFormulario('Contraseña'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Artista'),
                        selected: rolSeleccionado == RolUsuario.artista,
                        onSelected: (seleccionado) {
                          setState(() {
                            rolSeleccionado = RolUsuario.artista;
                          });
                        },
                        selectedColor: colorAcento,
                        backgroundColor: colorTarjeta,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Oyente'),
                        selected: rolSeleccionado == RolUsuario.oyente,
                        onSelected: (seleccionado) {
                          setState(() {
                            rolSeleccionado = RolUsuario.oyente;
                          });
                        },
                        selectedColor: colorAcento,
                        backgroundColor: colorTarjeta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                BotonPrincipal(texto: 'Ingresar', onPressed: ingresar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
