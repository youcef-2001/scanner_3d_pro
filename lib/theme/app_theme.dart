import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF4318D1);
  static const Color primaryLightColor = Color(0xFF8B5CF6);
  static const Color primaryDarkColor = Color(0xFF3B1BA8);
  static const Color backgroundColor = Color(0xFF111111);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFF4F2BC4);

  // Text Styles
  static TextStyle headingStyle(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 18, // Adjusted for mobile
      fontWeight: FontWeight.w500,
      letterSpacing: 0.05 * 17,
      color: Colors.white,
      shadows: [
        Shadow(
          color: primaryColor.withOpacity(0.4),
          blurRadius: 8, // Reduced blur for smaller screens
        ),
      ],
    );
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 12, // Adjusted for mobile
      letterSpacing: 0.025 * 10,
      color: primaryLightColor,
    );
  }

  // Theme Data
  static ThemeData themeData() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
    );
  }
}
