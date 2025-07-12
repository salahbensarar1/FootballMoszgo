import 'package:cloud_firestore/cloud_firestore.dart';

class TeamCoach {
  final String userId;
  final String role;
  final DateTime assignedAt;
  final String assignedBy;
  final bool isActive;

  TeamCoach({
    required this.userId,
    required this.role,
    required this.assignedAt,
    required this.assignedBy,
    required this.isActive,
  });

  factory TeamCoach.fromJson(Map<String, dynamic> json) {
    return TeamCoach(
      userId: json['userId'] ?? json['user_id'] ?? '',
      role: json['role'] ?? 'coach',
      assignedAt: json['assignedAt'] is Timestamp
          ? (json['assignedAt'] as Timestamp).toDate()
          : json['assigned_at'] is Timestamp
              ? (json['assigned_at'] as Timestamp).toDate()
              : DateTime.tryParse(
                      json['assignedAt'] ?? json['assigned_at'] ?? '') ??
                  DateTime.now(),
      assignedBy: json['assignedBy'] ?? json['assigned_by'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'assignedBy': assignedBy,
      'isActive': isActive,
    };
  }

  // Helper method to get coach name from users collection
  Future<String> getCoachName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()?['name'] ?? 'Unknown Coach';
      }
      return 'Unknown Coach';
    } catch (e) {
      return 'Error Loading Coach';
    }
  }
}

class Team {
  final String id;
  final String teamName;
  final String teamDescription;
  final int numberOfPlayers;
  final List<TeamCoach> coaches;
  final int payment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Team({
    required this.id,
    required this.teamName,
    required this.teamDescription,
    required this.numberOfPlayers,
    required this.coaches,
    this.payment = 0,
    this.createdAt,
    this.updatedAt,
  });

  // BACKWARDS COMPATIBILITY: Get single coach for old queries
  String? get singleCoachId {
    final activeCoaches = coaches.where((c) => c.isActive).toList();
    if (activeCoaches.isNotEmpty) {
      // Prioritize head coach, otherwise return first active coach
      final headCoach =
          activeCoaches.where((c) => c.role == 'head_coach').firstOrNull;
      return headCoach?.userId ?? activeCoaches.first.userId;
    }
    return null;
  }

  // Get active coaches only
  List<TeamCoach> get activeCoaches =>
      coaches.where((coach) => coach.isActive).toList();

  // Get head coach
  TeamCoach? get headCoach {
    try {
      return coaches
          .firstWhere((coach) => coach.role == 'head_coach' && coach.isActive);
    } catch (e) {
      return null;
    }
  }

  // Get all coach user IDs for queries
  List<String> get activeCoachIds =>
      activeCoaches.map((coach) => coach.userId).toList();

  // Check if a user is a coach of this team
  bool isCoach(String userId) {
    return activeCoachIds.contains(userId);
  }

  // Get coach role for specific user
  String? getCoachRole(String userId) {
    try {
      final coach = activeCoaches.firstWhere((c) => c.userId == userId);
      return coach.role;
    } catch (e) {
      return null;
    }
  }

  // CRITICAL: Backwards compatible factory that works with your existing data
  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<TeamCoach> coachesList = [];

    // Handle NEW structure first (coaches array)
    if (data['coaches'] != null && data['coaches'] is List) {
      final coachesData = data['coaches'] as List<dynamic>;
      coachesList = coachesData
          .map((coachData) {
            if (coachData is Map<String, dynamic>) {
              return TeamCoach.fromJson(coachData);
            }
            return null;
          })
          .whereType<TeamCoach>()
          .toList();
    }
    // Handle OLD structure (your current single coach field)
    else if (data['coach'] != null && data['coach'].toString().isNotEmpty) {
      coachesList = [
        TeamCoach(
          userId: data['coach'].toString(),
          role: 'head_coach',
          assignedAt: data['created_at']?.toDate() ?? DateTime.now(),
          assignedBy: 'system_migration',
          isActive: true,
        )
      ];
    }

    return Team(
      id: doc.id,
      teamName: data['team_name'] ?? '',
      teamDescription: data['team_description'] ?? '',
      numberOfPlayers: data['number_of_players'] ?? 0,
      coaches: coachesList,
      payment: data['payment'] ?? 0,
      createdAt: data['created_at']?.toDate(),
      updatedAt: data['updated_at']?.toDate(),
    );
  }

  // Convert back to Firestore format (maintains backwards compatibility)
  Map<String, dynamic> toFirestore() {
    final result = {
      'team_name': teamName,
      'team_description': teamDescription,
      'number_of_players': numberOfPlayers,
      'payment': payment,
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Add new coaches array
    if (coaches.isNotEmpty) {
      result['coaches'] = coaches.map((coach) => coach.toJson()).toList();

      // BACKWARDS COMPATIBILITY: Keep single coach field for existing queries
      result['coach'] = singleCoachId!;
    }

    return result;
  }

  // Helper method to get data as Map (for existing code that expects Map)
  Map<String, dynamic> get asMap {
    return {
      'id': id,
      'team_name': teamName,
      'team_description': teamDescription,
      'number_of_players': numberOfPlayers,
      'coach': singleCoachId, // For backwards compatibility
      'coaches': coaches.map((c) => c.toJson()).toList(),
      'payment': payment,
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Copy with method for easy updates
  Team copyWith({
    String? id,
    String? teamName,
    String? teamDescription,
    int? numberOfPlayers,
    List<TeamCoach>? coaches,
    int? payment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      teamName: teamName ?? this.teamName,
      teamDescription: teamDescription ?? this.teamDescription,
      numberOfPlayers: numberOfPlayers ?? this.numberOfPlayers,
      coaches: coaches ?? this.coaches,
      payment: payment ?? this.payment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Team(id: $id, name: $teamName, coaches: ${coaches.length}, players: $numberOfPlayers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
