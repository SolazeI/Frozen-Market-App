import 'package:flutter/material.dart';

/// FrostMart palette: glacier blue brand, ice tints, clean cool-neutral surfaces.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF1F5AB4);
  static const primaryDark = Color(0xFF123D80);
  static const ice = Color(0xFFD3E6FA); // light tint used for chips, headers
  static const frost = Color(0xFFEAF3FC); // very light tint
  static const accent = Color(0xFF29B6F6);

  // Neutrals
  static const background = Color(0xFFF4F8FC);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0F2438);
  static const textSecondary = Color(0xFF5B6B7C);
  static const border = Color(0xFFDCE6F0);

  // Status
  static const success = Color(0xFF1B8E4B);
  static const successBg = Color(0xFFE3F5EB);
  static const warning = Color(0xFFC96A00);
  static const warningBg = Color(0xFFFFF1DD);
  static const error = Color(0xFFD33A3A);
  static const errorBg = Color(0xFFFCE6E6);
  static const star = Color(0xFFFFB400);
}
