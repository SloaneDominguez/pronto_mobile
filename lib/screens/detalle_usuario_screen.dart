import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetalleUsuarioScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const DetalleUsuarioScreen({
    super.key,
    required this.userData,
    required this.userId,
  });

  @override
  State<DetalleUsuarioScreen> createState() => _DetalleUsuarioScreenState();
}

class _DetalleUsuarioScreenState extends State<DetalleUsuarioScreen> {
  bool _estaSuspendido = false;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    // Revisamos si el usuario ya estaba suspendido en la base de datos
    _estaSuspendido = widget.userData['suspendido'] ?? false;
  }

  Future<void> _cambiarEstadoSuspension() async {
    setState(() => _cargando = true);

    try {
      final nuevoEstado = !_estaSuspendido;

      // Actualizamos el campo en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .set({'suspendido': nuevoEstado}, SetOptions(merge: true));

      setState(() {
        _estaSuspendido = nuevoEstado;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(nuevoEstado ? 'Cuenta suspendida' : 'Cuenta reactivada'),
            backgroundColor: nuevoEstado ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el estado')),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String fechaFormateada = 'Fecha desconocida';
    if (widget.userData['fechaRegistro'] != null) {
      final Timestamp timestamp = widget.userData['fechaRegistro'] as Timestamp;
      final DateTime date = timestamp.toDate();
      fechaFormateada =
          '${date.day}/${date.month}/${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Perfil del Emprendedor'),
        backgroundColor: const Color(0xFFFF6B00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _estaSuspendido
                    ? Colors.red.withValues(alpha: 0.1)
                    : const Color(0xFFFF6B00).withValues(alpha: 0.15),
                child: Icon(_estaSuspendido ? Icons.block : Icons.storefront,
                    size: 50,
                    color:
                        _estaSuspendido ? Colors.red : const Color(0xFFFF6B00)),
              ),
            ),
            if (_estaSuspendido)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('CUENTA SUSPENDIDA',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _construirFilaInfo(Icons.business, 'Emprendimiento',
                      widget.userData['nombreEmprendimiento'] ?? 'Sin nombre'),
                  const Divider(height: 30),
                  _construirFilaInfo(Icons.email, 'Correo Electrónico',
                      widget.userData['email'] ?? 'Sin correo'),
                  const Divider(height: 30),
                  _construirFilaInfo(Icons.calendar_today, 'Fecha de Registro',
                      fechaFormateada),
                ],
              ),
            ),

            const Spacer(),

            // Botón de Suspender/Reactivar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _estaSuspendido ? Colors.green : Colors.red,
                  side: BorderSide(
                      color: _estaSuspendido ? Colors.green : Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _cargando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_estaSuspendido ? Icons.check_circle : Icons.block),
                label: Text(
                    _estaSuspendido ? 'Reactivar Cuenta' : 'Suspender Cuenta'),
                onPressed: _cargando
                    ? null
                    : () {
                        // Diálogo de confirmación
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(_estaSuspendido
                                ? '¿Reactivar cuenta?'
                                : '¿Suspender cuenta?'),
                            content: Text(_estaSuspendido
                                ? 'El emprendedor podrá volver a iniciar sesión en la app.'
                                : 'El emprendedor no podrá acceder a su cuenta hasta que la reactives.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancelar')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _estaSuspendido
                                      ? Colors.green
                                      : Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _cambiarEstadoSuspension();
                                },
                                child: Text(_estaSuspendido
                                    ? 'Reactivar'
                                    : 'Suspender'),
                              ),
                            ],
                          ),
                        );
                      },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _construirFilaInfo(IconData icono, String titulo, String valor) {
    return Row(
      children: [
        Icon(icono, color: Colors.grey, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}
