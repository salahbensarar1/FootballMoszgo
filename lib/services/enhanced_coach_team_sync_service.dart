import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/services/scoped_firestore_service.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Enhanced Coach-Team Synchronization Service
/// This service ensures perfect bidirectional consistency between coaches and teams
class EnhancedCoachTeamSyncService {
  static const String _serviceName = 'EnhancedCoachTeamSyncService';

  /// Sync coach assignments after coach creation/update
  static Future<void> syncCoachAssignments({
    required String coachUserId,
    required String coachName,
    required String coachEmail,
    required List<Map<String, dynamic>> teamAssignments,
  }) async {
    ScopedFirestoreService.validateContext();
    LoggingService.info('$_serviceName: Starting sync for coach $coachUserId');

    final batch = FirebaseFirestore.instance.batch();
    final timestamp = FieldValue.serverTimestamp();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'system';

    try {
      // 1. Update Coach User Document
      final coachRef = ScopedFirestoreService.users.doc(coachUserId);
      
      // Prepare teams data for coach document
      final teamsData = teamAssignments.map((assignment) => {
        'team_id': assignment['id'] ?? assignment['team_id'],
        'team_name': assignment['team_name'],
        'role': assignment['role'],
        'assigned_at': Timestamp.now(),
        'assigned_by': currentUserId,
        'is_active': true,
      }).toList();

      batch.set(coachRef, {
        'name': coachName,
        'email': coachEmail,
        'role': 'coach',
        'teams': teamsData,
        'team_count': teamAssignments.length,
        'primary_team': teamAssignments.isNotEmpty ? teamAssignments.first['team_name'] : null,
        'organization_id': OrganizationContext.currentOrgId,
        'is_active': true,
        'created_at': timestamp,
        'updated_at': timestamp,
      }, SetOptions(merge: true));

      // 2. Update Each Team Document
      for (final assignment in teamAssignments) {
        final teamId = assignment['id'] ?? assignment['team_id'];
        final teamRef = ScopedFirestoreService.teams.doc(teamId);
        
        // Get current team data first
        final teamDoc = await teamRef.get();
        if (!teamDoc.exists) {
          LoggingService.warning('Team $teamId does not exist, skipping');
          continue;
        }

        final teamData = teamDoc.data() as Map<String, dynamic>;
        final currentCoaches = List<Map<String, dynamic>>.from(
          teamData['coaches']?.map((c) => c is Map ? Map<String, dynamic>.from(c) : {}) ?? []
        );

        // Check if coach is already assigned
        final existingIndex = currentCoaches.indexWhere(
          (c) => c['userId'] == coachUserId || c['user_id'] == coachUserId || c['coach_id'] == coachUserId
        );

        final coachData = {
          'userId': coachUserId, // Standard field name
          'coach_name': coachName,
          'role': assignment['role'],
          'assignedAt': Timestamp.now(),
          'assignedBy': currentUserId,
          'isActive': true,
        };

        if (existingIndex >= 0) {
          // Update existing coach
          currentCoaches[existingIndex] = coachData;
          LoggingService.info('Updated existing coach assignment for team $teamId');
        } else {
          // Add new coach
          currentCoaches.add(coachData);
          LoggingService.info('Added new coach assignment for team $teamId');
        }

        // Count active coaches
        final activeCoaches = currentCoaches.where((c) => c['isActive'] == true).toList();
        final coachIds = activeCoaches.map((c) => c['userId'] as String).toList();

        // Update team with proper counts and backward compatibility
        batch.update(teamRef, {
          'coaches': currentCoaches,
          'coach_count': activeCoaches.length, // ✅ CORRECT COUNT
          'coach_ids': coachIds, // For backward compatibility
          'primary_coach': activeCoaches.isNotEmpty ? activeCoaches.first['userId'] : null,
          'updated_at': timestamp,
        });

        LoggingService.info('Team $teamId will have ${activeCoaches.length} active coaches');
      }

      // 3. Commit all changes atomically
      await batch.commit();
      LoggingService.info('$_serviceName: Successfully synced coach $coachUserId with ${teamAssignments.length} teams');

    } catch (e) {
      LoggingService.error('$_serviceName: Failed to sync coach assignments', e);
      throw Exception('Failed to sync coach assignments: $e');
    }
  }

