import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';

const _coleccionInventario = 'inventario';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _firestore = FirestoreService();
  final _controladorBusqueda = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  // --- FORMULARIO MODERNO DESLIZABLE (BOTTOM SHEET) ---
  Future<void> _abrirFormulario({Map<String, dynamic>? producto}) async {
    final controladorNombre =
        TextEditingController(text: producto?['nombre'] ?? '');
    final controladorPrecio =
        TextEditingController(text: producto?['precio']?.toString() ?? '');
    final controladorCantidad =
        TextEditingController(text: producto?['cantidad']?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que suba con el teclado
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              24, // Sube con el teclado
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              producto == null ? 'Nuevo Producto' : 'Editar Producto',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controladorNombre,
              decoration: InputDecoration(
                labelText: 'Nombre del producto',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controladorPrecio,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: controladorCantidad,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ProntoColors.naranja,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final nombre = controladorNombre.text.trim();
                  final precio = double.tryParse(controladorPrecio.text) ?? 0;
                  final cantidad = int.tryParse(controladorCantidad.text) ?? 0;

                  if (nombre.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('El nombre es obligatorio')));
                    return;
                  }

                  final datos = {
                    'nombre': nombre,
                    'precio': precio,
                    'cantidad': cantidad
                  };

                  if (producto == null) {
                    await _firestore.agregar(_coleccionInventario, datos);
                  } else {
                    await _firestore.actualizar(
                        _coleccionInventario, producto['id'], datos);
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Guardar Producto',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarProducto(String id) {
    return _firestore.eliminar(_coleccionInventario, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      // --- BOTÓN FLOTANTE ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ProntoColors.naranja,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label:
            const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _encabezado(context),

          // --- BARRA DE BÚSQUEDA ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextField(
              controller: _controladorBusqueda,
              onChanged: (texto) => setState(() => _busqueda = texto),
              decoration: InputDecoration(
                hintText: 'Buscar en tu inventario...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon:
                    const Icon(Icons.search, color: ProntoColors.naranja),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // --- LISTA DE PRODUCTOS ---
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.escuchar(_coleccionInventario),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: ProntoColors.naranja));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final productos = (snapshot.data ?? [])
                    .where((p) => (p['nombre'] as String)
                        .toLowerCase()
                        .contains(_busqueda.toLowerCase()))
                    .toList();

                if (productos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _busqueda.isEmpty
                              ? 'Tu inventario está vacío'
                              : 'No se encontraron resultados',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 80,
                      top: 10), // Padding inferior para el FAB
                  itemCount: productos.length,
                  itemBuilder: (_, i) {
                    final p = productos[i];
                    final String nombre = p['nombre'];
                    final letraInicial =
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'P';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor:
                              ProntoColors.naranja.withValues(alpha: 0.15),
                          child: Text(letraInicial,
                              style: const TextStyle(
                                  color: ProntoColors.naranja,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20)),
                        ),
                        title: Text(nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              // Etiqueta de Precio
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    '\$${(p['precio'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              // Etiqueta de Stock
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (p['cantidad'] as num) <= 5
                                      ? Colors.red.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Stock: ${p['cantidad']}',
                                    style: TextStyle(
                                        color: (p['cantidad'] as num) <= 5
                                            ? Colors.red.shade700
                                            : Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (accion) {
                            if (accion == 'editar') {
                              _abrirFormulario(producto: p);
                            } else if (accion == 'eliminar') {
                              _eliminarProducto(p['id']);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'editar',
                                child: Row(children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 10),
                                  Text('Editar')
                                ])),
                            const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(children: [
                                  Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  SizedBox(width: 10),
                                  Text('Eliminar',
                                      style: TextStyle(color: Colors.red))
                                ])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// El encabezado permanece igual para mantener la identidad visual
Widget _encabezado(BuildContext context) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
    decoration: const BoxDecoration(
      color: ProntoColors.naranja,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
            ),
            const Text('Atrás',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Módulo de',
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const Text('Inventario',
            style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
