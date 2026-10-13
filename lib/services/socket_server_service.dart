import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/delivery.dart';

/// El móvil actúa como SERVIDOR WebSocket (puerto 4040), igual que en tu
/// prueba con sockets TCP crudos, pero ahora con un handshake HTTP real
/// (dart:io HttpServer + WebSocketTransformer), que es lo que pide la
/// actividad: WebSockets de verdad, no sockets TCP a pelo.
///
/// Protocolo (mensajes JSON), campo "type":
///  - "nueva_entrega"        -> el móvil envía una Delivery al watch
///  - "entrega_completada"   -> el watch avisa que se completó (envía id)
///  - "entrega_no_entregada" -> el watch avisa que no se entregó (envía id)
class SocketServerService {
  static const int puerto = 4040;

  HttpServer? _server;
  final List<WebSocket> _clientesConectados = [];

  /// Notifica a la UI cuando cambia el estado de una entrega
  /// (para refrescar la pantalla de Agenda en tiempo real).
  final StreamController<Map<String, dynamic>> _eventosController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get eventos => _eventosController.stream;

  bool get hayWatchConectado => _clientesConectados.isNotEmpty;

  Future<void> iniciar() async {
    if (_server != null) return; // ya está corriendo
    _server = await HttpServer.bind(InternetAddress.anyIPv4, puerto);
    print('Servidor WebSocket de Pronto escuchando en el puerto $puerto');

    await for (final HttpRequest request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _clientesConectados.add(socket);
        print('Watch conectado. Total conectados: ${_clientesConectados.length}');

        socket.listen(
          (mensaje) => _onMensajeRecibido(mensaje),
          onDone: () {
            _clientesConectados.remove(socket);
            print('Watch desconectado.');
          },
          onError: (_) => _clientesConectados.remove(socket),
        );
      } else {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..close();
      }
    }
  }

  void _onMensajeRecibido(dynamic mensajeCrudo) {
    try {
      final Map<String, dynamic> mensaje = jsonDecode(mensajeCrudo as String);
      // Reenviamos el evento a quien esté escuchando (la pantalla de Agenda)
      _eventosController.add(mensaje);
    } catch (e) {
      print('Mensaje no válido recibido del watch: $e');
    }
  }

  /// Envía una entrega al watch para que la notifique (ej. "en 40 min...").
  void enviarNuevaEntrega(Delivery entrega) {
    _broadcast({'type': 'nueva_entrega', 'data': entrega.toJson()});
  }

  void _broadcast(Map<String, dynamic> mensaje) {
    final texto = jsonEncode(mensaje);
    for (final cliente in _clientesConectados) {
      cliente.add(texto);
    }
  }

  Future<void> detener() async {
    for (final c in _clientesConectados) {
      await c.close();
    }
    await _server?.close(force: true);
    _server = null;
  }
}
