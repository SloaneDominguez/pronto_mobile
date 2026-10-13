import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/socket_server_service.dart';
import '../theme.dart';

/// Pantalla para vincular el watch (u otro dispositivo) al servidor
/// WebSocket que corre en el móvil. Muestra un QR real con la dirección
/// "ws://IP:puerto" y también permite copiarla a mano.
class VincularDispositivoScreen extends StatelessWidget {
  const VincularDispositivoScreen({super.key});

  Future<String> _obtenerIpLocal() async {
    for (final interfaz in await NetworkInterface.list()) {
      for (final direccion in interfaz.addresses) {
        if (direccion.type == InternetAddressType.IPv4 &&
            !direccion.isLoopback) {
          return direccion.address;
        }
      }
    }
    return 'no encontrada';
  }

  void _copiarAlPortapapeles(BuildContext context, String direccion) {
    Clipboard.setData(ClipboardData(text: direccion));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dirección copiada al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _obtenerIpLocal(),
          builder: (context, snapshot) {
            final cargando = !snapshot.hasData;
            final ip = snapshot.data ?? '';
            final direccion = 'ws://$ip:${SocketServerService.puerto}';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text('Vincular dispositivo',
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Bienvenido a',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const Text('Pronto',
                      style: TextStyle(
                          color: ProntoColors.naranja,
                          fontSize: 38,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 28),

                  // Tarjeta con el QR y la dirección WebSocket.
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black45,
                            blurRadius: 16,
                            offset: Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Escanea para vincular tu watch',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 20),
                        cargando
                            ? const SizedBox(
                                height: 180,
                                width: 180,
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: ProntoColors.naranja, width: 2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data: direccion,
                                  version: QrVersions.auto,
                                  size: 180,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        const Text('O copia la dirección manualmente:',
                            style: TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: cargando
                                    ? const Text('Buscando IP…')
                                    : SelectableText(
                                        direccion,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace'),
                                      ),
                              ),
                              if (!cargando)
                                IconButton(
                                  icon: const Icon(Icons.copy,
                                      color: ProntoColors.naranja, size: 20),
                                  tooltip: 'Copiar',
                                  onPressed: () =>
                                      _copiarAlPortapapeles(context, direccion),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Pasos, igual que en el mockup original.
                  const Text('¿Cómo vincular con la app watch?',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  const _PasoVinculacion(
                      numero: '1', texto: 'Abre la app Pronto Watch en tu reloj'),
                  const _PasoVinculacion(
                      numero: '2',
                      texto: 'Selecciona "Conectar" en la pantalla inicial'),
                  const _PasoVinculacion(
                      numero: '3',
                      texto: 'Escanea este código QR o escribe la dirección'),
                  const _PasoVinculacion(
                      numero: '4',
                      texto: '¡Listo! Ya puedes recibir entregas en tu watch'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PasoVinculacion extends StatelessWidget {
  final String numero;
  final String texto;
  const _PasoVinculacion({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: ProntoColors.naranja,
            child: Text(numero,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: const TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
