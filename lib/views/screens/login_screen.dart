import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/utils/errores_auth.dart';
import 'package:streamtunes_demo/inyeccion.dart';
import 'package:streamtunes_demo/navigation/rutas.dart';
import 'package:streamtunes_demo/views/widgets/boton_google.dart';
import 'package:streamtunes_demo/views/widgets/elegir_rol.dart';
import 'package:streamtunes_demo/views/widgets/formulario_email.dart';

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
  RolUsuario _rol = RolUsuario.oyente;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _error(String mensaje) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // El estado de carga y el error viven en el AuthViewModel; acá solo se
  // traduce el error crudo con descripcionErrorAuth, conservando los mensajes
  // específicos de Firebase/Google. Como el VM limpia el error al comenzar
  // cada operación, nunca mostramos un error viejo.
  void _mostrarErrorSiHubo() {
    final e = authViewModel.ultimoError;
    if (e != null && mounted) _error(descripcionErrorAuth(e));
  }

  Future<void> _ingresarConEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await authViewModel.loginConEmail(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      rol: _rol,
    );
    _mostrarErrorSiHubo();
  }

  // Google no devuelve el rol: se elige antes de entrar.
  Future<void> _ingresarConGoogle() async {
    final rol = await elegirRol(context, titulo: '¿Cómo entrás con Google?');
    if (rol == null) return;
    await authViewModel.loginConGoogle(rol: rol);
    _mostrarErrorSiHubo();
  }

  Future<void> _entrarComoInvitado() async {
    await authViewModel.entrarComoInvitado();
    _mostrarErrorSiHubo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ListenableBuilder(
              listenable: authViewModel,
              builder: (context, _) => Column(
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
                  if (authViewModel.cargando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(color: colorAcento),
                    )
                  else ...[
                    BotonGoogle(
                      texto: 'Continuar con Google',
                      onPressed: _ingresarConGoogle,
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'o',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_mostrarFormularioEmail)
                      FormularioEmail(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        rol: _rol,
                        onRolChanged: (rol) => setState(() => _rol = rol),
                        onIngresar: _ingresarConEmail,
                      )
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
                      onPressed: _entrarComoInvitado,
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
                      onPressed: () => irA(context, Rutas.registro),
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
      ),
    );
  }
}
