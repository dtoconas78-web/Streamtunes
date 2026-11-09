import 'package:flutter/material.dart';
import 'package:streamtunes_demo/theme/colores.dart';
import 'package:streamtunes_demo/viewmodels/perfil_viewmodel.dart';
import 'package:streamtunes_demo/views/screens/solicitud_verificacion_screen.dart';
import 'package:streamtunes_demo/views/widgets/boton_principal.dart';

// Pantalla Verificación: muestra una vista distinta según el estado.
class PantallaVerificacion extends StatelessWidget {
  const PantallaVerificacion({super.key});

  void _abrirFormulario(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaSolicitudVerificacion()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: perfil,
          builder: (context, _) {
            switch (perfil.estadoVerificacion) {
              case EstadoVerificacion.noSolicitada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Verificá tu perfil',
                  mensaje:
                      'Para publicar conciertos y cobrar entradas necesitamos confirmar tu identidad y dónde vas a cobrar. Subir música sigue siendo libre.',
                  hijos: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorTarjeta,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Paso(numero: 1, texto: 'Tus datos y tu documento'),
                          _Paso(numero: 2, texto: 'Tu cuenta de cobro'),
                          _Paso(numero: 3, texto: 'Revisión de nuestro equipo'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    BotonPrincipal(
                      texto: 'Empezar verificación',
                      onPressed: () => _abrirFormulario(context),
                    ),
                  ],
                );

              case EstadoVerificacion.pendiente:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Solicitud en revisión',
                  mensaje:
                      'Recibimos tus datos. Te vamos a avisar cuando haya una respuesta.',
                  hijos: [
                    // Caja de pruebas: se borra cuando exista el backend.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Solo para pruebas',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Todavía no hay backend: simulá la respuesta del equipo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      perfil.simularResultado(aprobada: true),
                                  child: const Text('Aprobar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => perfil.simularResultado(
                                    aprobada: false,
                                    motivo:
                                        'La foto del documento no se ve con claridad.',
                                  ),
                                  child: const Text('Rechazar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case EstadoVerificacion.rechazada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Solicitud rechazada',
                  mensaje: 'Motivo: ${perfil.motivoRechazo}',
                  hijos: [
                    BotonPrincipal(
                      texto: 'Volver a intentar',
                      onPressed: () => _abrirFormulario(context),
                    ),
                  ],
                );

              case EstadoVerificacion.verificada:
                return _VistaEstado(
                  icono: perfil.iconoVerificacion,
                  color: perfil.colorVerificacion,
                  titulo: 'Perfil verificado',
                  mensaje:
                      'Tu perfil tiene la insignia de verificado. Vas a poder publicar conciertos y cobrar entradas cuando esa sección esté disponible.',
                );
            }
          },
        ),
      ),
    );
  }
}

// Diseño común de todas las vistas de estado: ícono, título, mensaje y extras.
class _VistaEstado extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String mensaje;
  final List<Widget> hijos;

  const _VistaEstado({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.mensaje,
    this.hijos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 56, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...hijos,
        ],
      ),
    );
  }
}

// Un paso numerado de la lista "cómo funciona".
class _Paso extends StatelessWidget {
  final int numero;
  final String texto;

  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colorAcento,
            child: Text('$numero',
                style: const TextStyle(fontSize: 12, color: Colors.black)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}