  /// Remove coach from team and update counts
  static Future<void> removeCoachFromTeam({
    required String coachUserId,
    required String teamId,
  }) async {
    ScopedFirestoreService.validateContext();
    LoggingService.info('$_serviceName: Removing coach $coachUserId from team $teamId');

    final batch = FirebaseFirestore.instance.batch();
    final timestamp = FieldValue.serverTimestamp();

    try {
      // 1. Update Coach Document
      final coachRef = ScopedFirestoreService.users.doc(coachUserId);
      final coachDoc = await coachRef.get();
      
      if (coachDoc.exists) {
        final coachData = coachDoc.data() as Map<String, dynamic>;
        final teams = List<Map<String, dynamic>>.from(coachData['teams'] ?? []);
        
        // Mark team assignment as inactive
        final updatedTeams = teams.map((team) {
          if (team['team_id'] == teamId) {
            return {...team, 'is_active': false, 'removed_at': Timestamp.now()};
          }
          return team;
        }).toList();

        final activeTeams = updatedTeams.where((t) => t['is_active'] == true).toList();

        batch.update(coachRef, {
          'teams': updatedTeams,
          'team_count': activeTeams.length,
          'primary_team': activeTeams.isNotEmpty ? activeTeams.first['team_name'] : null,
          'updated_at': timestamp,
        });
      }

      // 2. Update Team Document
      final teamRef = ScopedFirestoreService.teams.doc(teamId);
      final teamDoc = await teamRef.get();
      
      if (teamDoc.exists) {
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final coaches = List<Map<String, dynamic>>.from(
          teamData['coaches']?.map((c) => c is Map ? Map<String, dynamic>.from(c) : {}) ?? []
        );
        
        // Mark coach as inactive
        final updatedCoaches = coaches.map((coach) {
          final coachId = coach['userId'] ?? coach['user_id'] ?? coach['coach_id'];
          if (coachId == coachUserId) {
            return {...coach, 'isActive': false, 'removed_at': Timestamp.now()};
          }
          return coach;
        }).toList();

        final activeCoaches = updatedCoaches.where((c) => c['isActive'] == true).toList();
        final coachIds = activeCoaches.map((c) => c['userId'] as String).toList();

        batch.update(teamRef, {
          'coaches': updatedCoaches,
          'coach_count': activeCoaches.length, // ✅ CORRECT COUNT
          'coach_ids': coachIds,
          'primary_coach': activeCoaches.isNotEmpty ? activeCoaches.first['userId'] : null,
          'updated_at': timestamp,
        });
      }

      await batch.commit();
      LoggingService.info('$_serviceName: Successfully removed coach from team');

    } catch (e) {
      LoggingService.error('$_serviceName: Failed to remove coach from team', e);
      throw Exception('Failed to remove coach from team: $e');
    }
  }

