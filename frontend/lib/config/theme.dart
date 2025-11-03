import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color seedPrimary = Color(0xFF22D3EE);
const Color seedSecondary = Color(0xFFF97316);
const Color seedBackground = Color(0xFF0F172A);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedPrimary,
      brightness: Brightness.light,
      primary: seedPrimary,
      secondary: seedSecondary,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontWeight: FontWeight.bold,
      fontSize: 42,
    ),
    titleLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF6FAFF),
    cardTheme: base.cardTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: seedPrimary.withOpacity(0.12),
      labelStyle: const TextStyle(color: seedPrimary),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: seedBackground,
      centerTitle: false,
    ),
    textTheme: textTheme,
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: seedPrimary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
