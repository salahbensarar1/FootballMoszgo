import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Team Assignment Model
class TeamAssignment {
  final String teamId;
  final String teamName;
  final String role;
  final DateTime assignedAt;
  final String assignedBy;
  final bool isActive;

  TeamAssignment({
    required this.teamId,
    required this.teamName,
    required this.role,
    required this.assignedAt,
    required this.assignedBy,
    this.isActive = true,
  });

  factory TeamAssignment.fromFirestore(Map<String, dynamic> data) {
    return TeamAssignment(
      teamId: data['team_id'] ?? '',
      teamName: data['team_name'] ?? '',
      role: data['role'] ?? 'coach',
      assignedAt: _parseTimestamp(data['assigned_at']),
      assignedBy: data['assigned_by'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'team_id': teamId,
      'team_name': teamName,
      'role': role,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'assigned_by': assignedBy,
      'is_active': isActive,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.tryParse(timestamp) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Enhanced Coach Assignment Model
class CoachAssignment {
  final String coachId;
  final String coachName;
  final String role;
  final DateTime assignedAt;
  final String assignedBy;
  final bool isActive;

  CoachAssignment({
    required this.coachId,
    required this.coachName,
    required this.role,
    required this.assignedAt,
    required this.assignedBy,
    this.isActive = true,
  });

  factory CoachAssignment.fromFirestore(Map<String, dynamic> data) {
    return CoachAssignment(
      coachId: data['coach_id'] ?? data['userId'] ?? '',
      coachName: data['coach_name'] ?? '',
      role: data['role'] ?? 'coach',
      assignedAt: TeamAssignment._parseTimestamp(data['assigned_at']),
      assignedBy: data['assigned_by'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'coach_name': coachName,
      'role': role,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'assigned_by': assignedBy,
      'is_active': isActive,
    };
  }
}

/// Training Session Model
class TrainingSession {
  final String id;
  final String teamId;
  final String teamName;
  final String coachId;
  final String coachName;
  final DateTime startTime;
  final DateTime endTime;
  final String pitchLocation;
  final String notes;
  final List<PlayerAttendance> players;
  final DateTime createdAt;

  TrainingSession({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.coachId,
    required this.coachName,
    required this.startTime,
    required this.endTime,
    required this.pitchLocation,
    this.notes = '',
    required this.players,
    required this.createdAt,
  });

  factory TrainingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrainingSession(
      id: doc.id,
      teamId: data['team_id'] ?? '',
      teamName: data['team_name'] ?? '',
      coachId: data['coach_uid'] ?? '',
      coachName: data['coach_name'] ?? '',
      startTime: TeamAssignment._parseTimestamp(data['start_time']),
      endTime: TeamAssignment._parseTimestamp(data['end_time']),
      pitchLocation: data['pitch_location'] ?? '',
      notes: data['note'] ?? '',
      players: (data['players'] as List<dynamic>? ?? [])
          .map((p) => PlayerAttendance.fromFirestore(p))
          .toList(),
      createdAt: TeamAssignment._parseTimestamp(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'team_id': teamId,
      'team_name': teamName,
      'coach_uid': coachId,
      'coach_name': coachName,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'pitch_location': pitchLocation,
      'note': notes,
      'players': players.map((p) => p.toFirestore()).toList(),
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

/// Player Attendance Model
class PlayerAttendance {
  final String playerId;
  final String playerName;
  final bool present;
  final int minutes;
  final String notes;

  PlayerAttendance({
    required this.playerId,
    required this.playerName,
    this.present = false,
    this.minutes = 0,
    this.notes = '',
  });

  factory PlayerAttendance.fromFirestore(Map<String, dynamic> data) {
    return PlayerAttendance(
      playerId: data['player_id'] ?? '',
      playerName: data['name'] ?? '',
      present: data['present'] ?? false,
      minutes: data['minutes'] ?? 0,
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'player_id': playerId,
      'name': playerName,
      'present': present,
      'minutes': minutes,
      'notes': notes,
    };
  }

  PlayerAttendance copyWith({
    String? playerId,
    String? playerName,
    bool? present,
    int? minutes,
    String? notes,
  }) {
    return PlayerAttendance(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      present: present ?? this.present,
      minutes: minutes ?? this.minutes,
      notes: notes ?? this.notes,
    );
  }
}

/// Coach Dashboard Data Model
class CoachDashboardData {
  final String coachId;
  final List<TeamAssignment> assignedTeams;
  final TeamAssignment? selectedTeam;
  final List<PlayerAttendance> teamPlayers;
  final List<TrainingSession> recentSessions;

  CoachDashboardData({
    required this.coachId,
    required this.assignedTeams,
    this.selectedTeam,
    required this.teamPlayers,
    required this.recentSessions,
  });

  CoachDashboardData copyWith({
    String? coachId,
    List<TeamAssignment>? assignedTeams,
    TeamAssignment? selectedTeam,
    List<PlayerAttendance>? teamPlayers,
    List<TrainingSession>? recentSessions,
  }) {
    return CoachDashboardData(
      coachId: coachId ?? this.coachId,
      assignedTeams: assignedTeams ?? this.assignedTeams,
      selectedTeam: selectedTeam ?? this.selectedTeam,
      teamPlayers: teamPlayers ?? this.teamPlayers,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  bool get hasTeams => assignedTeams.isNotEmpty;
  bool get hasSelectedTeam => selectedTeam != null;
  bool get hasPlayers => teamPlayers.isNotEmpty;
}