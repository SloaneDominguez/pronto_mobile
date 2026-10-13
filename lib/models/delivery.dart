/// Modelo de una entrega de la Agenda de entregas.
/// Este mismo modelo (con el mismo formato JSON) se usa en pronto_watch,
/// así ambas apps "hablan el mismo idioma" por WebSockets.
///
/// IMPORTANTE: `fecha` ahora guarda el día Y la hora exactos de la
/// entrega (antes solo guardábamos el día, y la hora vivía aparte como
/// texto libre). Con fecha+hora en un solo DateTime podemos comparar
/// contra "ahora" y saber automáticamente cuándo avisarle al watch.
class Delivery {
  final String id;
  String cliente;
  double total;
  String lugar;
  DateTime fecha; // incluye día y hora de la entrega
  String estado; // 'pendiente' | 'completada' | 'no_entregada'
  bool notificada; // true si ya se le avisó al watch (evita reenvíos)

  Delivery({
    required this.id,
    required this.cliente,
    required this.total,
    required this.lugar,
    required this.fecha,
    this.estado = 'pendiente',
    this.notificada = false,
  });

  /// Hora en formato "3:45 pm", derivada de `fecha` (ya no se captura
  /// aparte). Se calcula aquí para no depender de BuildContext.
  String get hora {
    final h = fecha.hour;
    final m = fecha.minute.toString().padLeft(2, '0');
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final sufijo = h < 12 ? 'am' : 'pm';
    return '$h12:$m $sufijo';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente': cliente,
        'total': total,
        'lugar': lugar,
        'hora': hora, // se manda calculado, para que pronto_watch no cambie
        'fecha': fecha.toIso8601String(),
        'estado': estado,
      };

  factory Delivery.fromJson(Map<String, dynamic> j) => Delivery(
        id: j['id'] as String,
        cliente: j['cliente'] as String,
        total: (j['total'] as num).toDouble(),
        lugar: j['lugar'] as String,
        fecha: j['fecha'] != null
            ? DateTime.parse(j['fecha'] as String)
            : DateTime.now(),
        estado: j['estado'] as String? ?? 'pendiente',
      );
}
