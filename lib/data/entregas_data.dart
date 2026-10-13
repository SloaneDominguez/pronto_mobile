import '../models/delivery.dart';

/// Igual que `productosDemo` en Inventario: vive en memoria mientras la
/// app esté abierta. Al estar aquí (y no dentro del State de la
/// pantalla), el revisor automático de horarios puede leerla y
/// modificarla aunque el usuario no tenga la Agenda abierta en pantalla.
final List<Delivery> entregasDemo = [
  Delivery(
    id: '1',
    cliente: 'Felipe',
    total: 120,
    lugar: 'Diana Cazadora',
    fecha: DateTime(2026, 5, 27, 15, 45),
  ),
  Delivery(
    id: '2',
    cliente: 'Diana',
    total: 80,
    lugar: 'Aurrera',
    fecha: DateTime(2026, 5, 27, 16, 30),
  ),
  Delivery(
    id: '3',
    cliente: 'Maria',
    total: 60,
    lugar: 'Oxxo San Miguel',
    fecha: DateTime(2026, 5, 27, 18, 0),
  ),
  Delivery(
    id: '4',
    cliente: 'Juan',
    total: 95,
    lugar: 'Diana Cazadora',
    fecha: DateTime(2026, 6, 2, 16, 0),
  ),
];
