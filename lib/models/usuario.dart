enum RolUsuario { artista, oyente }

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final RolUsuario rol;
  final String? fotoUrl;
  final bool esVerificado;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.fotoUrl,
    this.esVerificado = false,
  });
}