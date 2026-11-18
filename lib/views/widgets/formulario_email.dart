import 'package:flutter/material.dart';
import 'package:streamtunes_demo/models/usuario.dart';
import 'package:streamtunes_demo/utils/formularios.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';
import 'package:streamtunes_demo/views/widgets/selector_rol.dart';

// Formulario de ingreso con email: campos, selector de rol y botón.
// Los controladores y la GlobalKey pertenecen al State de la pantalla que lo
// usa; este widget solo renderiza el formulario y llama a los callbacks.
class FormularioEmail extends StatelessWidget {
  const FormularioEmail({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.rol,
    required this.onRolChanged,
    required this.onIngresar,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final RolUsuario rol;
  final ValueChanged<RolUsuario> onRolChanged;
  final VoidCallback onIngresar;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: decoracionFormulario('Email'),
            validator: validarEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: decoracionFormulario('Contraseña'),
            validator: validarPassword,
          ),
          const SizedBox(height: 16),
          SelectorRol(rol: rol, onChanged: onRolChanged),
          const SizedBox(height: 20),
          BotonPrincipal(texto: 'Ingresar con email', onPressed: onIngresar),
        ],
      ),
    );
  }
}
