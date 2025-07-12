import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? roleDescription;
  final String? picture;
  final String? team; // For backwards compatibility with existing structure
  final List<String> assignedTeams; // For coaches with multiple teams
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleDescription,
    this.picture,
    this.team,
    this.assignedTeams = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // Check if user is a coach
  bool get isCoach => role.toLowerCase() == 'coach';

  // Check if user is admin
  bool get isAdmin => role.toLowerCase() == 'admin';

  // Check if user is receptionist
  bool get isReceptionist => role.toLowerCase() == 'receptionist';

  // Get display role name
  String get displayRole {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'coach':
        return 'Coach';
      case 'receptionist':
        return 'Receptionist';
      default:
        return role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1).toLowerCase()
            : 'Unknown';
    }
  }

  // Get all teams this user is associated with
  List<String> get allTeams {
    final teams = <String>[];

    // Add single team (backwards compatibility)
    if (team != null && team!.isNotEmpty) {
      teams.add(team!);
    }

    // Add assigned teams
    teams.addAll(assignedTeams);

    // Remove duplicates and return
    return teams.toSet().toList();
  }

  // Check if user is assigned to a specific team
  bool isAssignedToTeam(String teamName) {
    return allTeams.contains(teamName);
  }

  // BACKWARDS COMPATIBLE: Factory that works with your existing user data
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle assigned teams (new structure)
    List<String> assignedTeamsList = [];
    if (data['assigned_teams'] != null) {
      if (data['assigned_teams'] is List) {
        assignedTeamsList = List<String>.from(data['assigned_teams']);
      }
    }

    return User(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      roleDescription: data['role_description'],
      picture: data['picture'],
      team: data['team'], // Keep backwards compatibility
      assignedTeams: assignedTeamsList,
      isActive: data['is_active'] ?? data['isActive'] ?? true,
      createdAt: data['created_at']?.toDate(),
      updatedAt: data['updated_at']?.toDate(),
    );
  }

  // Factory for creating from Map (for existing code)
  factory User.fromMap(Map<String, dynamic> data, String id) {
    List<String> assignedTeamsList = [];
    if (data['assigned_teams'] != null) {
      if (data['assigned_teams'] is List) {
        assignedTeamsList = List<String>.from(data['assigned_teams']);
      }
    }

    return User(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      roleDescription: data['role_description'],
      picture: data['picture'],
      team: data['team'],
      assignedTeams: assignedTeamsList,
      isActive: data['is_active'] ?? data['isActive'] ?? true,
      createdAt: data['created_at']?.toDate(),
      updatedAt: data['updated_at']?.toDate(),
    );
  }

  // Convert to Firestore format (maintains backwards compatibility)
  Map<String, dynamic> toFirestore() {
    final result = {
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Add optional fields only if they exist
    if (roleDescription != null) {
      result['role_description'] = roleDescription!;
    }

    if (picture != null && picture!.isNotEmpty) {
      result['picture'] = picture!;
    }

    // BACKWARDS COMPATIBILITY: Keep single team field
    if (team != null && team!.isNotEmpty) {
      result['team'] = team!;
    }

    // Add assigned teams for multi-team support
    if (assignedTeams.isNotEmpty) {
      result['assigned_teams'] = assignedTeams;
    }

    return result;
  }

  // Helper method to get data as Map (for existing code that expects Map)
  Map<String, dynamic> get asMap {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'role_description': roleDescription,
      'picture': picture,
      'team': team, // For backwards compatibility
      'assigned_teams': assignedTeams,
      'is_active': isActive,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with method for easy updates
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? roleDescription,
    String? picture,
    String? team,
    List<String>? assignedTeams,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      roleDescription: roleDescription ?? this.roleDescription,
      picture: picture ?? this.picture,
      team: team ?? this.team,
      assignedTeams: assignedTeams ?? this.assignedTeams,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Add team to assigned teams
  User addTeam(String teamName) {
    if (!assignedTeams.contains(teamName)) {
      return copyWith(assignedTeams: [...assignedTeams, teamName]);
    }
    return this;
  }

  // Remove team from assigned teams
  User removeTeam(String teamName) {
    return copyWith(
        assignedTeams: assignedTeams.where((t) => t != teamName).toList());
  }

  // Get user's role-specific permissions
  List<String> get permissions {
    switch (role.toLowerCase()) {
      case 'admin':
        return [
          'manage_users',
          'manage_teams',
          'manage_players',
          'view_all_sessions',
          'generate_reports',
          'system_settings',
          'manage_payments',
        ];
      case 'coach':
        return [
          'create_sessions',
          'manage_assigned_teams',
          'track_attendance',
          'view_player_stats',
          'update_training_records',
        ];
      case 'receptionist':
        return [
          'register_players',
          'manage_player_info',
          'handle_payments',
          'view_basic_reports',
          'manage_contacts',
        ];
      default:
        return ['view_basic_info'];
    }
  }

  // Check if user has specific permission
  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  // Get user avatar/profile image
  String get avatarUrl {
    if (picture != null && picture!.isNotEmpty) {
      return picture!;
    }
    // Return default avatar based on role
    return 'assets/images/default_profile.jpeg';
  }

  // Get user initials for avatar fallback
  String get initials {
    if (name.isEmpty) return 'U';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  // Validate user data
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        role.isNotEmpty;
  }

  // Get user status text
  String get statusText {
    if (!isActive) return 'Inactive';
    if (!isValid) return 'Invalid Data';
    return 'Active';
  }

  // Get role color for UI
  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFDC2626); // Red
      case 'coach':
        return const Color(0xFF2563EB); // Blue
      case 'receptionist':
        return const Color(0xFF16A34A); // Green
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  // Get role icon for UI
  IconData get roleIcon {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'coach':
        return Icons.sports_rounded;
      case 'receptionist':
        return Icons.desk_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, role: $role, teams: ${allTeams.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
