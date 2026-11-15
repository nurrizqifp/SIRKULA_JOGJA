import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors representing Yogyakarta circular green economy
  static const Color primaryGreen = Color(0xFF1B5E20);      // Deep Forest Green
  static const Color primaryMedium = Color(0xFF2E7D32);     // Jogja Hijau Daun
  static const Color primaryLight = Color(0xFF81C784);      // Soft Green Accent
  static const Color backgroundLight = Color(0xFFF7FAF7);   // Clean off-white
  static const Color cardSurface = Colors.white;

  // Commodity colors
  static const Color jelantahGold = Color(0xFFE65100);     // Warm Amber for Minyak Jelantah
  static const Color jelantahLight = Color(0xFFFFF3E0);
  static const Color petBlue = Color(0xFF0277BD);          // Clear Blue for Botol PET
  static const Color petLight = Color(0xFFE1F5FE);

  // Status Colors
  static const Color statusPending = Color(0xFFF57C00);
  static const Color statusAssigned = Color(0xFF1976D2);
  static const Color statusInTransit = Color(0xFF7B1FA2);
  static const Color statusWaitingConfirm = Color(0xFF0097A7);
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusDisputed = Color(0xFFD32F2F);
  static const Color statusCancelled = Color(0xFF616161);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: primaryMedium,
        surface: backgroundLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1B381E),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B381E),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryMedium,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryMedium,
          side: const BorderSide(color: primaryMedium, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryMedium, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF546E7A)),
      ),
    );
  }
}
