import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/models/user_model.dart' as UserModel;

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID for audit trail
  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  // COACH MANAGEMENT METHODS

  /// Add a coach to a team with specified role
  Future<void> addCoachToTeam({
    required String teamId,
    required String coachUserId,
    required String role,
  }) async {
    try {
      // Get current team data
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final team = Team.fromFirestore(teamDoc);

      // Check if coach is already assigned and active
      if (team.activeCoachIds.contains(coachUserId)) {
        throw Exception('Coach is already assigned to this team');
      }

      // Create new coach entry
      final newCoach = TeamCoach(
        userId: coachUserId,
        role: role,
        assignedAt: DateTime.now(),
        assignedBy: _currentUserId,
        isActive: true,
      );

      // Update team with new coach
      final updatedCoaches = [...team.coaches, newCoach];

      await teamDoc.reference.update({
        'coaches': updatedCoaches.map((c) => c.toJson()).toList(),
        'coach': updatedCoaches
            .firstWhere((c) => c.isActive)
            .userId, // Keep backwards compatibility
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Coach added successfully: $coachUserId to team $teamId');
    } catch (e) {
      print('❌ Error adding coach: $e');
      rethrow;
    }
  }

  /// Remove a coach from a team (set inactive for audit trail)
  Future<void> removeCoachFromTeam(String teamId, String coachUserId) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final team = Team.fromFirestore(teamDoc);

      // Check if coach is assigned
      if (!team.activeCoachIds.contains(coachUserId)) {
        throw Exception('Coach is not assigned to this team');
      }

      // Update coaches list - set specific coach to inactive
      final updatedCoaches = team.coaches.map((coach) {
        if (coach.userId == coachUserId && coach.isActive) {
          return TeamCoach(
            userId: coach.userId,
            role: coach.role,
            assignedAt: coach.assignedAt,
            assignedBy: coach.assignedBy,
            isActive: false, // Set to inactive
          );
        }
        return coach;
      }).toList();

      // Find new primary coach for backwards compatibility
      final activeCoaches = updatedCoaches.where((c) => c.isActive).toList();
      final primaryCoachId =
          activeCoaches.isNotEmpty ? activeCoaches.first.userId : null;

      await teamDoc.reference.update({
        'coaches': updatedCoaches.map((c) => c.toJson()).toList(),
        'coach': primaryCoachId, // Update single coach field
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Coach removed successfully: $coachUserId from team $teamId');
    } catch (e) {
      print('❌ Error removing coach: $e');
      rethrow;
    }
  }

  /// Update coach role in a team
  Future<void> updateCoachRole(
      String teamId, String coachUserId, String newRole) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final team = Team.fromFirestore(teamDoc);

      // Update specific coach's role
      final updatedCoaches = team.coaches.map((coach) {
        if (coach.userId == coachUserId && coach.isActive) {
          return TeamCoach(
            userId: coach.userId,
            role: newRole,
            assignedAt: coach.assignedAt,
            assignedBy: coach.assignedBy,
            isActive: coach.isActive,
          );
        }
        return coach;
      }).toList();

      await teamDoc.reference.update({
        'coaches': updatedCoaches.map((c) => c.toJson()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Coach role updated: $coachUserId -> $newRole');
    } catch (e) {
      print('❌ Error updating coach role: $e');
      rethrow;
    }
  }

  // TEAM QUERY METHODS

  /// Get teams where user is an active coach (NEW APPROACH)
  Stream<List<Team>> getTeamsForCoach(String coachUserId) {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Team.fromFirestore(doc))
          .where((team) => team.activeCoachIds.contains(coachUserId))
          .toList();
    });
  }

  /// Get teams where user is an active coach (BACKWARDS COMPATIBLE)
  Stream<QuerySnapshot> getTeamsForCoachCompatible(String coachUserId) {
    // This returns QuerySnapshot for compatibility with existing code
    return _firestore
        .collection('teams')
        .where('coach', isEqualTo: coachUserId)
        .snapshots();
  }

  /// Get all teams as models
  Stream<List<Team>> getAllTeams() {
    return _firestore.collection('teams').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList());
  }

  /// Get single team by ID
  Future<Team?> getTeamById(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return Team.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting team: $e');
      return null;
    }
  }

  // COACH QUERY METHODS

  /// Get all available coaches for assignment
  Future<List<UserModel.User>> getAvailableCoaches() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.User.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting available coaches: $e');
      return [];
    }
  }

  /// Get coaches not assigned to a specific team
  Future<List<UserModel.User>> getUnassignedCoaches(String teamId) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) return [];

      final allCoaches = await getAvailableCoaches();
      final assignedCoachIds = team.activeCoachIds;

      return allCoaches
          .where((coach) => !assignedCoachIds.contains(coach.id))
          .toList();
    } catch (e) {
      print('❌ Error getting unassigned coaches: $e');
      return [];
    }
  }

  /// Get coach details for a team
  Future<List<Map<String, dynamic>>> getTeamCoachDetails(String teamId) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) return [];

      final coachDetails = <Map<String, dynamic>>[];

      for (final teamCoach in team.activeCoaches) {
        try {
          final coachDoc =
              await _firestore.collection('users').doc(teamCoach.userId).get();
          if (coachDoc.exists) {
            final coach = UserModel.User.fromFirestore(coachDoc);
            coachDetails.add({
              'teamCoach': teamCoach,
              'user': coach,
              'name': coach.name,
              'email': coach.email,
              'role': teamCoach.role,
              'assignedAt': teamCoach.assignedAt,
              'assignedBy': teamCoach.assignedBy,
            });
          }
        } catch (e) {
          print('⚠️ Error getting coach details for ${teamCoach.userId}: $e');
        }
      }

      return coachDetails;
    } catch (e) {
      print('❌ Error getting team coach details: $e');
      return [];
    }
  }

  // TEAM MANAGEMENT METHODS

  /// Create a new team
  Future<String> createTeam({
    required String teamName,
    required String teamDescription,
    String? initialCoachId,
    int payment = 0,
  }) async {
    try {
      final teamData = {
        'team_name': teamName,
        'team_description': teamDescription,
        'number_of_players': 0,
        'payment': payment,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add initial coach if provided
      if (initialCoachId != null && initialCoachId.isNotEmpty) {
        final initialCoach = TeamCoach(
          userId: initialCoachId,
          role: 'head_coach',
          assignedAt: DateTime.now(),
          assignedBy: _currentUserId,
          isActive: true,
        );

        teamData['coaches'] = [initialCoach.toJson()];
        teamData['coach'] = initialCoachId; // Backwards compatibility
      }

      final docRef = await _firestore.collection('teams').add(teamData);
      print('✅ Team created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating team: $e');
      rethrow;
    }
  }

  /// Update team information
  Future<void> updateTeam(Team team) async {
    try {
      await _firestore
          .collection('teams')
          .doc(team.id)
          .update(team.toFirestore());

      print('✅ Team updated successfully: ${team.id}');
    } catch (e) {
      print('❌ Error updating team: $e');
      rethrow;
    }
  }

  /// Delete a team (soft delete - set inactive)
  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print('✅ Team deleted successfully: $teamId');
    } catch (e) {
      print('❌ Error deleting team: $e');
      rethrow;
    }
  }

  // MIGRATION AND UTILITY METHODS

  /// Migrate teams from single coach to multi-coach structure
  Future<void> migrateToMultiCoach() async {
    try {
      // Get teams that have single coach but no coaches array
      final teamsQuery = await _firestore
          .collection('teams')
          .where('coach', isNull: false)
          .get();

      int migratedCount = 0;

      for (final doc in teamsQuery.docs) {
        final data = doc.data();
        final oldCoachId = data['coach'];

        // Skip if already has coaches array
        if (data['coaches'] != null) continue;

        if (oldCoachId != null && oldCoachId.toString().isNotEmpty) {
          await doc.reference.update({
            'coaches': [
              {
                'userId': oldCoachId.toString(),
                'role': 'head_coach',
                'assignedAt': Timestamp.now(),
                'assignedBy': 'system_migration',
                'isActive': true,
              }
            ],
            'updated_at': FieldValue.serverTimestamp(),
            // Keep the old coach field for backwards compatibility
          });
          migratedCount++;
        }
      }

      print('✅ Migration completed: $migratedCount teams migrated');
    } catch (e) {
      print('❌ Error during migration: $e');
      rethrow;
    }
  }

  /// Validate team coach assignments
  Future<Map<String, dynamic>> validateTeamCoaches() async {
    try {
      final issues = <String, List<String>>{};
      int validTeams = 0;
      int totalTeams = 0;

      final teamsSnapshot = await _firestore.collection('teams').get();
      totalTeams = teamsSnapshot.docs.length;

      for (final doc in teamsSnapshot.docs) {
        final team = Team.fromFirestore(doc);
        final teamIssues = <String>[];

        // Check if team has coaches
        if (team.coaches.isEmpty) {
          teamIssues.add('No coaches assigned');
        }

        // Check if all coach users exist
        for (final coach in team.activeCoaches) {
          final coachDoc =
              await _firestore.collection('users').doc(coach.userId).get();
          if (!coachDoc.exists) {
            teamIssues.add('Coach ${coach.userId} does not exist');
          } else {
            final userData = coachDoc.data() as Map<String, dynamic>;
            if (userData['role'] != 'coach') {
              teamIssues.add('User ${coach.userId} is not a coach');
            }
          }
        }

        if (teamIssues.isEmpty) {
          validTeams++;
        } else {
          issues[team.teamName] = teamIssues;
        }
      }

      return {
        'totalTeams': totalTeams,
        'validTeams': validTeams,
        'issues': issues,
      };
    } catch (e) {
      print('❌ Error validating teams: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get team statistics
  Future<Map<String, dynamic>> getTeamStatistics() async {
    try {
      final teamsSnapshot = await _firestore.collection('teams').get();
      final teams =
          teamsSnapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();

      int totalCoaches = 0;
      int teamsWithMultipleCoaches = 0;
      int teamsWithNoCoaches = 0;
      final coachRoleDistribution = <String, int>{};

      for (final team in teams) {
        totalCoaches += team.activeCoaches.length;

        if (team.activeCoaches.isEmpty) {
          teamsWithNoCoaches++;
        } else if (team.activeCoaches.length > 1) {
          teamsWithMultipleCoaches++;
        }

        // Count coach roles
        for (final coach in team.activeCoaches) {
          coachRoleDistribution[coach.role] =
              (coachRoleDistribution[coach.role] ?? 0) + 1;
        }
      }

      return {
        'totalTeams': teams.length,
        'totalCoaches': totalCoaches,
        'averageCoachesPerTeam':
            teams.isNotEmpty ? totalCoaches / teams.length : 0,
        'teamsWithMultipleCoaches': teamsWithMultipleCoaches,
        'teamsWithNoCoaches': teamsWithNoCoaches,
        'coachRoleDistribution': coachRoleDistribution,
      };
    } catch (e) {
      print('❌ Error getting team statistics: $e');
      return {'error': e.toString()};
    }
  }

  // COACH ROLE CONSTANTS
  static const String roleHeadCoach = 'head_coach';
  static const String roleAssistantCoach = 'assistant_coach';
  static const String roleTemporaryCoach = 'temporary_coach';
  static const String roleSubstituteCoach = 'substitute_coach';

  static List<String> get allCoachRoles => [
        roleHeadCoach,
        roleAssistantCoach,
        roleTemporaryCoach,
        roleSubstituteCoach,
      ];

  static String getCoachRoleDisplayName(String role) {
    switch (role) {
      case roleHeadCoach:
        return 'Head Coach';
      case roleAssistantCoach:
        return 'Assistant Coach';
      case roleTemporaryCoach:
        return 'Temporary Coach';
      case roleSubstituteCoach:
        return 'Substitute Coach';
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
