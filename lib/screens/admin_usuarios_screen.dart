import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_usuario_screen.dart'; // Importamos la nueva pantalla

class AdminUsuariosScreen extends StatelessWidget {
  const AdminUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: const Color(0xFFFF6B00), // Pronto naranja
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .orderBy('fechaRegistro', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Manejo de errores
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error de Firebase:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No hay usuarios registrados aún.'));
          }

          final usuarios = snapshot.data!.docs;

          // MÉTRICAS DEL DASHBOARD
          final totalUsuarios = usuarios.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECCIÓN DEL DASHBOARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]),
                child: Row(
                  children: [
                    _construirTarjetaMetrica(
                      titulo: 'Total Registrados',
                      valor: totalUsuarios.toString(),
                      icono: Icons.people_alt_outlined,
                      color: const Color(0xFFFF6B00),
                    ),
                    // Aquí podremos agregar más tarjetas en el futuro (ej. Usuarios Activos hoy)
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Text('Lista de Emprendedores',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),

              // --- SECCIÓN DE LA LISTA DE USUARIOS ---
              Expanded(
                child: ListView.builder(
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final documento = usuarios[index];
                    final data = documento.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: const CircleAvatar(
                          backgroundColor:
                              Color(0xFFFFF0E6), // Naranja muy claro
                          child:
                              Icon(Icons.storefront, color: Color(0xFFFF6B00)),
                        ),
                        title: Text(
                          data['nombreEmprendimiento'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data['email'] ?? 'Sin correo',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          // NAVEGACIÓN A LA VISTA DETALLADA
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleUsuarioScreen(
                                userData: data,
                                userId: documento.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget para armar los recuadros del Dashboard
  Widget _construirTarjetaMetrica(
      {required String titulo,
      required String valor,
      required IconData icono,
      required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color, size: 32),
            const SizedBox(height: 12),
            Text(valor,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(titulo,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
