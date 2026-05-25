import 'package:flutter/material.dart';

/// Design tokens for the tutor module — extends the base AppColors palette
/// with a module accent system used to colour-code individual modules.
class TColors {
  TColors._();

  // Brand
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primarySubtle = Color(0xFFCCFBF1);
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondarySubtle = Color(0xFFEDE9FE);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Surfaces
  static const Color bg = Color(0xFFF0FDF9);
  static const Color white = Colors.white;
  static const Color muted = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Dark surfaces (chat)
  static const Color dark = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkMuted = Color(0xFF64748B);

  // Module accent colours — assigned by hash of module code
  static const List<Color> accents = [
    Color(0xFF0D9488), // teal
    Color(0xFF6366F1), // indigo
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF8B5CF6), // violet
    Color(0xFF22C55E), // green
    Color(0xFFEC4899), // pink
    Color(0xFF3B82F6), // blue
  ];

  static Color accentFor(String code) {
    final idx = code.codeUnits.fold(0, (a, b) => a + b) % accents.length;
    return accents[idx];
  }
}
