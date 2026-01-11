/// Modern color palette for Prism app
/// Clean blue/teal professional design
library;

import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors - Modern Blue/Teal Gradient
  static const Color primaryBlue = Color(0xFF2563EB); // Bright Blue
  static const Color primaryTeal = Color(0xFF0891B2); // Cyan/Teal
  static const Color accentIndigo = Color(0xFF4F46E5); // Deep Indigo
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryTeal],
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  );
  
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
  );
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72);
  static const Color lightBorder = Color(0xFFDFE6E9);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF262626);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB2B2B2);
  static const Color darkBorder = Color(0xFF3A3A3A);
  
  // Semantic Colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFFF7675);
  static const Color info = Color(0xFF74B9FF);
  
  // Social Media Inspired Colors
  static const Color likeRed = Color(0xFFED4956);
  static const Color commentBlue = Color(0xFF0095F6);
  static const Color shareGreen = Color(0xFF00BA7C);
  static const Color bookmarkYellow = Color(0xFFFFC107);
  
  // Glassmorphism Colors
  static Color glassLight = const Color.fromRGBO(255, 255, 255, 0.1);
  static Color glassDark = const Color.fromRGBO(0, 0, 0, 0.2);
  
  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
