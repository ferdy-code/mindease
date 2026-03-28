import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9D8FF5);
  static const Color primaryDark = Color(0xFF4A3DB8);
  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryLight = Color(0xFF55EFC4);

  // Neutrals
  static const Color background = Color(0xFFF8F7FF);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD63031);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color divider = Color(0xFFDFE6E9);

  // Radius
  static const double cardRadius = 16;
  static const double buttonRadius = 24;
  static const double smallRadius = 8;

  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.poppins(
            fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.poppins(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        displaySmall: GoogleFonts.poppins(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
        bodyLarge: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: BorderSide(color: divider.withValues(alpha: 0.5)),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            textStyle: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.5),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            textStyle: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide:
                BorderSide(color: divider.withValues(alpha: 0.8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: error, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: textHint),
          labelStyle:
              GoogleFonts.poppins(fontSize: 14, color: textSecondary),
          errorStyle: GoogleFonts.poppins(fontSize: 12, color: error),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: background,
          selectedColor: primary.withValues(alpha: 0.1),
          labelStyle: GoogleFonts.poppins(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
            side: const BorderSide(color: divider),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle:
              GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
