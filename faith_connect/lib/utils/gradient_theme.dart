import 'package:flutter/material.dart';

/// Global spiritual gradient system for FaithConnect
/// 
/// Provides consistent gradients, colors, and styling across the app
/// following the premium spiritual design system.
class GradientTheme {
  GradientTheme._();

  // Primary Gradient - Soft Premium Purple/Violet (Softer, more elegant)
  static const primaryGradient = LinearGradient(
    colors: [
      Color(0xFF9D8BF5), // Soft Lavender
      Color(0xFF8B7CF0), // Medium Lavender
      Color(0xFF7B6FE8), // Rich Violet
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Gradient - Even softer for cards/sections
  static const secondaryGradient = LinearGradient(
    colors: [
      Color(0xFFB5A9F8), // Very Soft Lavender
      Color(0xFF9D8BF5), // Soft Lavender
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background Colors
  static const softBackground = Color(0xFFF7F8FC); // Soft off-white
  static const cardBackground = Color(0xFFFFFFFF);

  // Accent Colors
  static const goldAccent = Color(0xFFFFD700); // Soft gold for verified badges
  static const goldAccentLight = Color(0xFFFFF8DC); // Light gold for backgrounds

  // Pastel Icon Backgrounds
  static const pastelPink = Color(0xFFFFE5F1);
  static const pastelMint = Color(0xFFE0F7F4);
  static const pastelSkyBlue = Color(0xFFE3F2FD);
  static const pastelYellow = Color(0xFFFFF9E6);

  // Text Colors
  static const textDark = Color(0xFF111827);
  static const textMedium = Color(0xFF6B7280);
  static const textLight = Color(0xFF9CA3AF);

  // Card Styling
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    double borderRadius = 18,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Icon Container Decoration
  static BoxDecoration iconContainerDecoration({
    required Color accentColor,
    double borderRadius = 14,
  }) {
    return BoxDecoration(
      color: accentColor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // Button Gradient
  static const buttonGradient = LinearGradient(
    colors: [
      Color(0xFF8E7CF0),
      Color(0xFF6A5AE0),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
