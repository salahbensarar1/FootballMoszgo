import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Utility class for coach role constants and display names
class CoachRoleUtils {
  // COACH ROLE CONSTANTS
  static const String roleHeadCoach = 'head_coach';
  static const String roleAssistantCoach = 'assistant_coach';
  static const String roleTacticsCoach = 'tactics_coach';
  static const String roleFitnessCoach = 'fitness_coach';
  static const String roleGoalkeepingCoach = 'goalkeeping_coach';
  static const String roleYouthCoach = 'youth_coach';

  static List<String> get allCoachRoles => [
        roleHeadCoach,
        roleAssistantCoach,
        roleTacticsCoach,
        roleFitnessCoach,
        roleGoalkeepingCoach,
        roleYouthCoach,
      ];

  static String getCoachRoleDisplayName(String role, [AppLocalizations? l10n]) {
    if (l10n != null) {
      switch (role) {
        case roleHeadCoach:
          return l10n.headCoach;
        case roleAssistantCoach:
          return l10n.assistantCoach;
        case roleTacticsCoach:
          return l10n.tacticsCoach;
        case roleFitnessCoach:
          return l10n.fitnessCoach;
        case roleGoalkeepingCoach:
          return l10n.goalkeepingCoach;
        case roleYouthCoach:
          return l10n.youthCoach;
        default:
          return role
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
              .join(' ');
      }
    } else {
      // Fallback for when localization context is not available
      switch (role) {
        case roleHeadCoach:
          return 'Head Coach';
        case roleAssistantCoach:
          return 'Assistant Coach';
        case roleTacticsCoach:
          return 'Tactics Coach';
        case roleFitnessCoach:
          return 'Fitness Coach';
        case roleGoalkeepingCoach:
          return 'Goalkeeping Coach';
        case roleYouthCoach:
          return 'Youth Coach';
        default:
          return role
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
              .join(' ');
      }
    }
  }
}
