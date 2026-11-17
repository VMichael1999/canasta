import 'package:flutter/material.dart';

class CaTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 50,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.25, // -4.5%
    color: Colors.white,
    height: 1.1,
  );

  static const TextStyle eta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.14, // -3%
    color: Color(0xFF1A4FE0),
    height: 1.1,
  );

  static const TextStyle price = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.96, // -3%
    color: Color(0xFF0F1324),
    height: 1.15,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.65, // -2.5%
    color: Color(0xFF0F1324),
    height: 1.15,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.44, // -2%
    color: Color(0xFF0F1324),
    height: 1.2,
  );

  static const TextStyle section = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.27, // -1.5%
    color: Color(0xFF0F1324),
    height: 1.2,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFF0F1324),
    height: 1.35,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Color(0xFF0F1324),
    height: 1.35,
  );

  static const TextStyle bodySemi = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F1324),
    height: 1.35,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F1324),
    height: 1.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7186),
    height: 1.25,
  );

  static const TextStyle tab = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6B7186),
    height: 1.1,
  );

  static const TextStyle tabActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A4FE0),
    height: 1.1,
  );
}
