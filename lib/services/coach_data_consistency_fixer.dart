import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/scoped_firestore_service.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/services/organization_context.dart';

/// 🛠️ CRITICAL DATA CONSISTENCY FIXER
/// Fixes the mess between coaches assignments in teams and users collections
/// 
/// THE PROBLEM:
/// - Teams collection has coaches[].userId
/// - Some teams have primary_coach with wrong IDs
/// - Users collection has teams[] with mismatched team_id references
/// - Multiple services writing different field structures
class CoachDataConsistencyFixer {
  
  /// 🚨 EMERGENCY FIX: Synchronize ALL coach assignments
  /// This fixes the bidirectional relationship mess
  static Future<Map<String, dynamic>> fixAllCoachAssignments() async {
    ScopedFirestoreService.validateContext();
    
    final results = {
      'teams_processed': 0,
      'users_processed': 0,
      'assignments_fixed': 0,
      'errors': <String>[],
      'fixed_assignments': <Map<String, dynamic>>[],
    };
    
    try {
      LoggingService.info('🔧 Starting EMERGENCY coach assignment fix...');
      
      // STEP 1: Get all teams and build the source of truth
      final teamsSnapshot = await ScopedFirestoreService.teams
          .where('is_active', isEqualTo: true)
          .get();
      
      final Map<String, List<Map<String, dynamic>>> teamCoachesMap = {};
      final Map<String, Map<String, dynamic>> teamInfoMap = {};
      
      // Process each team to extract coach assignments
      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final teamId = teamDoc.id;
        final teamName = teamData['team_name'] ?? 'Unknown Team';
        
        teamInfoMap[teamId] = {
          'id': teamId,
          'name': teamName,
          'data': teamData,
        };
        
        final List<Map<String, dynamic>> teamCoaches = [];
        
        // Extract coaches from coaches array (new structure - SOURCE OF TRUTH)
        if (teamData['coaches'] != null && teamData['coaches'] is List) {
          final coaches = List<dynamic>.from(teamData['coaches']);
          
          for (var coach in coaches) {
            if (coach is Map<String, dynamic>) {
              final coachId = coach['userId'] ?? 
                             coach['user_id'] ?? 
                             coach['coach_id'] ?? 
                             coach['coachId'] ?? '';
              
              final role = coach['role'] ?? 'coach';
              final isActive = coach['isActive'] ?? coach['is_active'] ?? true;
              
              if (coachId.isNotEmpty && isActive) {
                teamCoaches.add({
                  'coach_id': coachId,
                  'role': role,
                  'team_id': teamId,
                  'team_name': teamName,
                });
                
                LoggingService.info('✓ Found coach assignment: $coachId -> $teamId ($role)');
              }
            } else if (coach is String && coach.isNotEmpty) {
              // Handle legacy string format
              teamCoaches.add({
                'coach_id': coach,
                'role': 'coach',
                'team_id': teamId,
                'team_name': teamName,
              });
              
              LoggingService.info('✓ Found legacy coach assignment: $coach -> $teamId');
            }
          }
        }
        
        // Also check primary_coach field for additional assignments
        if (teamData['primary_coach'] != null && teamData['primary_coach'].toString().isNotEmpty) {
          final primaryCoachId = teamData['primary_coach'].toString();
          
          // Only add if not already in the list
          final alreadyExists = teamCoaches.any((c) => c['coach_id'] == primaryCoachId);
          if (!alreadyExists) {
            teamCoaches.add({
              'coach_id': primaryCoachId,
              'role': 'head_coach',
              'team_id': teamId,
              'team_name': teamName,
            });
            
            LoggingService.info('✓ Found primary coach: $primaryCoachId -> $teamId');
          }
        }
        
        teamCoachesMap[teamId] = teamCoaches;
        results['teams_processed'] = (results['teams_processed'] as int) + 1;
      }
      
      // STEP 2: Build reverse mapping (coach -> teams)
      final Map<String, List<Map<String, dynamic>>> coachTeamsMap = {};
      
      for (final teamId in teamCoachesMap.keys) {
        for (final coachAssignment in teamCoachesMap[teamId]!) {
          final coachId = coachAssignment['coach_id'] as String;
          
          if (!coachTeamsMap.containsKey(coachId)) {
            coachTeamsMap[coachId] = [];
          }
          
          coachTeamsMap[coachId]!.add(coachAssignment);
        }
      }
      
      // STEP 3: Fix all user documents to match the source of truth
      final batch = FirebaseFirestore.instance.batch();
      
      for (final coachId in coachTeamsMap.keys) {
        final userDoc = await ScopedFirestoreService.users.doc(coachId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final coachTeams = coachTeamsMap[coachId]!;
          
          // Build correct teams array
          final fixedTeamsArray = coachTeams.map((assignment) {
            return {
              'team_id': assignment['team_id'],
              'team_name': assignment['team_name'],
              'role': assignment['role'],
              'is_active': true,
              'assigned_at': FieldValue.serverTimestamp(),
              'organization_id': OrganizationContext.currentOrgId,
            };
          }).toList();
          
          // Set primary_coach to first team (most important)
          final primaryTeamId = coachTeams.isNotEmpty ? coachTeams.first['team_id'] : null;
          
          // Update user document
          batch.update(
            ScopedFirestoreService.users.doc(coachId),
            {
              'teams': fixedTeamsArray,
              'primary_coach': primaryTeamId,
              'updated_at': FieldValue.serverTimestamp(),
            },
          );
          
          results['users_processed'] = (results['users_processed'] as int) + 1;
          results['assignments_fixed'] = (results['assignments_fixed'] as int) + coachTeams.length;
          
          (results['fixed_assignments'] as List<Map<String, dynamic>>).add({
            'coach_id': coachId,
            'coach_name': userData['name'] ?? 'Unknown',
            'teams_assigned': coachTeams.length,
            'teams': coachTeams.map((t) => '${t['team_name']} (${t['role']})').toList(),
          });
          
          LoggingService.info('✅ Fixed user assignments for coach: $coachId (${coachTeams.length} teams)');
        } else {
          LoggingService.warning('⚠️ Coach user not found: $coachId');
          (results['errors'] as List<String>).add('Coach user not found: $coachId');
        }
      }
      
      // STEP 4: Fix team documents to ensure consistent coach structure
      for (final teamId in teamCoachesMap.keys) {
        final teamCoaches = teamCoachesMap[teamId]!;
        final teamInfo = teamInfoMap[teamId]!;
        
        // Build consistent coaches array (ensure all use 'userId' field)
        final fixedCoachesArray = teamCoaches.map((coach) {
          return {
            'userId': coach['coach_id'], // ✅ CONSISTENT FIELD NAME
            'role': coach['role'],
            'assignedAt': FieldValue.serverTimestamp(),
            'isActive': true,
          };
        }).toList();
        
        // Set primary_coach to first coach ID
        final primaryCoachId = teamCoaches.isNotEmpty ? teamCoaches.first['coach_id'] : null;
        
        // Update team document
        batch.update(
          ScopedFirestoreService.teams.doc(teamId),
          {
            'coaches': fixedCoachesArray,
            'primary_coach': primaryCoachId,
            'coach_count': teamCoaches.length,
            'coach_ids': teamCoaches.map((c) => c['coach_id']).toList(), // Fallback array
            'updated_at': FieldValue.serverTimestamp(),
          },
        );
        
        LoggingService.info('✅ Fixed team structure for: ${teamInfo['name']} (${teamCoaches.length} coaches)');
      }
      
      // STEP 5: Commit all fixes
      await batch.commit();
      
      LoggingService.info('🎉 EMERGENCY FIX COMPLETED!');
      LoggingService.info('📊 Results: ${results['teams_processed']} teams, ${results['users_processed']} users, ${results['assignments_fixed']} assignments fixed');
      
      return results;
      
    } catch (e, stackTrace) {
      LoggingService.error('❌ EMERGENCY FIX FAILED', e, stackTrace);
      (results['errors'] as List<String>).add('Emergency fix failed: $e');
      return results;
    }
  }
  
  /// 🔍 DIAGNOSIS: Check current data consistency state
  static Future<Map<String, dynamic>> diagnoseDataConsistency() async {
    ScopedFirestoreService.validateContext();
    
    final diagnosis = {
      'total_teams': 0,
      'total_coaches': 0,
      'inconsistent_teams': <Map<String, dynamic>>[],
      'inconsistent_users': <Map<String, dynamic>>[],
      'orphaned_assignments': <Map<String, dynamic>>[],
      'field_mismatches': <String>[],
    };
    
    try {
      // Check teams collection
      final teamsSnapshot = await ScopedFirestoreService.teams
          .where('is_active', isEqualTo: true)
          .get();
      
      diagnosis['total_teams'] = teamsSnapshot.docs.length;
      
      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data() as Map<String, dynamic>;
        final teamId = teamDoc.id;
        final teamName = teamData['team_name'] ?? 'Unknown';
        
        final issues = <String>[];
        
        // Check for field inconsistencies
        if (teamData['coaches'] is List) {
          final coaches = List<dynamic>.from(teamData['coaches']);
          for (var coach in coaches) {
            if (coach is Map<String, dynamic>) {
              // Check which field is used for coach ID
              final hasUserId = coach.containsKey('userId');
              final hasCoachId = coach.containsKey('coach_id');
              final hasUserIdAlt = coach.containsKey('user_id');
              
              if (!hasUserId && hasCoachId) {
                issues.add('Uses coach_id instead of userId');
              }
              if (!hasUserId && hasUserIdAlt) {
                issues.add('Uses user_id instead of userId');
              }
            }
          }
        }
        
        if (issues.isNotEmpty) {
          (diagnosis['inconsistent_teams'] as List<Map<String, dynamic>>).add({
            'team_id': teamId,
            'team_name': teamName,
            'issues': issues,
          });
        }
      }
      
      return diagnosis;
      
    } catch (e, stackTrace) {
      LoggingService.error('❌ Diagnosis failed', e, stackTrace);
      return diagnosis;
    }
  }
}