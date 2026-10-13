import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/firestore_service.dart';

const _coleccionEntregas = 'entregas';

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre'
];

String _formatearFecha(DateTime f) =>
    '${f.day} de ${_meses[f.month - 1]} de ${f.year}';

String _formatearHora(DateTime f) {
  final h = f.hour;
  final m = f.minute.toString().padLeft(2, '0');
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final sufijo = h < 12 ? 'am' : 'pm';
  return '$h12:$m $sufijo';
}

DateTime _obtenerFecha(dynamic valorFecha) {
  if (valorFecha == null) return DateTime.now();
  if (valorFecha is Timestamp) return valorFecha.toDate();
  if (valorFecha is String) {
    return DateTime.tryParse(valorFecha) ?? DateTime.now();
  }
  return DateTime.now();
}

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _firestore = FirestoreService();
  final _auth = FirebaseAuth.instance;

  // =========================================================================
  // NUEVA FUNCIÓN: COMPLETAR ENTREGA, DESCONTAR INVENTARIO Y REGISTRAR VENTA
  // =========================================================================
  Future<void> _completarEntregaYRegistrarVenta(
      Map<String, dynamic> entrega, String entregaId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Usuario no autenticado';

      final List productos = entrega['productos'] ?? [];
      final double total = (entrega['total'] ?? 0).toDouble();

      // Iniciamos el Batch (Operación en bloque)
      final batch = FirebaseFirestore.instance.batch();

      // 1. Actualizar el estado de la entrega a 'completada'
      final entregaRef = FirebaseFirestore.instance
          .collection(_coleccionEntregas)
          .doc(entregaId);
      batch.update(entregaRef, {'estado': 'completada'});

      // 2. Crear el registro en el Historial de Ventas
      final ventaRef = FirebaseFirestore.instance.collection('ventas').doc();
      batch.set(ventaRef, {
        'userId': user.uid,
        'productos': productos,
        'total': total,
        'estado': 'completada',
        'origen': 'agenda', // Para saber que vino de una entrega agendada
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      // 3. Descontar los productos del inventario
      for (var p in productos) {
        final prodRef = FirebaseFirestore.instance
            .collection('inventario')
            .doc(p['idProducto']);
        batch.update(
            prodRef, {'cantidad': FieldValue.increment(-p['cantidad'])});
      }

      // Ejecutar todo de golpe
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  '¡Entrega completada! Venta registrada e inventario descontado.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al procesar: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // =========================================================================
  // DIÁLOGO PARA SELECCIONAR PRODUCTOS DEL INVENTARIO
  // =========================================================================
  Future<void> _seleccionarProducto(StateSetter setFormState,
      List<Map<String, dynamic>> carritoActual) async {
    final user = _auth.currentUser;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('inventario')
                  .where('userId', isEqualTo: user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No hay productos en tu inventario.');
                }

                final productos = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final p = productos[index].data() as Map<String, dynamic>;
                    final docId = productos[index].id;
                    final stock = p['cantidad'] ?? 0;

                    return ListTile(
                      leading: const Icon(Icons.inventory_2,
                          color: ProntoColors.naranja),
                      title: Text(p['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text('Precio: \$${p['precio']} | Stock: $stock'),
                      onTap: () {
                        if (stock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sin stock')));
                          return;
                        }
                        // Agregamos al carrito del formulario (por defecto cantidad 1)
                        setFormState(() {
                          final existeIndex = carritoActual.indexWhere(
                              (item) => item['idProducto'] == docId);
                          if (existeIndex >= 0) {
                            if (carritoActual[existeIndex]['cantidad'] <
                                stock) {
                              carritoActual[existeIndex]['cantidad']++;
                              carritoActual[existeIndex]['subtotal'] =
                                  carritoActual[existeIndex]['cantidad'] *
                                      carritoActual[existeIndex]
                                          ['precioUnitario'];
                            }
                          } else {
                            carritoActual.add({
                              'idProducto': docId,
                              'nombre': p['nombre'],
                              'cantidad': 1,
                              'precioUnitario': (p['precio'] ?? 0).toDouble(),
                              'subtotal': (p['precio'] ?? 0).toDouble(),
                            });
                          }
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'))
          ],
        );
      },
    );
  }

  // =========================================================================
  // FORMULARIO DE AGENDA (BOTTOM SHEET)
  // =========================================================================
  Future<void> _abrirFormulario({Map<String, dynamic>? entrega}) async {
    final controladorCliente =
        TextEditingController(text: entrega?['cliente'] ?? '');
    final controladorLugar =
        TextEditingController(text: entrega?['lugar'] ?? '');

    // Si estamos editando, cargamos los productos guardados; si no, lista vacía
    List<Map<String, dynamic>> carrito =
        List<Map<String, dynamic>>.from(entrega?['productos'] ?? []);

    DateTime fechaSeleccionada = entrega != null
        ? _obtenerFecha(entrega['fecha'])
        : DateTime.now().add(const Duration(minutes: 30));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        // Calculamos el total dinámicamente basado en los productos seleccionados
        double totalCalculado =
            carrito.fold(0, (suma, item) => suma + (item['subtotal'] ?? 0));

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entrega == null ? 'Nueva Entrega' : 'Editar Entrega',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: controladorCliente,
                  decoration: InputDecoration(
                    labelText: 'Nombre del cliente',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: controladorLugar,
                  decoration: InputDecoration(
                    labelText: 'Lugar de entrega',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // SELECCIÓN DE PRODUCTOS (NUEVO)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Productos a entregar:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.add_shopping_cart,
                          color: ProntoColors.naranja),
                      label: const Text('Agregar',
                          style: TextStyle(color: ProntoColors.naranja)),
                      onPressed: () =>
                          _seleccionarProducto(setDialogState, carrito),
                    )
                  ],
                ),

                if (carrito.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No has seleccionado productos.',
                          style: TextStyle(color: Colors.grey)))
                else
                  ...carrito.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '${item['cantidad']}x ${item['nombre']}')),
                            Text('\$${item['subtotal'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  if (item['cantidad'] > 1) {
                                    item['cantidad']--;
                                    item['subtotal'] = item['cantidad'] *
                                        item['precioUnitario'];
                                  } else {
                                    carrito.remove(item);
                                  }
                                });
                              },
                            )
                          ],
                        ),
                      )),

                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL A COBRAR:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('\$${totalCalculado.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: ProntoColors.naranja)),
                  ],
                ),
                const SizedBox(height: 20),

                // Selectores de Fecha y Hora modernos
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ProntoColors.naranja.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: ProntoColors.naranja.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: ProntoColors.naranja, size: 20),
                              const SizedBox(width: 8),
                              Text(_formatearFecha(fechaSeleccionada),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: ProntoColors.naranja),
                            onPressed: () async {
                              final elegida = await showDatePicker(
                                context: context,
                                initialDate: fechaSeleccionada,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (elegida != null) {
                                setDialogState(() => fechaSeleccionada =
                                    DateTime(
                                        elegida.year,
                                        elegida.month,
                                        elegida.day,
                                        fechaSeleccionada.hour,
                                        fechaSeleccionada.minute));
                              }
                            },
                            child: const Text('Cambiar'),
                          ),
                        ],
                      ),
                      const Divider(height: 0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: ProntoColors.naranja, size: 20),
                              const SizedBox(width: 8),
                              Text(_formatearHora(fechaSeleccionada),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: ProntoColors.naranja),
                            onPressed: () async {
                              final elegida = await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay.fromDateTime(fechaSeleccionada),
                              );
                              if (elegida != null) {
                                setDialogState(() => fechaSeleccionada =
                                    DateTime(
                                        fechaSeleccionada.year,
                                        fechaSeleccionada.month,
                                        fechaSeleccionada.day,
                                        elegida.hour,
                                        elegida.minute));
                              }
                            },
                            child: const Text('Cambiar'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                      final cliente = controladorCliente.text.trim();
                      final lugar = controladorLugar.text.trim();

                      if (cliente.isEmpty || lugar.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Falta cliente o lugar')));
                        return;
                      }
                      if (carrito.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Debes agregar al menos un producto')));
                        return;
                      }

                      final user = _auth.currentUser;
                      final datos = {
                        'userId': user?.uid,
                        'cliente': cliente,
                        'total': totalCalculado,
                        'lugar': lugar,
                        'fecha': fechaSeleccionada.toIso8601String(),
                        'estado': entrega?['estado'] ?? 'pendiente',
                        'productos': carrito, // Guardamos la lista de productos
                      };

                      if (entrega == null) {
                        await _firestore.agregar(_coleccionEntregas, datos);
                      } else {
                        await _firestore.actualizar(
                            _coleccionEntregas, entrega['id'], datos);
                      }
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Guardar Entrega',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _eliminarEntrega(String id) =>
      _firestore.eliminar(_coleccionEntregas, id);
  Future<void> _cambiarEstadoSimple(String id, String estado) =>
      _firestore.actualizar(_coleccionEntregas, id, {'estado': estado});

  // =========================================================================
  // INTERFAZ PRINCIPAL DE LA AGENDA
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ProntoColors.naranja,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Entrega',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _encabezado(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_coleccionEntregas)
                  .where('userId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: ProntoColors.naranja));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                final entregas = docs
                    .map((d) =>
                        {'id': d.id, ...d.data() as Map<String, dynamic>})
                    .toList();

                entregas.sort((a, b) => _obtenerFecha(a['fecha'])
                    .compareTo(_obtenerFecha(b['fecha'])));

                if (entregas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No tienes entregas agendadas',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 80, top: 16),
                  itemCount: entregas.length,
                  itemBuilder: (_, i) {
                    final e = entregas[i];
                    final fecha = _obtenerFecha(e['fecha']);
                    final String estadoStr = e['estado'] ?? 'pendiente';

                    Color colorEstado = Colors.orange;
                    IconData iconoEstado = Icons.pending_actions;
                    String textoEstado = 'Pendiente';

                    if (estadoStr == 'completada') {
                      colorEstado = Colors.green;
                      iconoEstado = Icons.check_circle;
                      textoEstado = 'Completada';
                    } else if (estadoStr == 'no_entregada') {
                      colorEstado = Colors.red;
                      iconoEstado = Icons.cancel;
                      textoEstado = 'No entregada';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.only(
                                left: 16, right: 8, top: 4),
                            leading: CircleAvatar(
                              backgroundColor:
                                  colorEstado.withValues(alpha: 0.15),
                              child: Icon(iconoEstado, color: colorEstado),
                            ),
                            title: Text(e['cliente'] ?? 'Sin cliente',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              onSelected: (accion) {
                                if (accion == 'editar') {
                                  _abrirFormulario(entrega: e);
                                } else if (accion == 'eliminar')
                                  _eliminarEntrega(e['id']);
                                else if (accion == 'completada') {
                                  // AQUÍ ES DONDE SUCEDE LA MAGIA DE LA VINCULACIÓN
                                  _completarEntregaYRegistrarVenta(e, e['id']);
                                } else
                                  _cambiarEstadoSimple(e['id'], accion);
                              },
                              itemBuilder: (_) => [
                                // Si ya está completada, no mostramos de nuevo la opción para evitar duplicar ventas
                                if (estadoStr != 'completada')
                                  const PopupMenuItem(
                                      value: 'completada',
                                      child: Row(children: [
                                        Icon(Icons.check,
                                            color: Colors.green, size: 20),
                                        SizedBox(width: 10),
                                        Text('Marcar completada')
                                      ])),
                                if (estadoStr != 'pendiente')
                                  const PopupMenuItem(
                                      value: 'pendiente',
                                      child: Row(children: [
                                        Icon(Icons.access_time,
                                            color: Colors.orange, size: 20),
                                        SizedBox(width: 10),
                                        Text('Regresar a pendiente')
                                      ])),
                                if (estadoStr != 'no_entregada')
                                  const PopupMenuItem(
                                      value: 'no_entregada',
                                      child: Row(children: [
                                        Icon(Icons.close,
                                            color: Colors.red, size: 20),
                                        SizedBox(width: 10),
                                        Text('Marcar no entregada')
                                      ])),
                                const PopupMenuDivider(),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(e['lugar'] ?? 'Sin lugar',
                                            style: TextStyle(
                                                color: Colors.grey.shade700))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey.shade500),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${_formatearFecha(fecha)} • ${_formatearHora(fecha)}',
                                        style: TextStyle(
                                            color: Colors.grey.shade700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 0),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(textoEstado,
                                      style: TextStyle(
                                          color: colorEstado,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12)),
                                ),
                                Text(
                                  'Total: \$${((e['total'] ?? 0) as num).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: ProntoColors.naranja),
                                ),
                              ],
                            ),
                          ),
                        ],
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
        const Text('Agenda de entregas',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
