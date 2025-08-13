import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/models/user_model.dart' as user_model;
import 'package:footballtraining/services/logging_service.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID for audit trail
  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  // 🔥 FIXED: Get teams for coach - handles BOTH old and new data structures
  Stream<List<Team>> getTeamsForCoach(String coachUserId) {
    return _firestore.collection('teams').snapshots().map((snapshot) {
      final coachTeams = <Team>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Skip inactive teams
          if (data['is_active'] == false) continue;

          if (_isCoachAssignedToTeam(data, coachUserId)) {
            final team = Team.fromFirestore(doc);
            coachTeams.add(team);
          }
        } catch (e) {
          // Log error but don't break the stream
          continue;
        }
      }

      return coachTeams;
    });
  }

  /// Helper method to check if coach is assigned to team (handles all data structures)
  bool _isCoachAssignedToTeam(
      Map<String, dynamic> teamData, String coachUserId) {
    // PRIMARY: Check coaches array (new standard structure)
    if (teamData['coaches'] != null && teamData['coaches'] is List) {
      final coaches = teamData['coaches'] as List;
      for (final coach in coaches) {
        if (coach is Map &&
            (coach['userId'] == coachUserId || coach['coach_id'] == coachUserId) &&
            (coach['isActive'] ?? true)) {
          return true;
        }
      }
    }

    // FALLBACK: Check coach_ids array (existing structure)
    if (teamData['coach_ids'] != null && teamData['coach_ids'] is List) {
      final coachIds = List<String>.from(teamData['coach_ids']);
      if (coachIds.contains(coachUserId)) {
        return true;
      }
    }

    // LEGACY: Check single coach field (backwards compatibility)
    if (teamData['coach'] == coachUserId) {
      return true;
    }

    return false;
  }

  /// 🔥 NEW: Cascade delete coach from all teams and authentication
  Future<void> deleteCoachCompletely(String coachUserId) async {
    try {
      final batch = _firestore.batch();

      // 1. Get all teams where coach is assigned
      final teamsSnapshot = await _firestore.collection('teams').get();

      for (final teamDoc in teamsSnapshot.docs) {
        final data = teamDoc.data();
        bool needsUpdate = false;

        // Remove from coaches array (new structure)
        if (data['coaches'] != null && data['coaches'] is List) {
          final coaches = List<Map<String, dynamic>>.from(data['coaches']);
          final originalLength = coaches.length;
          coaches.removeWhere((coach) => coach['userId'] == coachUserId);
          if (coaches.length != originalLength) {
            batch.update(teamDoc.reference, {'coaches': coaches});
            needsUpdate = true;
          }
        }

        // Remove from coach_ids array (fallback structure)
        if (data['coach_ids'] != null && data['coach_ids'] is List) {
          final coachIds = List<String>.from(data['coach_ids']);
          if (coachIds.contains(coachUserId)) {
            coachIds.remove(coachUserId);
            batch.update(teamDoc.reference, {'coach_ids': coachIds});
            needsUpdate = true;
          }
        }

        // Remove single coach (legacy structure)
        if (data['coach'] == coachUserId) {
          batch.update(teamDoc.reference, {'coach': null});
          needsUpdate = true;
        }

        // Add audit trail
        if (needsUpdate) {
          batch.update(teamDoc.reference, {
            'last_modified': FieldValue.serverTimestamp(),
            'modified_by': _currentUserId,
            'modification_reason': 'Coach deleted - cascade cleanup'
          });
        }
      }

      // 2. Delete user document
      batch.delete(_firestore.collection('users').doc(coachUserId));

      // 3. Commit all changes
      await batch.commit();

      // 4. Delete from Firebase Auth (this should be done by admin)
      // Note: This requires admin privileges and should be handled server-side
      LoggingService.info(
          '✅ Coach $coachUserId successfully deleted from all teams and user collection');
    } catch (e) {
      LoggingService.error('❌ Error deleting coach', e);
      rethrow;
    }
  }

  /// 🔥 NEW: Remove coach from specific team only (direct removal)
  Future<void> removeCoachFromTeamDirect(
      String teamId, String coachUserId) async {
    try {
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final data = teamDoc.data()!;
      final updates = <String, dynamic>{};

      // Remove from coaches array (new structure)
      if (data['coaches'] != null && data['coaches'] is List) {
        final coaches = List<Map<String, dynamic>>.from(data['coaches']);
        coaches.removeWhere((coach) => coach['userId'] == coachUserId);
        updates['coaches'] = coaches;
      }

      // Remove from coach_ids array (fallback structure)
      if (data['coach_ids'] != null && data['coach_ids'] is List) {
        final coachIds = List<String>.from(data['coach_ids']);
        coachIds.remove(coachUserId);
        updates['coach_ids'] = coachIds;
      }

      // Remove single coach (legacy structure)
      if (data['coach'] == coachUserId) {
        updates['coach'] = null;
      }

      // Add audit trail
      updates['last_modified'] = FieldValue.serverTimestamp();
      updates['modified_by'] = _currentUserId;

      await teamRef.update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 FIXED: Alternative query method for immediate debugging
  Future<List<Team>> getTeamsForCoachDebug(String coachUserId) async {
    try {
      LoggingService.debug('🔍 DEBUG: Getting teams for coach: $coachUserId');

      final snapshot = await _firestore.collection('teams').get();
      LoggingService.debug('📊 DEBUG: Total teams in database: ${snapshot.docs.length}');

      final coachTeams = <Team>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        LoggingService.debug('🏟️ DEBUG: Checking team: ${data['team_name']} (${doc.id})');
        LoggingService.debug('📋 DEBUG: Team data keys: ${data.keys.toList()}');

        // Check all possible coach storage methods
        bool isCoachInTeam = false;
        String foundMethod = '';

        // Check coach_ids array
        if (data['coach_ids'] != null) {
          LoggingService.debug('🔍 DEBUG: coach_ids found: ${data['coach_ids']}');
          final coachIds = List<String>.from(data['coach_ids']);
          if (coachIds.contains(coachUserId)) {
            isCoachInTeam = true;
            foundMethod = 'coach_ids array';
          }
        }

        // Check coaches array
        if (data['coaches'] != null) {
          LoggingService.debug('🔍 DEBUG: coaches found: ${data['coaches']}');
          final coaches = data['coaches'] as List;
          for (final coach in coaches) {
            if (coach is Map && (coach['userId'] == coachUserId || coach['coach_id'] == coachUserId)) {
              isCoachInTeam = true;
              foundMethod = 'coaches array';
              break;
            }
          }
        }

        // Check single coach
        if (data['coach'] != null) {
          LoggingService.debug('🔍 DEBUG: single coach found: ${data['coach']}');
          if (data['coach'] == coachUserId) {
            isCoachInTeam = true;
            foundMethod = 'single coach';
          }
        }

        if (isCoachInTeam) {
          LoggingService.debug('✅ DEBUG: Coach found in team via $foundMethod');
          final team = Team.fromFirestore(doc);
          coachTeams.add(team);
        } else {
          LoggingService.debug('❌ DEBUG: Coach NOT found in this team');
        }
      }

      LoggingService.debug('🏆 DEBUG: Final result: ${coachTeams.length} teams found');
      return coachTeams;
    } catch (e) {
      LoggingService.error('❌ DEBUG: Error getting teams', e);
      return [];
    }
  }

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
        'coach_ids': updatedCoaches
            .where((c) => c.isActive)
            .map((c) => c.userId)
            .toList(),
        'coach': updatedCoaches
            .firstWhere((c) => c.isActive)
            .userId, // Keep backwards compatibility
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.info('✅ Coach added successfully: $coachUserId to team $teamId');
    } catch (e) {
      LoggingService.error('❌ Error adding coach', e);
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
        'coach_ids': activeCoaches.map((c) => c.userId).toList(),
        'coach': primaryCoachId, // Update single coach field
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.info('✅ Coach removed successfully: $coachUserId from team $teamId');
    } catch (e) {
      LoggingService.error('❌ Error removing coach', e);
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

      LoggingService.info('✅ Coach role updated: $coachUserId -> $newRole');
    } catch (e) {
      LoggingService.error('❌ Error updating coach role', e);
      rethrow;
    }
  }

  // TEAM QUERY METHODS

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
      LoggingService.error('❌ Error getting team', e);
      return null;
    }
  }

  // COACH QUERY METHODS

  /// Get all available coaches for assignment
  Future<List<user_model.User>> getAvailableCoaches() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .where('is_active', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => user_model.User.fromFirestore(doc))
          .toList();
    } catch (e) {
      LoggingService.error('❌ Error getting available coaches', e);
      return [];
    }
  }

  /// Get coaches not assigned to a specific team
  Future<List<user_model.User>> getUnassignedCoaches(String teamId) async {
    try {
      final team = await getTeamById(teamId);
      if (team == null) return [];

      final allCoaches = await getAvailableCoaches();
      final assignedCoachIds = team.activeCoachIds;

      return allCoaches
          .where((coach) => !assignedCoachIds.contains(coach.id))
          .toList();
    } catch (e) {
      LoggingService.error('❌ Error getting unassigned coaches', e);
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
            final coach = user_model.User.fromFirestore(coachDoc);
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
          LoggingService.warning('⚠️ Error getting coach details for ${teamCoach.userId}', e);
        }
      }

      return coachDetails;
    } catch (e) {
      LoggingService.error('❌ Error getting team coach details', e);
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
        teamData['coach_ids'] = [initialCoachId];
        teamData['coach'] = initialCoachId; // Backwards compatibility
      }

      final docRef = await _firestore.collection('teams').add(teamData);
      LoggingService.info('✅ Team created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      LoggingService.error('❌ Error creating team', e);
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

      LoggingService.info('✅ Team updated successfully: ${team.id}');
    } catch (e) {
      LoggingService.error('❌ Error updating team', e);
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

      LoggingService.info('✅ Team deleted successfully: $teamId');
    } catch (e) {
      LoggingService.error('❌ Error deleting team', e);
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
            'coach_ids': [oldCoachId.toString()],
            'updated_at': FieldValue.serverTimestamp(),
            // Keep the old coach field for backwards compatibility
          });
          migratedCount++;
        }
      }

      LoggingService.info('✅ Migration completed: $migratedCount teams migrated');
    } catch (e) {
      LoggingService.error('❌ Error during migration', e);
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
      LoggingService.error('❌ Error validating teams', e);
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
      LoggingService.error('❌ Error getting team statistics', e);
      return {'error': e.toString()};
    }
  }

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
