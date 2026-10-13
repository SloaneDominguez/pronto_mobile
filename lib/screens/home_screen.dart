import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'inventario_screen.dart';
import 'ventas_screen.dart';
import 'agenda_screen.dart';
import 'login_screen.dart';
import 'admin_usuarios_screen.dart';
import 'historial_ventas_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final usuario = authService.usuarioActual; //[cite: 4]
    final nombreEmprendedor =
        usuario?.displayName ?? 'Emprendedor(a)'; //[cite: 4]

    // Obtenemos la primera letra para el avatar
    final inicial =
        nombreEmprendedor.isNotEmpty ? nombreEmprendedor[0].toUpperCase() : 'E';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), //[cite: 4]
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start, //[cite: 4]
        children: [
          // --- ENCABEZADO MODERNO ---
          Container(
            width: double.infinity, //[cite: 4]
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
                color: ProntoColors.naranja, //[cite: 4]
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                      color: ProntoColors.naranja.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 4]
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, //[cite: 4]
                    children: [
                      const Text(
                        'Bienvenido a', //[cite: 4]
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const Text(
                        'Pronto', //[cite: 4]
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white24,
                            child: Text(inicial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nombreEmprendedor, //[cite: 4]
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout,
                      color: Colors.white, size: 28), //[cite: 4]
                  tooltip: 'Cerrar sesión', //[cite: 4]
                  style: IconButton.styleFrom(backgroundColor: Colors.white24),
                  onPressed: () async {
                    await authService.cerrarSesion(); //[cite: 4]
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const LoginScreen()), //[cite: 4]
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // --- BANNER DE ADMINISTRADOR (Solo para Fátima) ---
          if (usuario?.email == 'fdb2330910@gmail.com') ...[
            //[cite: 4]
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Material(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const AdminUsuariosScreen()), //[cite: 4]
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                              color: Colors.white24, shape: BoxShape.circle),
                          child: const Icon(Icons.admin_panel_settings,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modo Administrador',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('Gestionar usuarios registrados',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // --- TÍTULO SECCIÓN CENTRAL ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '¿Qué deseas hacer hoy?', //[cite: 4]
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
          ),

          const SizedBox(height: 16),

          // --- CUADRÍCULA DE MÓDULOS (Dashboard) ---
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              crossAxisCount: 2, // Dos columnas
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, // Tarjetas perfectamente cuadradas
              children: [
                _construirTarjetaModulo(
                  context,
                  titulo: 'Inventario', //[cite: 4]
                  icono: Icons.inventory_2_outlined, //[cite: 4]
                  colorIcono: Colors.blue.shade600,
                  destino: const InventarioScreen(), //[cite: 4]
                ),
                _construirTarjetaModulo(
                  context,
                  titulo: 'Nueva Venta', //[cite: 4]
                  icono: Icons.point_of_sale_outlined, //[cite: 4]
                  colorIcono: Colors.green.shade600,
                  destino: const VentasScreen(), //[cite: 4]
                ),
                _construirTarjetaModulo(
                  context,
                  titulo: 'Agenda',
                  icono: Icons.calendar_month_outlined, //[cite: 4]
                  colorIcono: Colors.purple.shade600,
                  destino: const AgendaScreen(), //[cite: 4]
                ),
                _construirTarjetaModulo(
                  context,
                  titulo: 'Historial',
                  icono: Icons.receipt_long_outlined, //[cite: 4]
                  colorIcono: ProntoColors.naranja,
                  destino: const HistorialVentasScreen(), //[cite: 4]
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para construir las tarjetas del Dashboard
  Widget _construirTarjetaModulo(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Color colorIcono,
    required Widget destino,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destino),
          );
        },
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, size: 36, color: colorIcono),
              ),
              const SizedBox(height: 16),
              Text(
                titulo,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
