import 'package:flutter/material.dart';

/// Paleta tierra de "colores_para_app.png" (2026-09-14): fondo crema, marron
/// oxido como color principal (mas vivo/amigable que el marron grisaceo que
/// tenia antes), naranja quemado de acento, y un tostado claro para bordes
/// de botones secundarios.
class AppColors {
  static const fondo = Color(0xFFFAF3E8);
  static const marronOscuro = Color(0xFF422100);
  static const marronPrincipal = Color(0xFF964B00);
  static const naranjaTostado = Color(0xFFB25900);
  static const tostadoClaro = Color(0xFFDE924F); // borde de botones secundarios
  static const crema = Color(0xFFF1E4D0);
  static const verdeVivo = Color(0xFF4F7942); // tilde del conteo en vivo
  static const celesteMacho = Color(0xFF2196F3); // icono de toro/ternero
  static const rosaHembra = Color(
    0xFFE91E63,
  ); // icono de vaca/vaquillona/ternera
  static const bordoAlerta = Color(
    0xFF8B4038,
  ); // cartel de "pasar de a 5" en el conteo
  static const bordoAlertaFondo = Color(
    0xFFF3E3E0,
  ); // fondo clarito del mismo cartel
}

class AppTheme {
  static ThemeData get tema {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.marronPrincipal,
      primary: AppColors.marronPrincipal,
      secondary: AppColors.naranjaTostado,
      surface: AppColors.crema,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.marronPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.crema,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.marronPrincipal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.marronPrincipal,
          side: const BorderSide(color: AppColors.tostadoClaro, width: 1.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.marronOscuro,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: AppColors.marronOscuro),
        bodyMedium: TextStyle(color: AppColors.marronOscuro),
      ),
    );
  }
}
