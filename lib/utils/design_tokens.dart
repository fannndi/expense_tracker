import 'package:flutter/material.dart';

/// Design tokens for the warm-minimal UI.
class DesignTokens {
  DesignTokens._();

  // Spacing (8px grid)
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double sectionGap = 128;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  // Typography scale (mobile)
  static const double textXs = 12;
  static const double textSm = 14;
  static const double textMd = 16;
  static const double textLg = 18;
  static const double textXl = 22;
  static const double text2Xl = 28;
  static const double text3Xl = 36;

  // Warm palette (light)
  static const Color warmGround = Color(0xFFF7F2EA);
  static const Color warmSurface = Color(0xFFFFFBF5);
  static const Color warmInk = Color(0xFF2B241D);
  static const Color warmMuted = Color(0xFF6F6255);
  static const Color warmAccent = Color(0xFFB8623A);
  static const Color warmAccentSoft = Color(0xFFF0D9CC);

  // Warm palette (dark)
  static const Color warmGroundDark = Color(0xFF1F1A16);
  static const Color warmSurfaceDark = Color(0xFF2A231E);
  static const Color warmInkDark = Color(0xFFF2ECE3);
  static const Color warmMutedDark = Color(0xFFB9AA99);
  static const Color warmAccentDark = Color(0xFFD9825C);
  static const Color warmAccentSoftDark = Color(0xFF3A2A22);
}
