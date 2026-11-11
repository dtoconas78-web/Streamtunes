import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/viewmodels/auth_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/registro_screen.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';

// Pantalla de acceso: entrar con Google, con email o como invitado.
// El home de main.dart reacciona solo al login: acá no se navega a mano.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _mostrarFormularioEmail = false;
  bool _cargando = false;
  RolUsuario _rol = RolUsuario.oyente;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _error(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // Envuelve las llamadas al servicio (simulado hoy, real después) con carga.
  Future<void> _ejecutar(Future<void> Function() accion) async {
    if (_cargando) return;
    setState(() => _cargando = true);
    try {
      await accion();
    } catch (_) {
      _error('No se pudo entrar. Probá de nuevo.');
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _ingresarConEmail() {
    if (!_formKey.currentState!.validate()) return;
    _ejecutar(
      () => authViewModel.loginConEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        rol: _rol,
      ),
    );
  }

  // Google no devuelve el rol: se elige antes de entrar.
  Future<void> _ingresarConGoogle() async {
    final rol = await showModalBottomSheet<RolUsuario>(
      context: context,
      backgroundColor: colorTarjeta,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Cómo entrás con Google?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elegí el rol de esta cuenta:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              for (final r in [RolUsuario.artista, RolUsuario.oyente])
                ListTile(
                  leading: Icon(
                    r == RolUsuario.artista ? Icons.mic : Icons.headphones,
                    color: colorAcento,
                  ),
                  title: Text(r == RolUsuario.artista ? 'Artista' : 'Oyente'),
                  subtitle: Text(
                    r == RolUsuario.artista
                        ? 'Subo mi música, publico conciertos y veo mis ventas'
                        : 'Escucho gratis, compro entradas y apoyo directo al artista',
                  ),
                  onTap: () => Navigator.pop(ctx, r),
                ),
            ],
          ),
        ),
      ),
    );
    if (rol != null) {
      await _ejecutar(() => authViewModel.loginConGoogle(rol: rol));
    }
  }

  Widget _botonGoogle() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.grey),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: const CircleAvatar(
          radius: 11,
          backgroundColor: Colors.white,
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        label: const Text('Continuar con Google'),
        onPressed: _ingresarConGoogle,
      ),
    );
  }

  Widget _selectorRol() {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Text('Artista'),
            selected: _rol == RolUsuario.artista,
            onSelected: (_) => setState(() => _rol = RolUsuario.artista),
            selectedColor: colorAcento,
            backgroundColor: colorTarjeta,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Text('Oyente'),
            selected: _rol == RolUsuario.oyente,
            onSelected: (_) => setState(() => _rol = RolUsuario.oyente),
            selectedColor: colorAcento,
            backgroundColor: colorTarjeta,
          ),
        ),
      ],
    );
  }

  Widget _formularioEmail() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
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
          const SizedBox(height: 16),
          _selectorRol(),
          const SizedBox(height: 20),
          BotonPrincipal(texto: 'Ingresar con email', onPressed: _ingresarConEmail),
        ],
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
                  'Música gratis. Apoyo directo al artista.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                if (_cargando)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: colorAcento),
                  )
                else ...[
                  _botonGoogle(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_mostrarFormularioEmail)
                    _formularioEmail()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorAcento,
                          side: const BorderSide(color: colorAcento),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () =>
                            setState(() => _mostrarFormularioEmail = true),
                        child: const Text('Continuar con email'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _ejecutar(authViewModel.entrarComoInvitado),
                    child: const Text(
                      'Entrar como invitado',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(
                    'Como invitado solo podés escuchar gratis.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: '¿No tenés cuenta? ',
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Crear cuenta gratis',
                            style: TextStyle(
                              color: colorAcento,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
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
