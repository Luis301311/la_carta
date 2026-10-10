import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de La Carta
class AppColors {
  // Un color = una función (así el personal aprende rápido qué significa cada uno)
  static const coral = Color(0xFFF04432); // MARCA: logo, sección activa, detalles
  static const danger = Color(0xFFC62828); // PELIGRO: cancelar, eliminar, errores
  static const amber = Color(0xFFB26A00); // ATENCIÓN: pedidos por confirmar
  static const amberSoft = Color(0xFFFFF4E0);
  static const coralDark = Color(0xFFC8321F); // texto pequeño en coral (más contraste)
  static const cream = Color(0xFFFFF8F2); // crema (acentos suaves)
  static const background = Color(0xFFFAFAFA); // fondo de las pantallas (casi blanco)
  static const carbon = Color(0xFF17212F); // ACCIÓN principal (botones), texto y barra lateral
  static const green = Color(0xFF39765F); // AVANZAR / positivo: avanzar pedido, ventas
  static const gray = Color(0xFFF3F4F6); // fondos suaves
  static const border = Color(0xFFE2E4E8); // bordes de tarjetas (visibles sobre el fondo)

  // Tintes suaves para tarjetas e íconos
  static const coralSoft = Color(0xFFFDE8E4);
  static const orangeSoft = Color(0xFFFFF0E0);
  static const greenSoft = Color(0xFFE6F1EC);
  static const purpleSoft = Color(0xFFF1ECFA);
  static const blueSoft = Color(0xFFE8F0FA);
  static const purple = Color(0xFF6B4BB8);
  static const blue = Color(0xFF2F6DB5);
  static const orange = Color(0xFFE07B10);
}

/// Tema de la app con la paleta (Poppins + coral + crema)
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.carbon,
      primary: AppColors.carbon, // botones, interruptores, foco
      secondary: AppColors.green,
      tertiary: AppColors.coral, // marca
      error: AppColors.danger,
      surface: Colors.white,
    );
    final text = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: AppColors.carbon,
      displayColor: AppColors.carbon,
    );
    final rounded12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.carbon,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.carbon,
        foregroundColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.carbon,
          foregroundColor: Colors.white,
          shape: rounded12,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.carbon,
          shape: rounded12,
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: const Color(0xFFE6E8EC),
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.carbon, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.coralSoft,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
