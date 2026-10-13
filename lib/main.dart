import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

void main() async {
  // 1. Vinculación obligatoria con los servicios nativos de Android/iOS
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicialización de Firebase pasando las opciones de la plataforma actual
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error crítico al inicializar Firebase: $e');
  }

  runApp(const ProntoApp());
}

class ProntoApp extends StatelessWidget {
  const ProntoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pronto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ProntoColors.naranja),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
