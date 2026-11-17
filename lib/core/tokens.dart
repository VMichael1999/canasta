import 'package:flutter/material.dart';

@immutable
class CaTokens extends ThemeExtension<CaTokens> {
  const CaTokens({
    required this.bg,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.border,
    required this.chip,
    required this.soft,
    required this.blue,
    required this.blueDeep,
    required this.blueSoft,
    required this.navy,
    required this.green,
    required this.greenSoft,
    required this.bad,
    required this.badSoft,
    required this.sun,
    required this.toast,
  });

  final Color bg;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color border;
  final Color chip;
  final Color soft;
  final Color blue;
  final Color blueDeep;
  final Color blueSoft;
  final Color navy;
  final Color green;
  final Color greenSoft;
  final Color bad;
  final Color badSoft;
  final Color sun;
  final Color toast;

  static const CaTokens light = CaTokens(
    bg: Color(0xFFFFFFFF),
    ink: Color(0xFF0F1324),
    ink2: Color(0xFF6B7186),
    ink3: Color(0xFFA4A9B8),
    line: Color(0xFFECEEF2),
    border: Color(0xFFE6E9F0),
    chip: Color(0xFFF3F5F9),
    soft: Color(0xFFF6F8FC),
    blue: Color(0xFF1A4FE0),
    blueDeep: Color(0xFF123BB0),
    blueSoft: Color(0xFFEBF0FE),
    navy: Color(0xFF0B2A73),
    green: Color(0xFF1E9E5A),
    greenSoft: Color(0xFFE3F6EC),
    bad: Color(0xFFE0412F),
    badSoft: Color(0xFFFDECEA),
    sun: Color(0xFFF5A524),
    toast: Color(0xFF121A33),
  );

  // Spacing & Radii
  static const double pad = 22.0;
  static const double cardRadius = 16.0;
  static const double catRadius = 18.0;
  static const double bannerRadius = 20.0;
  static const double btnRadius = 14.0;
  static const double payBtnRadius = 18.0;
  static const double fieldRadius = 13.0;
  static const double chipRadius = 19.0;
  static const double sheetRadius = 28.0;
  static const double glassSheetRadius = 34.0;

  @override
  CaTokens copyWith({
    Color? bg,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? border,
    Color? chip,
    Color? soft,
    Color? blue,
    Color? blueDeep,
    Color? blueSoft,
    Color? navy,
    Color? green,
    Color? greenSoft,
    Color? bad,
    Color? badSoft,
    Color? sun,
    Color? toast,
  }) {
    return CaTokens(
      bg: bg ?? this.bg,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      line: line ?? this.line,
      border: border ?? this.border,
      chip: chip ?? this.chip,
      soft: soft ?? this.soft,
      blue: blue ?? this.blue,
      blueDeep: blueDeep ?? this.blueDeep,
      blueSoft: blueSoft ?? this.blueSoft,
      navy: navy ?? this.navy,
      green: green ?? this.green,
      greenSoft: greenSoft ?? this.greenSoft,
      bad: bad ?? this.bad,
      badSoft: badSoft ?? this.badSoft,
      sun: sun ?? this.sun,
      toast: toast ?? this.toast,
    );
  }

  @override
  CaTokens lerp(ThemeExtension<CaTokens>? other, double t) {
    if (other is! CaTokens) return this;
    return CaTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      line: Color.lerp(line, other.line, t)!,
      border: Color.lerp(border, other.border, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueDeep: Color.lerp(blueDeep, other.blueDeep, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      green: Color.lerp(green, other.green, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      badSoft: Color.lerp(badSoft, other.badSoft, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      toast: Color.lerp(toast, other.toast, t)!,
    );
  }
}

extension CaTokensBuildContext on BuildContext {
  CaTokens get tokens => Theme.of(this).extension<CaTokens>() ?? CaTokens.light;
}
