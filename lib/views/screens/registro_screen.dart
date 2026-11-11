import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/views/widgets/boton_google.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';
import 'package:streamtunes_demo/views/widgets/elegir_rol.dart';

// Registro de cuenta gratis: con Google o con email + contraseña.
// Al registrar, el home de main.dart cambia solo; esta pantalla se saca del stack.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();
  RolUsuario _rol = RolUsuario.oyente;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  void _error(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Con backend real, si la cuenta de Google todavía no existe se crea acá
  // (mismo flujo: FirebaseAuth crea la cuenta con el credential de Google).
  Future<void> _registrarConGoogle() async {
    if (_cargando) return;
    final rol = await elegirRol(
      context,
      titulo: '¿Cómo te registrás con Google?',
    );
    if (rol == null) return;
    setState(() => _cargando = true);
    try {
      await authViewModel.loginConGoogle(rol: rol);
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      _error('No se pudo crear la cuenta. Probá de nuevo.');
      setState(() => _cargando = false);
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate() || _cargando) return;
    setState(() => _cargando = true);
    try {
      await authViewModel.registrar(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        rol: _rol,
      );
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      _error('No se pudo crear la cuenta. Probá de nuevo.');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Es gratis y para siempre',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escuchás toda la música gratis. Con cuenta además podés guardar canciones, crear listas, comprar entradas y apoyar directo al artista.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              if (_cargando)
                const Center(
                  child: CircularProgressIndicator(color: colorAcento),
                )
              else ...[
                BotonGoogle(
                  texto: 'Registrarse con Google',
                  onPressed: _registrarConGoogle,
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o con tu email',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: decoracionFormulario('Nombre'),
                      validator: validarNombre,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: decoracionFormulario('Email'),
                      validator: validarEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: decoracionFormulario('Contraseña'),
                      validator: validarPassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _repetirCtrl,
                      obscureText: true,
                      decoration: decoracionFormulario('Repetir contraseña'),
                      validator: (v) =>
                          validarRepeticion(v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Quiero usar StreamTunes como:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Artista'),
                            selected: _rol == RolUsuario.artista,
                            onSelected: (_) =>
                                setState(() => _rol = RolUsuario.artista),
                            selectedColor: colorAcento,
                            backgroundColor: colorTarjeta,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Oyente'),
                            selected: _rol == RolUsuario.oyente,
                            onSelected: (_) =>
                                setState(() => _rol = RolUsuario.oyente),
                            selectedColor: colorAcento,
                            backgroundColor: colorTarjeta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      texto: 'Crear cuenta gratis',
                      onPressed: _registrar,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
