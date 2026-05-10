import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGradientStart = Color(0xFFF27121);
  static const Color primaryGradientEnd = Colors.white;
  static const Color primaryOrange = Color(0xFFF27121);
  static const Color lightGrey = Color(0xFFEEEEEE);
}

class AppConstants {
  static const String appName = 'Football Training';
  static const int trainingDurationHours = 2;
  static const int maxPlayersPerTeam = 30;

  // Payment related
  static const int monthsToDisplay = 12;
  static const int futureMonthsAllowed = 2;
}

class AppTextStyles {
  static const TextStyle cardTitle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

  static const TextStyle cardSubtitle =
      TextStyle(color: Colors.grey, fontSize: 13);

  static const TextStyle headerText =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
}

/// Firestore query limits used across the app to prevent memory exhaustion
/// with large datasets.  Increase if an organisation legitimately exceeds these
/// numbers, or implement cursor-based pagination for unbounded growth.
class FirestoreLimits {
  /// Maximum number of coaches loaded in a single stream listener.
  static const int maxCoaches = 200;

  /// Maximum number of players loaded in a single stream listener.
  static const int maxPlayers = 500;

  /// Maximum number of teams loaded in a single stream listener.
  static const int maxTeams = 100;
}
