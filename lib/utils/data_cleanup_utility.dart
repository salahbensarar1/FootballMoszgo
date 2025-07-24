import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/models/user_model.dart';
import 'package:footballtraining/utils/migration_result.dart';

/// Utility class for cleaning up coach-team relationship data
class DataCleanupUtility {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clean and standardize all coach-team relationships
  Future<MigrationResult> cleanupCoachTeamRelationships() async {
    int totalTeams = 0;
    int migratedTeams = 0;
    int skippedTeams = 0;
    int errorTeams = 0;
    final errors = <String>[];
    final statistics = <String, dynamic>{};

    try {
      // Get all teams
      final teamsSnapshot = await _firestore.collection('teams').get();
      totalTeams = teamsSnapshot.docs.length;
      
      statistics['startTime'] = DateTime.now().toIso8601String();
      statistics['orphanedCoachIds'] = <String>[];
      statistics['duplicateAssignments'] = <String>[];
      statistics['invalidCoaches'] = <String>[];

      for (final teamDoc in teamsSnapshot.docs) {
        try {
          // Analyze current structure
          final analysisResult = await _analyzeTeamStructure(teamDoc);
          
          if (analysisResult['needsMigration'] == true) {
            await _migrateTeamStructure(teamDoc, analysisResult);
            migratedTeams++;
          } else {
            skippedTeams++;
          }
          
          // Collect statistics
          final orphanedIds = analysisResult['orphanedCoachIds'] as List<String>? ?? [];
          final duplicates = analysisResult['duplicates'] as List<String>? ?? [];
          final invalidCoaches = analysisResult['invalidCoaches'] as List<String>? ?? [];
          
          statistics['orphanedCoachIds'].addAll(orphanedIds);
          statistics['duplicateAssignments'].addAll(duplicates);
          statistics['invalidCoaches'].addAll(invalidCoaches);
          
        } catch (e) {
          errorTeams++;
          errors.add('Team ${teamDoc.id}: $e');
        }
      }

      statistics['endTime'] = DateTime.now().toIso8601String();
      final startTime = DateTime.parse(statistics['startTime'] as String);
      final endTime = DateTime.parse(statistics['endTime'] as String);
      statistics['duration'] = endTime.difference(startTime).inSeconds;

    } catch (e) {
      errors.add('Migration failed: $e');
    }

    return MigrationResult(
      totalTeams: totalTeams,
      migratedTeams: migratedTeams,
      skippedTeams: skippedTeams,
      errorTeams: errorTeams,
      errors: errors,
      statistics: statistics,
    );
  }

  /// Analyze team structure and identify issues
  Future<Map<String, dynamic>> _analyzeTeamStructure(DocumentSnapshot teamDoc) async {
    final data = teamDoc.data() as Map<String, dynamic>;
    final analysis = <String, dynamic>{
      'needsMigration': false,
      'issues': <String>[],
      'orphanedCoachIds': <String>[],
      'duplicates': <String>[],
      'invalidCoaches': <String>[],
    };

    // Check for multiple coach storage methods (inconsistency)
    final hasCoachesArray = data['coaches'] != null && data['coaches'] is List;
    final hasCoachIdsArray = data['coach_ids'] != null && data['coach_ids'] is List;
    final hasSingleCoach = data['coach'] != null && data['coach'].toString().isNotEmpty;

    int storageMethodCount = 0;
    if (hasCoachesArray) storageMethodCount++;
    if (hasCoachIdsArray) storageMethodCount++;
    if (hasSingleCoach) storageMethodCount++;

    // If multiple methods exist, check for consistency
    if (storageMethodCount > 1) {
      analysis['issues'].add('Multiple coach storage methods detected');
      analysis['needsMigration'] = true;
    }

    // If no coaches array but has other methods, needs migration
    if (!hasCoachesArray && (hasCoachIdsArray || hasSingleCoach)) {
      analysis['issues'].add('Missing standard coaches array structure');
      analysis['needsMigration'] = true;
    }

    // Validate coach references
    final allCoachIds = <String>{};
    
    // Collect coach IDs from all sources
    if (hasCoachesArray) {
      final coaches = data['coaches'] as List;
      for (final coach in coaches) {
        if (coach is Map && coach['userId'] != null) {
          allCoachIds.add(coach['userId'].toString());
        }
      }
    }
    
    if (hasCoachIdsArray) {
      final coachIds = List<String>.from(data['coach_ids']);
      allCoachIds.addAll(coachIds);
    }
    
    if (hasSingleCoach) {
      allCoachIds.add(data['coach'].toString());
    }

    // Check if coach users exist
    for (final coachId in allCoachIds) {
      try {
        final coachDoc = await _firestore.collection('users').doc(coachId).get();
        if (!coachDoc.exists) {
          analysis['orphanedCoachIds'].add(coachId);
          analysis['needsMigration'] = true;
        } else {
          final coachData = coachDoc.data();
          if (coachData != null) {
            final coachMap = coachData as Map<String, dynamic>;
            if (coachMap['role'] != 'coach') {
              analysis['invalidCoaches'].add(coachId);
              analysis['needsMigration'] = true;
            }
          }
        }
      } catch (e) {
        analysis['invalidCoaches'].add(coachId);
        analysis['needsMigration'] = true;
      }
    }

    return analysis;
  }

