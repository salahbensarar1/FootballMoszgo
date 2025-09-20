import 'package:flutter/material.dart';

/// Constants for the receptionist screen components
class ReceptionistConstants {
  // App Bar Gradient
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Other gradients
  static const LinearGradient drawerHeaderGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border radius values
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double dialogBorderRadius = 20.0;

  // Animation durations
  static const Duration mainAnimationDuration = Duration(milliseconds: 1200);
  static const Duration fabAnimationDuration = Duration(milliseconds: 300);

  // Colors
  static const Color primaryBlue = Color(0xFF667eea);
  static const Color primaryPurple = Color(0xFF764ba2);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);

  // Shadows
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
