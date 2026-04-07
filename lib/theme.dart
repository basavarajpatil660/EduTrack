import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF000613);
  static const Color primaryContainer = Color(0xFF001F3F);
  static const Color onPrimaryContainer = Color(0xFF6F88AD);
  static const Color primaryFixed = Color(0xFFD4E3FF);
  
  static const Color secondary = Color(0xFF435E91);
  static const Color secondaryContainer = Color(0xFFA9C4FD);
  static const Color onSecondaryContainer = Color(0xFF355082);
  
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.publicSans(fontWeight: FontWeight.w900),
        headlineMedium: GoogleFonts.publicSans(fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        titleSmall: GoogleFonts.publicSans(fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.publicSans(),
        bodyMedium: GoogleFonts.publicSans(),
        bodySmall: GoogleFonts.publicSans(),
        labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.inter(fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      scaffoldBackgroundColor: background,
    );
  }
}
