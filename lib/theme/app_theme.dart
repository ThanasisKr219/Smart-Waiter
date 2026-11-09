import 'package:flutter/material.dart';

abstract final class AppColors {
  static const midnightNavy = Color(0xFF101B2A);
  static const deepSlateNavy = Color(0xFF17263B);
  static const electricCyan = Color(0xFF50D6D1);
  static const frostWhite = Color(0xFFEAF4F5);
  static const steelGrey = Color(0xFF8296A5);
  static const amber = Color(0xFFF59E0B);
  static const emerald = Color(0xFF10B981);
  static const coralRed = Color(0xFFEF4444);

  static const colorScheme = ColorScheme.dark(
    primary: electricCyan,
    onPrimary: midnightNavy,
    secondary: electricCyan,
    onSecondary: midnightNavy,
    surface: deepSlateNavy,
    onSurface: frostWhite,
    error: coralRed,
    onError: frostWhite,
  );
}

abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: AppColors.colorScheme,
      scaffoldBackgroundColor: AppColors.midnightNavy,
      canvasColor: AppColors.midnightNavy,
      cardColor: AppColors.deepSlateNavy,
      dividerColor: AppColors.steelGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepSlateNavy,
        foregroundColor: AppColors.frostWhite,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.deepSlateNavy,
        selectedItemColor: AppColors.electricCyan,
        unselectedItemColor: AppColors.steelGrey,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.deepSlateNavy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.frostWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: AppColors.frostWhite),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.deepSlateNavy,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.steelGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.steelGrey),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.electricCyan, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricCyan,
          foregroundColor: AppColors.midnightNavy,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.electricCyan,
          side: const BorderSide(color: AppColors.steelGrey),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.electricCyan),
      ),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppColors.frostWhite,
            displayColor: AppColors.frostWhite,
          ),
    );
  }
}
