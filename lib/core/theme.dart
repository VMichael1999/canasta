import 'package:flutter/material.dart';
import 'tokens.dart';
import 'typography.dart';

class CaTheme {
  static ThemeData get light {
    const tokens = CaTokens.light;

    return ThemeData(
      useMaterial3: true,
      fontFamily: CaTypography.fontFamily,
      scaffoldBackgroundColor: tokens.bg,
      colorScheme: ColorScheme.light(
        surface: tokens.bg,
        primary: tokens.blue,
        onPrimary: Colors.white,
        secondary: tokens.navy,
        error: tokens.bad,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFECEEF2),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F1324)),
        titleTextStyle: TextStyle(
          fontFamily: CaTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F1324),
        ),
      ),
      extensions: const [tokens],
    );
  }
}
