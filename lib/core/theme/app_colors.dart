import 'package:flutter/material.dart';

/// Colour tokens taken from the Figma prototype.
///
/// Widgets should read colours from here (or from the theme) instead of
/// hard-coding hex values, so a design change only touches this file.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF17736B);
  static const onPrimary = Colors.white;
  static const primaryContainer = Color(0xFFDDEFEC);
  static const onPrimaryContainer = Color(0xFF0E4A45);

  // Surfaces
  static const background = Color(0xFFF4F5F4);
  static const surface = Colors.white;
  static const border = Color(0xFFE3E6E5);

  // Text
  static const textPrimary = Color(0xFF1A1C1C);
  static const textSecondary = Color(0xFF5F6665);

  // Status chips ("19 days", "In date", "Low stock", "Expired batch", ...)
  static const warning = Color(0xFF8A5A00);
  static const warningContainer = Color(0xFFFFF1CC);
  static const success = Color(0xFF1E6B3F);
  static const successContainer = Color(0xFFE2F3E8);
  static const danger = Color(0xFFB3261E);
  static const dangerContainer = Color(0xFFFCE8E6);
  static const info = Color(0xFF2F5A9E);
  static const infoContainer = Color(0xFFE3ECFA);
}