  /// Migrate team to standard structure
  Future<void> _migrateTeamStructure(DocumentSnapshot teamDoc, Map<String, dynamic> analysis) async {
    final data = teamDoc.data() as Map<String, dynamic>;
    final validCoaches = <TeamCoach>[];
    final processedCoachIds = <String>{};

    // Priority order: coaches array > coach_ids array > single coach
    
    // 1. Process coaches array (highest priority)
    if (data['coaches'] != null && data['coaches'] is List) {
      final coaches = data['coaches'] as List;
      for (final coachData in coaches) {
        if (coachData is Map) {
          final coachId = coachData['userId']?.toString();
          if (coachId != null && 
              !processedCoachIds.contains(coachId) &&
              !(analysis['orphanedCoachIds'] as List).contains(coachId) &&
              !(analysis['invalidCoaches'] as List).contains(coachId)) {
            
            validCoaches.add(TeamCoach.fromJson(coachData as Map<String, dynamic>));
            processedCoachIds.add(coachId);
          }
        }
      }
    }

    // 2. Process coach_ids array (fallback)
    if (data['coach_ids'] != null && data['coach_ids'] is List) {
      final coachIds = List<String>.from(data['coach_ids']);
      for (final coachId in coachIds) {
        if (!processedCoachIds.contains(coachId) &&
            !(analysis['orphanedCoachIds'] as List).contains(coachId) &&
            !(analysis['invalidCoaches'] as List).contains(coachId)) {
          
          validCoaches.add(TeamCoach(
            userId: coachId,
            role: 'head_coach',
            assignedAt: data['created_at']?.toDate() ?? DateTime.now(),
            assignedBy: 'migration_cleanup',
            isActive: true,
          ));
          processedCoachIds.add(coachId);
        }
      }
    }

    // 3. Process single coach (legacy)
    if (data['coach'] != null && data['coach'].toString().isNotEmpty) {
      final coachId = data['coach'].toString();
      if (!processedCoachIds.contains(coachId) &&
          !(analysis['orphanedCoachIds'] as List).contains(coachId) &&
          !(analysis['invalidCoaches'] as List).contains(coachId)) {
        
        validCoaches.add(TeamCoach(
          userId: coachId,
          role: 'head_coach',
          assignedAt: data['created_at']?.toDate() ?? DateTime.now(),
          assignedBy: 'migration_cleanup',
          isActive: true,
        ));
        processedCoachIds.add(coachId);
      }
    }

    // Update team with clean structure
    final updateData = <String, dynamic>{
      'coaches': validCoaches.map((coach) => coach.toJson()).toList(),
      'coach_ids': validCoaches.map((coach) => coach.userId).toList(),
      'updated_at': FieldValue.serverTimestamp(),
      'migration_timestamp': FieldValue.serverTimestamp(),
      'migration_version': '1.0',
    };

    // Set primary coach for backwards compatibility
    if (validCoaches.isNotEmpty) {
      final headCoach = validCoaches.where((c) => c.role == 'head_coach').firstOrNull;
      updateData['coach'] = headCoach?.userId ?? validCoaches.first.userId;
    } else {
      // Remove coach field if no valid coaches
      updateData['coach'] = FieldValue.delete();
    }

    await teamDoc.reference.update(updateData);
  }

  /// Remove orphaned coach references from user documents
  Future<Map<String, dynamic>> cleanupUserTeamReferences() async {
    final result = <String, dynamic>{
      'processedUsers': 0,
      'updatedUsers': 0,
      'errors': <String>[],
    };

    try {
      // Get all coaches
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .get();

      result['processedUsers'] = usersSnapshot.docs.length;

      for (final userDoc in usersSnapshot.docs) {
        try {
          final user = User.fromFirestore(userDoc);
          final validTeams = <String>[];
          bool needsUpdate = false;

          // Check each assigned team
          for (final teamName in user.allTeams) {
            final teamExists = await _checkTeamExists(teamName, user.id);
            if (teamExists) {
              validTeams.add(teamName);
            } else {
              needsUpdate = true;
            }
          }

          // Update user if orphaned references found
          if (needsUpdate) {
            await userDoc.reference.update({
              'assigned_teams': validTeams,
              'team': validTeams.isNotEmpty ? validTeams.first : FieldValue.delete(),
              'updated_at': FieldValue.serverTimestamp(),
            });
            result['updatedUsers']++;
          }
        } catch (e) {
          result['errors'].add('User ${userDoc.id}: $e');
        }
      }
    } catch (e) {
      result['errors'].add('Cleanup failed: $e');
    }

    return result;
  }

  /// Check if team exists and coach is actually assigned
  Future<bool> _checkTeamExists(String teamName, String coachId) async {
    try {
      final teamsQuery = await _firestore
          .collection('teams')
          .where('team_name', isEqualTo: teamName)
          .limit(1)
          .get();

      if (teamsQuery.docs.isEmpty) return false;

      final teamData = teamsQuery.docs.first.data();
      
      // Check if coach is actually assigned to this team
      return _isCoachAssignedToTeam(teamData, coachId);
    } catch (e) {
      return false;
    }
  }

  /// Helper method to check coach assignment (same logic as TeamService)
  bool _isCoachAssignedToTeam(Map<String, dynamic> teamData, String coachId) {
    // Check coaches array
    if (teamData['coaches'] != null && teamData['coaches'] is List) {
      final coaches = teamData['coaches'] as List;
      for (final coach in coaches) {
        if (coach is Map &&
            coach['userId'] == coachId &&
            (coach['isActive'] ?? true)) {
          return true;
        }
      }
    }

    // Check coach_ids array
    if (teamData['coach_ids'] != null && teamData['coach_ids'] is List) {
      final coachIds = List<String>.from(teamData['coach_ids']);
      if (coachIds.contains(coachId)) return true;
    }

    // Check single coach field
    if (teamData['coach'] == coachId) return true;

    return false;
  }
}