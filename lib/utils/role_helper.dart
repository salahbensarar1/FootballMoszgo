// File: lib/utils/role_helper.dart

import 'package:flutter/material.dart';

/// Utility class for role-related operations
/// Contains all role constants, colors, icons, and helper methods
class RoleHelper {
  // Private constructor to prevent instantiation
  const RoleHelper._();

  // Role constants
  static const String adminRole = 'admin';
  static const String coachRole = 'coach';
  static const String receptionistRole = 'receptionist';

  /// Returns the appropriate color for a given role
  /// Used for UI elements like badges, borders, and backgrounds
  static Color getRoleColor(String role) {
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return Colors.red.shade600;
      case coachRole:
        return Colors.blue.shade600;
      case receptionistRole:
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Returns the appropriate icon for a given role
  /// Used in dropdowns, cards, and other UI elements
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return Icons.admin_panel_settings_rounded;
      case coachRole:
        return Icons.sports_rounded;
      case receptionistRole:
        return Icons.desk_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  /// Returns a user-friendly description for a given role
  /// Used in forms, help text, and role explanations
  static String getRoleDescription(String role) {
    switch (role.toLowerCase().trim()) {
      case coachRole:
        return 'Responsible for training sessions and player development';
      case adminRole:
        return 'Full system access and management capabilities';
      case receptionistRole:
        return 'Handles player registration and basic administrative tasks';
      default:
        return 'Standard user role with limited access';
    }
  }

  /// Returns a formatted display name for a given role
  /// Used in UI labels and form fields
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase().trim()) {
      case coachRole:
        return 'Coach';
      case adminRole:
        return 'Administrator';
      case receptionistRole:
        return 'Receptionist';
      default:
        return role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1).toLowerCase()
            : 'Unknown';
    }
  }

  /// Returns all available roles in the system
  /// Used in dropdowns and role selection components
  static List<String> getAllRoles() {
    return [coachRole, adminRole, receptionistRole];
  }

  /// Returns all available roles with their display names
  /// Used for creating dropdown options with proper labels
  static Map<String, String> getAllRolesWithDisplayNames() {
    return {
      coachRole: getRoleDisplayName(coachRole),
      adminRole: getRoleDisplayName(adminRole),
      receptionistRole: getRoleDisplayName(receptionistRole),
    };
  }

  /// Validates if a role is valid
  /// Returns true if the role exists in the system
  static bool isValidRole(String role) {
    return getAllRoles().contains(role.toLowerCase().trim());
  }

  /// Returns the hierarchy level of a role (higher number = more permissions)
  /// Used for permission checks and role comparisons
  static int getRoleHierarchy(String role) {
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return 3; // Highest permissions
      case coachRole:
        return 2; // Medium permissions
      case receptionistRole:
        return 1; // Basic permissions
      default:
        return 0; // No permissions
    }
  }

  /// Checks if role1 has higher or equal permissions than role2
  /// Used for permission validation
  static bool hasPermissionLevel(String userRole, String requiredRole) {
    return getRoleHierarchy(userRole) >= getRoleHierarchy(requiredRole);
  }

  /// Returns a light version of the role color
  /// Used for subtle backgrounds and hover states
  static Color getRoleLightColor(String role) {
    return getRoleColor(role).withOpacity(0.1);
  }

  /// Returns role-specific permissions list
  /// Used for displaying what each role can do
  static List<String> getRolePermissions(String role) {
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return [
          'Manage all users',
          'View all training sessions',
          'Access system settings',
          'Generate reports',
          'Manage teams and players',
          'Handle payments and billing',
        ];
      case coachRole:
        return [
          'Create training sessions',
          'Track player attendance',
          'Manage assigned teams',
          'View player statistics',
          'Update training records',
        ];
      case receptionistRole:
        return [
          'Register new players',
          'Manage player information',
          'Handle basic inquiries',
          'Process payments',
          'Update contact details',
        ];
      default:
        return ['Limited access'];
    }
  }

  /// Returns appropriate greeting message based on role
  /// Used in welcome screens and dashboards
  static String getRoleGreeting(String role, String userName) {
    final displayName = getRoleDisplayName(role);
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return 'Welcome back, $displayName $userName! Ready to manage the system?';
      case coachRole:
        return 'Hello Coach $userName! Time to train some champions?';
      case receptionistRole:
        return 'Good day, $userName! Ready to help our players?';
      default:
        return 'Welcome, $userName!';
    }
  }

  /// Returns role-specific dashboard title
  /// Used in app bars and navigation
  static String getRoleDashboardTitle(String role) {
    switch (role.toLowerCase().trim()) {
      case adminRole:
        return 'Admin Dashboard';
      case coachRole:
        return 'Coach Dashboard';
      case receptionistRole:
        return 'Reception Dashboard';
      default:
        return 'Dashboard';
    }
  }

  /// Returns role badge widget for UI display
  /// Convenient method for creating consistent role badges
  static Widget createRoleBadge(String role, {double? fontSize}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getRoleLightColor(role),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getRoleColor(role).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getRoleIcon(role),
            size: fontSize != null ? fontSize * 1.2 : 14,
            color: getRoleColor(role),
          ),
          SizedBox(width: 4),
          Text(
            getRoleDisplayName(role).toUpperCase(),
            style: TextStyle(
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
              color: getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }
}
