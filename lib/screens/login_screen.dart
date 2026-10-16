import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _authService = AuthService();
  bool _cargando = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuario = await _authService.iniciarSesionConGoogle(); //[cite: 3]
      if (usuario != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        ); //[cite: 3]
      }
    } catch (e) {
      setState(() =>
          _error = 'No se pudo iniciar sesión con Google: $e'); //[cite: 3]
    } finally {
      if (mounted) setState(() => _cargando = false); //[cite: 3]
    }
  }

  /*Future<void> _iniciarSesionConFacebook() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final usuario = await _authService.iniciarSesionConFacebook(); //[cite: 3]
      if (usuario != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        ); //[cite: 3]
      }
    } catch (e) {
      setState(() => _error = e.toString()); //[cite: 3]
    } finally {
      if (mounted) setState(() => _cargando = false); //[cite: 3]
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // --- ENCABEZADO MODERNO ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(30, 80, 30, 50),
            decoration: BoxDecoration(
                color: ProntoColors.naranja, //[cite: 3]
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                      color: ProntoColors.naranja.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido a',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400)), //[cite: 3]
                SizedBox(height: 4),
                Text('Pronto',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1)), //[cite: 3]
                SizedBox(height: 8),
                Text('La app para gestionar tu emprendimiento',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 16)), //[cite: 3]
              ],
            ),
          ),

          // --- ÁREA DE CONTENIDO (Botones y alertas) ---
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono central estilizado
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ProntoColors.naranja.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront,
                          size: 64, color: ProntoColors.naranja), //[cite: 3]
                    ),
                    const SizedBox(height: 32),

                    const Text('Inicia sesión para continuar',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)), //[cite: 3]
                    const SizedBox(height: 32),

                    // 1. Campo para Correo Electrónico
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

// 2. Campo para Contraseña
                    TextField(
                      controller: passwordController,
                      obscureText: true, // Oculta los caracteres
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

// 3. Botón clásico de Iniciar Sesión
                    ElevatedButton(
                      onPressed: () {
                        // Aquí es donde agregaremos la lógica de Firebase en el siguiente paso
                        // Por ahora solo capturamos los textos: emailController.text y passwordController.text
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 50), // Botón ancho
                      ),
                      child: const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 24),

                    const Center(child: Text('O ingresa con:')),
                    const SizedBox(height: 16),

// 4. Botón de Google (Mantenemos tu lógica actual)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Aquí va la función que ya tenías para iniciar sesión con Google
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 30),
                      label: const Text('Continuar con Google'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- ZONA DE BOTONES / CARGA ---
                    if (_cargando)
                      const Column(
                        children: [
                          CircularProgressIndicator(
                              color: ProntoColors.naranja), //[cite: 3]
                          SizedBox(height: 16),
                          Text('Iniciando sesión...',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    else ...[
                      // Botón de Google
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 32),
                          ),
                          label: const Text('Continuar con Google',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)), //[cite: 3]
                          onPressed: _iniciarSesion, //[cite: 3]
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón de Facebook
                      /*SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF1877F2), //[cite: 3]
                            foregroundColor: Colors.white, //[cite: 3]
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          icon:
                              const Icon(Icons.facebook, size: 28), //[cite: 3]
                          label: const Text('Continuar con Facebook',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)), //[cite: 3]
                          onPressed: _iniciarSesionConFacebook, //[cite: 3]
                        ),
                      ),*/
                    ],

                    // --- ZONA DE ERRORES ---
                    if (_error != null) ...[
                      //[cite: 3]
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                      height: 1.4)), //[cite: 3]
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
