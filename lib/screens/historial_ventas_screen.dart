import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialVentasScreen extends StatelessWidget {
  const HistorialVentasScreen({super.key});

  // Función auxiliar para leer la fecha de forma segura
  DateTime _obtenerFechaVenta(dynamic valorFecha) {
    if (valorFecha == null) return DateTime.now();
    if (valorFecha is Timestamp) return valorFecha.toDate();
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        backgroundColor: const Color(0xFFFF6B00), // Pronto Naranja
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // QUITAMOS EL ORDER BY DE FIREBASE. Solo pedimos las ventas de tu usuario.
        stream: FirebaseFirestore.instance
            .collection('ventas')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar historial:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has registrado ninguna venta.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // ORDENAMOS LA LISTA DIRECTAMENTE EN FLUTTER (Más rápido y sin errores de índice)
          final ventas = snapshot.data!.docs.toList();
          ventas.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final fechaA = _obtenerFechaVenta(dataA['fechaRegistro']);
            final fechaB = _obtenerFechaVenta(dataB['fechaRegistro']);
            return fechaB
                .compareTo(fechaA); // Orden descendente (más nuevas primero)
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final data = ventas[index].data() as Map<String, dynamic>;
              final double total = (data['total'] ?? 0).toDouble();
              final String estado =
                  (data['estado'] ?? 'desconocido').toUpperCase();
              final List productos = data['productos'] ?? [];
              final origen = data['origen'] ?? 'directa';

              // Formateo de fecha
              final date = _obtenerFechaVenta(data['fechaRegistro']);
              final String fechaFormateada =
                  '${date.day}/${date.month}/${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFFFF6B00).withValues(alpha: 0.15),
                      child: Icon(
                          origen == 'agenda'
                              ? Icons.calendar_month
                              : Icons.receipt_long,
                          color: const Color(0xFFFF6B00)),
                    ),
                    title: Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('$fechaFormateada\nEstado: $estado'),
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16)),
                          border: Border(
                              top: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Detalle de la compra:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                                if (origen == 'agenda')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text('Vino de Agenda',
                                        style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (productos.isEmpty)
                              const Text('No hay productos registrados',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey))
                            else
                              ...productos.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            '${item['cantidad']}x ${item['nombre']}',
                                            style:
                                                const TextStyle(fontSize: 15)),
                                      ),
                                      Text(
                                          '\$${(item['subtotal'] ?? 0).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
