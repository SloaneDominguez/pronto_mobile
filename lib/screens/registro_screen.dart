import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _authService = AuthService();
  final _controladorEmprendimiento = TextEditingController();
  final _controladorEmail = TextEditingController();
  final _controladorPassword = TextEditingController();
  final _controladorConfirmar = TextEditingController();

  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _controladorEmprendimiento.dispose();
    _controladorEmail.dispose();
    _controladorPassword.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  Future<void> _registrarCuenta() async {
    final emprendimiento = _controladorEmprendimiento.text.trim();
    final email = _controladorEmail.text.trim();
    final password = _controladorPassword.text;
    final confirmar = _controladorConfirmar.text;

    if (emprendimiento.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos.');
      return;
    }

    if (password != confirmar) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      // Llamada correcta al método en AuthService
      await _authService.registroConEmailYPassword(
          email, password, emprendimiento);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = 'No se pudo registrar la cuenta: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            color: ProntoColors.naranja,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Text('Volver a Inicio de Sesión',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                children: [
                  const Text('Registro de cuenta',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controladorEmprendimiento,
                    decoration: const InputDecoration(
                        labelText: 'Nombre de tu emprendimiento'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controladorEmail,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controladorPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controladorConfirmar,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _registrarCuenta,
                          child: const Text('Registrar cuenta'),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
