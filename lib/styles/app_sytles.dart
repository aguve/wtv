import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSytles {
  static AppBarTheme appBarTheme = const AppBarTheme(
    centerTitle: true,
  );

  static ThemeData themeData = ThemeData(
      appBarTheme: appBarTheme,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      scaffoldBackgroundColor: platinium,
      primaryColor: platinium);

  static TextStyle baseTextColor = TextStyle(color: platinium);

  static Color blackOlive = const Color(0xff414337);
  static Color platinium = const Color(0xffdadad9);
}
