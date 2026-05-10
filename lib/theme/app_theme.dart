import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color farmerPrimary = Color(0xFF2E7D32);
  static const Color doctorPrimary = Color(0xFF1565C0);
  static const Color secondaryColor = Color(0xFFFF8F00);
  static const Color backgroundColor = Color(0xFFF8FAF8); // Very light greenish-white
  static const Color cardColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: primaryColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 22,   // F3: was 22, keep as spec
        ),
        titleMedium: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 18,   // F3: new
        ),
        titleSmall: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,   // F3: new
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 17,   // F3: was 16
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 15,   // F3: was 14
          color: Colors.black54,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 13,   // F3: was 11-12
          color: Colors.black54,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 13,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black87,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 17,  // F3: was 16
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),
    );
  }
}
