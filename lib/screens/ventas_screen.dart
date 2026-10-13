import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _auth = FirebaseAuth.instance;

  // Aquí guardaremos los productos que el usuario va seleccionando para vender
  final List<Map<String, dynamic>> _carrito = [];
  bool _procesando = false;

  // 1. FUNCIÓN MÁGICA: REGISTRAR VENTA Y DESCONTAR INVENTARIO
  Future<void> _registrarVenta() async {
    if (_carrito.isEmpty) return;

    setState(() => _procesando = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      // Iniciamos el "Batch" (Lote de operaciones)
      final batch = FirebaseFirestore.instance.batch();

      // Preparamos el documento de la nueva venta
      final ventaRef = FirebaseFirestore.instance.collection('ventas').doc();

      double totalVenta = 0;
      List<Map<String, dynamic>> resumenProductos = [];

      // Procesamos cada producto en el carrito
      for (var item in _carrito) {
        final docId = item['id'];
        final int cantidadAVender = item['cantidadAVender'];
        final double precio = item['precio'];
        final String nombre = item['nombre'];

        totalVenta += (precio * cantidadAVender);

        resumenProductos.add({
          'idProducto': docId,
          'nombre': nombre,
          'cantidad': cantidadAVender,
          'precioUnitario': precio,
          'subtotal': precio * cantidadAVender,
        });

        // Instrucción para DESCONTAR del inventario usando FieldValue.increment
        final productoRef =
            FirebaseFirestore.instance.collection('inventario').doc(docId);
        batch.update(productoRef, {
          'cantidad': FieldValue.increment(
              -cantidadAVender) // El signo menos hace que se reste
        });
      }

      // Instrucción para GUARDAR LA VENTA
      batch.set(ventaRef, {
        'userId': user.uid, // Requisito obligatorio por tus reglas de seguridad
        'productos': resumenProductos,
        'total': totalVenta,
        'estado': 'completada', // Se marca completada automáticamente
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      // Ejecutamos todo al mismo tiempo
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Venta completada y descontada del inventario'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresamos al Home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al registrar venta: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  // 2. FUNCIÓN PARA AGREGAR AL CARRITO
  void _agregarAlCarrito(DocumentSnapshot productoDoc) {
    final data = productoDoc.data() as Map<String, dynamic>;
    final int stockDisponible = data['cantidad'] ?? 0;

    if (stockDisponible <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay stock disponible de este producto')),
      );
      return;
    }

    setState(() {
      // Buscamos si el producto ya está en el carrito
      final index = _carrito.indexWhere((item) => item['id'] == productoDoc.id);

      if (index >= 0) {
        // Si ya está, le sumamos 1 si hay stock suficiente
        if (_carrito[index]['cantidadAVender'] < stockDisponible) {
          _carrito[index]['cantidadAVender']++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock máximo alcanzado')),
          );
        }
      } else {
        // Si no está, lo agregamos por primera vez
        _carrito.add({
          'id': productoDoc.id,
          'nombre': data['nombre'] ?? 'Producto',
          'precio': (data['precio'] ?? 0.0).toDouble(),
          'cantidadAVender': 1,
          'stockMaximo':
              stockDisponible, // Guardamos esto para que no vendan más de lo que tienen
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    double totalAcumulado = _carrito.fold(
        0, (suma, item) => suma + (item['precio'] * item['cantidadAVender']));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Nueva Venta'),
        backgroundColor: const Color(0xFFFF6B00), // Pronto Naranja
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ZONA SUPERIOR: LISTA DE PRODUCTOS DEL INVENTARIO
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              // Leemos SOLO el inventario del usuario actual
              stream: FirebaseFirestore.instance
                  .collection('inventario')
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Tu inventario está vacío.'));
                }

                final productos = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final data =
                        productos[index].data() as Map<String, dynamic>;
                    final stock = data['cantidad'] ?? 0;

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2,
                            color: Color(0xFFFF6B00)),
                        title: Text(data['nombre'] ?? 'Sin nombre',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            Text('Stock: $stock | Precio: \$${data['precio']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart,
                              color: Colors.black87),
                          onPressed: () => _agregarAlCarrito(productos[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ZONA INFERIOR: CARRITO Y BOTÓN DE CONFIRMAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Productos a vender:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                // Lista de items en el carrito
                if (_carrito.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No has seleccionado productos.',
                          style: TextStyle(color: Colors.grey)))
                else
                  ..._carrito.map((item) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text(
                                  '${item['cantidadAVender']}x ${item['nombre']}')),
                          Text(
                              '\$${(item['precio'] * item['cantidadAVender']).toStringAsFixed(2)}'),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                if (item['cantidadAVender'] > 1) {
                                  item['cantidadAVender']--;
                                } else {
                                  _carrito.remove(item);
                                }
                              });
                            },
                          )
                        ],
                      )),

                const Divider(height: 24),

                // Total y Botón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text('\$${totalAcumulado.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFFFF6B00))),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed:
                      _procesando || _carrito.isEmpty ? null : _registrarVenta,
                  child: _procesando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRMAR VENTA Y DESCONTAR',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