  /// Fix all coach counts across the organization
  static Future<void> fixAllCoachCounts() async {
    ScopedFirestoreService.validateContext();
    LoggingService.info('$_serviceName: Starting coach count fix for entire organization');

    try {
      final teamsSnapshot = await ScopedFirestoreService.teams
          .where('is_active', isEqualTo: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int fixedCount = 0;

      for (final doc in teamsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final coaches = List<dynamic>.from(data['coaches'] ?? []);
        
        // Count active coaches
        final activeCoaches = coaches.where((coach) {
          if (coach is Map<String, dynamic>) {
            return coach['isActive'] ?? true;
          }
          return true; // Assume active if not specified
        }).toList();

        final currentCount = data['coach_count'] ?? 0;
        final correctCount = activeCoaches.length;

        // Only update if count is wrong
        if (currentCount != correctCount) {
          final coachIds = activeCoaches.map((coach) {
            if (coach is Map<String, dynamic>) {
              return coach['userId'] ?? coach['user_id'] ?? coach['coach_id'] ?? '';
            } else if (coach is String) {
              return coach;
            }
            return '';
          }).where((id) => id.isNotEmpty).cast<String>().toList();

          batch.update(doc.reference, {
            'coach_count': correctCount,
            'coach_ids': coachIds,
            'primary_coach': coachIds.isNotEmpty ? coachIds.first : null,
            'updated_at': FieldValue.serverTimestamp(),
          });

          fixedCount++;
          LoggingService.info('Fixed team ${data['team_name']}: $currentCount → $correctCount coaches');
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        LoggingService.info('$_serviceName: Fixed coach counts for $fixedCount teams');
      } else {
        LoggingService.info('$_serviceName: All coach counts are already correct');
      }

    } catch (e) {
      LoggingService.error('$_serviceName: Failed to fix coach counts', e);
      throw Exception('Failed to fix coach counts: $e');
    }
  }

  /// Validate and repair coach-team relationships
  static Future<Map<String, dynamic>> validateAndRepairRelationships() async {
    ScopedFirestoreService.validateContext();
    LoggingService.info('$_serviceName: Starting relationship validation and repair');

    try {
      final results = {
        'teams_checked': 0,
        'coaches_checked': 0,
        'issues_found': <String>[],
        'repairs_made': <String>[],
      };

      // Get all teams
      final teamsSnapshot = await ScopedFirestoreService.teams.get();
      results['teams_checked'] = teamsSnapshot.docs.length;

      // Get all coaches
      final coachesSnapshot = await ScopedFirestoreService.users
          .where('role', isEqualTo: 'coach')
          .get();
      results['coaches_checked'] = coachesSnapshot.docs.length;

      final batch = FirebaseFirestore.instance.batch();

      // Check each team's coach references
      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final teamName = teamData['team_name'] ?? teamDoc.id;
        final coaches = List<dynamic>.from(teamData['coaches'] ?? []);
        
        final coachIds = <String>[];
        final validCoaches = <Map<String, dynamic>>[];

        for (final coach in coaches) {
          if (coach is Map<String, dynamic>) {
            final coachId = coach['userId'] ?? coach['user_id'] ?? coach['coach_id'];
            if (coachId != null && coachId.isNotEmpty) {
              // Verify coach exists
              final coachDoc = await ScopedFirestoreService.users.doc(coachId).get();
              if (coachDoc.exists) {
                validCoaches.add(coach);
                if (coach['isActive'] ?? true) {
                  coachIds.add(coachId);
                }
              } else {
                (results['issues_found'] as List<String>).add('Team $teamName has non-existent coach: $coachId');
              }
            }
          }
        }

        // Update team if coaches list changed
        if (validCoaches.length != coaches.length || 
            (teamData['coach_count'] ?? 0) != coachIds.length) {
          
          batch.update(teamDoc.reference, {
            'coaches': validCoaches,
            'coach_count': coachIds.length,
            'coach_ids': coachIds,
            'primary_coach': coachIds.isNotEmpty ? coachIds.first : null,
            'updated_at': FieldValue.serverTimestamp(),
          });

          (results['repairs_made'] as List<String>).add('Fixed team $teamName: ${coaches.length} → ${validCoaches.length} coaches, count: ${teamData['coach_count']} → ${coachIds.length}');
        }
      }

      // Commit repairs
      if ((results['repairs_made'] as List).isNotEmpty) {
        await batch.commit();
      }

      final issuesFound = (results['issues_found'] as List).length;
      final repairsMade = (results['repairs_made'] as List).length;
      LoggingService.info('$_serviceName: Validation complete - $issuesFound issues, $repairsMade repairs');
      return results;

    } catch (e) {
      LoggingService.error('$_serviceName: Failed to validate relationships', e);
      throw Exception('Failed to validate relationships: $e');
    }
  }
}