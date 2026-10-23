import 'package:flutter/material.dart';

/// Single source of truth for the MM Store visual language.
abstract final class AppConstants {
  static const brandName = 'MM Store';
  static const currency = 'EGP';

  // Brand palette — derived from the MM Store black / crown-gold identity.
  static const gold = Color(0xFFD8AD4A);
  static const goldBright = Color(0xFFF0C766);
  static const goldSoft = Color(0xFFB8933D);
  static const black = Color(0xFF070707);
  static const blackSoft = Color(0xFF0D0D0D);
  static const surface = Color(0xFF121212);
  static const surfaceElevated = Color(0xFF171717);
  static const surfaceGlass = Color(0xCC121212);
  static const page = Color(0xFF090909);
  static const textPrimary = Color(0xFFF5F1E8);
  static const textSecondary = Color(0xFFA9A39A);
  static const muted = Color(0xFF8C877F);
  static const border = Color(0xFF2B271F);
  static const danger = Color(0xFFE75C5C);
  static const success = Color(0xFF6FCF97);

  static const horizontalPadding = 18.0;
  static const sectionGap = 30.0;
  static const cardRadius = 24.0;
  static const imageRadius = 18.0;

  static const shadow = BoxShadow(
    color: Color(0x66000000),
    blurRadius: 26,
    offset: Offset(0, 14),
  );

  static const goldGlow = BoxShadow(
    color: Color(0x44D8AD4A),
    blurRadius: 28,
    spreadRadius: -4,
    offset: Offset(0, 10),
  );
}
