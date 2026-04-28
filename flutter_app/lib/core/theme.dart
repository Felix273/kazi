import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KaziTheme {
  static const Color primary = Color(0xFF2D6A6A);
  static const Color primaryLight = Color(0xFF3D8A8A);
  static const Color primaryDark = Color(0xFF1E4A4A);
  static const Color accent = Color(0xFFE8763A);
  static const Color accentLight = Color(0xFFF0946A);
  static const Color background = Color(0xFFF5F0EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFAF7F3);
  static const Color surfaceTeal = Color(0xFFE8F4F4);
  static const Color textPrimary = Color(0xFF1A2E2E);
  static const Color textSecondary = Color(0xFF5A7070);
  static const Color textHint = Color(0xFFA0B4B4);
  static const Color border = Color(0xFFE8E0D8);
  static const Color borderLight = Color(0xFFF0EBE5);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color catManual = Color(0xFFE8763A);
  static const Color catPro = Color(0xFF2D6A6A);
  static const Color catErrands = Color(0xFF7C5CBF);
  static const Color catDigital = Color(0xFF2196F3);
  static const Color surfaceVariant = surfaceWarm;
  static const Color statusOpen = info;
  static const Color accent2 = accentLight;

  static ThemeData get lightTheme {
    final base = GoogleFonts.dmSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      textTheme: base,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        background: background,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(double.infinity, 54),
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.dmSans(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceWarm,
        selectedColor: primary.withOpacity(0.12),
        labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1, space: 1),
    );
  }
}

class KaziText {
  static TextStyle get h1 => GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800, color: KaziTheme.textPrimary, height: 1.15);
  static TextStyle get h2 => GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: KaziTheme.textPrimary, height: 1.2);
  static TextStyle get h3 => GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700, color: KaziTheme.textPrimary);
  static TextStyle get body => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: KaziTheme.textPrimary, height: 1.5);
  static TextStyle get bodyMedium => GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: KaziTheme.textPrimary);
  static TextStyle get caption => GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: KaziTheme.textSecondary);
  static TextStyle get label => GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: KaziTheme.textSecondary, letterSpacing: 0.5);
  static TextStyle get price => GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: KaziTheme.primary, letterSpacing: -0.3);
}

class KaziSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// Backwards compatibility aliases
extension KaziThemeAliases on KaziTheme {
  static const Color surfaceVariant = KaziTheme.surfaceWarm;
  static const Color statusOpen = KaziTheme.info;
}
