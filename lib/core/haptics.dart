import 'package:flutter/services.dart';

class CaHaptics {
  static void selectionClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  static void lightImpact() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void mediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static void heavyImpact() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
