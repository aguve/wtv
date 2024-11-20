import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSytles {
  static AppBarTheme appBarTheme =
      AppBarTheme(centerTitle: true, backgroundColor: prussianBlue);

  static ThemeData themeData = ThemeData(
      appBarTheme: appBarTheme,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimaryColor), // Text normal
        bodyMedium: TextStyle(color: textPrimaryColor), // Text secundari
        displayLarge: TextStyle(
            color: textPrimaryColor,
            fontSize: 32,
            fontWeight: FontWeight.bold), // Titular gran
        displayMedium:
            TextStyle(color: textPrimaryColor, fontSize: 24), // Titular mitjà
      ).apply(
        bodyColor: textPrimaryColor,
        displayColor: textPrimaryColor,
      ),
      fontFamily: GoogleFonts.montserrat().fontFamily,
      scaffoldBackgroundColor: prussianBlue,
      primaryColor: prussianBlue);

  static Color textPrimaryColor = platinium;

  static Color sapphire = const Color(0xff0353a4);
  static Color platinium = const Color(0xffdadad9);
  static Color prussianBlue = const Color(0xff003559);
  static Color oxfordBlue = const Color(0xff061a40);
  static Color columbiaBlue = const Color(0xffb9d6f2);
}
