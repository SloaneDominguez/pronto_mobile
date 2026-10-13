import 'package:flutter/material.dart';

class ProntoColors {
  static const naranja = Color(0xFFF07C22);
  static const naranjaOscuro = Color(0xFFE0691A);
  static const fondoClaro = Color(0xFFF4F4F4);
  static const textoOscuro = Color(0xFF222222);
}

final prontoTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: ProntoColors.fondoClaro,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ProntoColors.naranja,
    primary: ProntoColors.naranja,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ProntoColors.naranja,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    ),
  ),
);
