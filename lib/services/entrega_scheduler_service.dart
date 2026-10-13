import 'dart:async';

import '../data/entregas_data.dart';
import 'socket_server_service.dart';

/// Corre en segundo plano durante toda la vida de la app (se inicia una
/// sola vez desde main.dart). Cada [intervalo] revisa la lista global
/// `entregasDemo` y, para toda entrega que:
///   - siga en estado 'pendiente'
///   - no se le haya avisado ya al watch (`notificada == false`)
///   - su fecha/hora programada ya haya llegado (o ya pasó)
/// ...le manda la notificación al watch por WebSocket automáticamente,
/// sin que nadie tenga que tocar el botón ⌚ a mano.
class EntregaSchedulerService {
  final SocketServerService socketService;
  Timer? _timer;

  EntregaSchedulerService(this.socketService);

  void iniciar({Duration intervalo = const Duration(seconds: 15)}) {
    _timer?.cancel();
    _timer = Timer.periodic(intervalo, (_) => _revisarEntregasProgramadas());
  }

  void _revisarEntregasProgramadas() {
    final ahora = DateTime.now();
    for (final entrega in entregasDemo) {
      final yaLlego = !ahora.isBefore(entrega.fecha); // ahora >= fecha
      if (entrega.estado == 'pendiente' && !entrega.notificada && yaLlego) {
        socketService.enviarNuevaEntrega(entrega);
        entrega.notificada = true;
      }
    }
  }

  void detener() {
    _timer?.cancel();
    _timer = null;
  }
}
