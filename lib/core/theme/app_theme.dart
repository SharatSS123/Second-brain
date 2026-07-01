import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6750A4);
  static const _seedColor = Color(0xFF6750A4);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
