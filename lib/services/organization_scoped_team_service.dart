import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/services/scoped_firestore_service.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/models/user_model.dart' as user_model;

/// Organization-scoped team service that ensures complete data isolation
/// All operations are automatically scoped to the current organization
class OrganizationScopedTeamService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  /// Get teams for the current organization (scoped to current org only)
  Stream<List<Team>> getAllTeams() {
    ScopedFirestoreService.validateContext();

    return ScopedFirestoreService.teams
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return Team.fromFirestore(doc);
            } catch (e) {
              LoggingService.error('Error parsing team document: ${doc.id}', e);
              return null;
            }
          })
          .where((team) => team != null)
          .cast<Team>()
          .toList();
    });
  }

  /// Get teams where user is a coach (scoped to current org)
  Stream<List<Team>> getTeamsForCoach(String coachUserId) {
    ScopedFirestoreService.validateContext();

    // Log important debug information
    LoggingService.info('🔍 Getting teams for coach: $coachUserId');

    return ScopedFirestoreService.teams
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final coachTeams = <Team>[];
      LoggingService.info('Found ${snapshot.docs.length} total teams to check');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final teamId = doc.id;

          // Check if coach is assigned to this team (multiple formats supported)
          bool isCoachAssigned = false;

          // Debug info
          LoggingService.info(
              'Checking team ${data['team_name']} (ID: $teamId) for coach $coachUserId');

          // Check coaches array (new structure)
          if (data['coaches'] != null && data['coaches'] is List) {
            final coaches = List<dynamic>.from(data['coaches']);
            LoggingService.info(
                'Team has ${coaches.length} coaches in the coaches array');

            for (var coach in coaches) {
              String coachId = '';
              String role = '';
              bool isActive = true;

              if (coach is Map<String, dynamic>) {
                coachId = coach['userId'] ??
                    coach['user_id'] ??
                    coach['coach_id'] ??
                    coach['coachId'] ??
                    '';
                role = coach['role'] ?? 'coach';
                isActive = coach['isActive'] ?? coach['is_active'] ?? true;

                LoggingService.info(
                    'Coach entry (Map): ID=$coachId, Role=$role, Active=$isActive');
              } else if (coach is String) {
                coachId = coach;
                LoggingService.info('Coach entry (String): ID=$coachId');
              }

              if (coachId == coachUserId && isActive) {
                isCoachAssigned = true;
                LoggingService.info(
                    '✅ Coach $coachUserId IS assigned to team $teamId');
                break;
              }
            }
          } else {
            LoggingService.info('No coaches array found in team $teamId');
          }

          // Fallback: coach_ids array
          if (!isCoachAssigned &&
              data['coach_ids'] != null &&
              data['coach_ids'] is List) {
            final coachIds = List<String>.from(data['coach_ids']);
            LoggingService.info(
                'Team has ${coachIds.length} coaches in the coach_ids array: $coachIds');
            isCoachAssigned = coachIds.contains(coachUserId);
            if (isCoachAssigned) {
              LoggingService.info(
                  '✅ Coach $coachUserId found in coach_ids for team $teamId');
            }
          }

          // Legacy: single coach field
          if (!isCoachAssigned && data['coach'] == coachUserId) {
            isCoachAssigned = true;
            LoggingService.info(
                '✅ Coach $coachUserId is the main coach for team $teamId');
          }

          if (isCoachAssigned) {
            final team = Team.fromFirestore(doc);
            coachTeams.add(team);
            LoggingService.info(
                '✅ Added team ${team.teamName} to coach\'s teams');
          } else {
            LoggingService.info(
                '❌ Coach $coachUserId is NOT assigned to team $teamId');
          }
        } catch (e) {
          LoggingService.error('Error processing team for coach: ${doc.id}', e);
        }
      }

      LoggingService.info(
          '👥 Found ${coachTeams.length} teams for coach $coachUserId');
      return coachTeams;
    });
  }

  /// Get single team by ID (scoped to current org)
  Future<Team?> getTeamById(String teamId) async {
    ScopedFirestoreService.validateContext();

    try {
      final doc = await ScopedFirestoreService.teams.doc(teamId).get();
      if (doc.exists) {
        return Team.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      LoggingService.error('Error getting team by ID: $teamId', e);
      return null;
    }
  }

  /// Create new team (scoped to current org)
  Future<String> createTeam({
    required String name,
    required String ageGroup,
    String? description,
    List<String>? coachIds,
    Map<String, dynamic>? trainingSchedule,
    double? paymentFee,
  }) async {
    ScopedFirestoreService.validateContext();

    try {
      final teamData = {
        'name': name,
        'age_group': ageGroup,
        'description': description ?? '',
        'coach_ids': coachIds ?? [],
        'coaches': coachIds
                ?.map((id) => {'userId': id, 'role': 'head_coach'})
                .toList() ??
            [],
        'training_schedule': trainingSchedule ?? {},
        'payment_fee': paymentFee ??
            OrganizationContext.currentOrg.settings['default_monthly_fee'] ??
            0,
        'currency':
            OrganizationContext.currentOrg.settings['currency'] ?? 'HUF',
        'is_active': true,
        'number_of_players': 0,
        'season': DateTime.now().year.toString(),
      };

      final docRef =
          await ScopedFirestoreService.createScopedDocument('teams', teamData);

      LoggingService.info('✅ Team created: $name (ID: ${docRef.id})');
      return docRef.id;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to create team: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Update team (scoped to current org)
  Future<void> updateTeam(String teamId, Map<String, dynamic> updates) async {
    ScopedFirestoreService.validateContext();

    try {
      await ScopedFirestoreService.updateScopedDocument(
          'teams', teamId, updates);
      LoggingService.info('✅ Team updated: $teamId');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to update team: $teamId', e, stackTrace);
      rethrow;
    }
  }

  /// Add coach to team (scoped to current org)
  /// This method is an alias to [assignCoachToTeam] for backwards compatibility
  Future<void> addCoachToTeam({
    required String teamId,
    required String coachUserId,
    required String role,
  }) =>
      assignCoachToTeam(teamId, coachUserId, role: role);

  /// Delete team (scoped to current org)
  Future<void> deleteTeam(String teamId) async {
    ScopedFirestoreService.validateContext();

    try {
      // Soft delete - mark as inactive
      await updateTeam(teamId, {
        'is_active': false,
        'deleted_at': FieldValue.serverTimestamp(),
        'deleted_by': _currentUserId,
      });

      LoggingService.info('✅ Team deleted (soft): $teamId');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to delete team: $teamId', e, stackTrace);
      rethrow;
    }
  }

  /// Assign coach to team (scoped to current org) - FIXED BIDIRECTIONAL SYNC
  /// [addCoachToTeam] is provided as an alias for backwards compatibility
  Future<void> assignCoachToTeam(String teamId, String coachUserId,
      {String role = 'coach'}) async {
    ScopedFirestoreService.validateContext();

    try {
      LoggingService.info('🔄 Starting bidirectional coach assignment: $coachUserId -> $teamId with role: $role');

      // STEP 1: Get team data and validate
      final teamDoc = await ScopedFirestoreService.teams.doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found: $teamId');
      }

      final teamData = teamDoc.data() as Map<String, dynamic>;
      final teamName = teamData['team_name'] ?? teamData['name'] ?? 'Unknown Team';

      // STEP 2: Update team's coaches array
      final coaches = List<dynamic>.from(teamData['coaches'] ?? []);

      // Check if coach is already assigned
      bool isCoachFound = false;
      for (int i = 0; i < coaches.length; i++) {
        final coach = coaches[i];
        String coachId;

        if (coach is Map<String, dynamic>) {
          coachId =
              coach['userId'] ?? coach['user_id'] ?? coach['coach_id'] ?? '';
        } else if (coach is String) {
          coachId = coach;
        } else {
          continue;
        }

        if (coachId == coachUserId) {
          // Update existing assignment
          coaches[i] = {
            'userId': coachUserId,
            'role': role,
            'assignedAt': Timestamp.now(),
            'assignedBy': _currentUserId,
            'isActive': true,
          };
          isCoachFound = true;
          LoggingService.info('✅ Updated existing coach assignment');
          break;
        }
      }

      // Add new assignment if not found
      if (!isCoachFound) {
        coaches.add({
          'userId': coachUserId,
          'role': role,
          'assignedAt': Timestamp.now(),
          'assignedBy': _currentUserId,
          'isActive': true,
        });
        LoggingService.info('✅ Added new coach assignment');
      }

      // Update coach_ids array (fallback structure)
      final coachIds = List<String>.from(teamData['coach_ids'] ?? []);
      if (!coachIds.contains(coachUserId)) {
        coachIds.add(coachUserId);
      }

      // STEP 3: Update team document
      await updateTeam(teamId, {
        'coaches': coaches,
        'coach_ids': coachIds,
      });

      // STEP 4: BIDIRECTIONAL SYNC - Update user's teams array
      try {
        final userDoc = await ScopedFirestoreService.users.doc(coachUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userTeams = List<dynamic>.from(userData['teams'] ?? []);

          // Check if team is already in user's teams array
          bool teamFound = false;
          for (int i = 0; i < userTeams.length; i++) {
            final team = userTeams[i];
            if (team is Map<String, dynamic>) {
              final existingTeamId = team['team_id'] ?? '';
              if (existingTeamId == teamId) {
                // Update existing team assignment
                userTeams[i] = {
                  'team_id': teamId,
                  'team_name': teamName,
                  'role': role,
                  'assigned_at': Timestamp.now(),
                  'assigned_by': _currentUserId,
                  'is_active': true,
                };
                teamFound = true;
                break;
              }
            }
          }

          // Add new team if not found
          if (!teamFound) {
            userTeams.add({
              'team_id': teamId,
              'team_name': teamName,
              'role': role,
              'assigned_at': Timestamp.now(),
              'assigned_by': _currentUserId,
              'is_active': true,
            });
          }

          // Update user document
          await ScopedFirestoreService.users.doc(coachUserId).update({
            'teams': userTeams,
            'updated_at': FieldValue.serverTimestamp(),
          });

          LoggingService.info('✅ Updated user teams array for coach: $coachUserId');
        }
      } catch (e) {
        LoggingService.error('⚠️ Failed to update user teams array (non-critical)', e);
        // Don't throw - team assignment succeeded, user sync is secondary
      }

      LoggingService.info('✅ Bidirectional coach assignment completed: $coachUserId -> $teamId');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to assign coach to team', e, stackTrace);
      rethrow;
    }
  }

  /// Remove coach from team (scoped to current org) - FIXED BIDIRECTIONAL SYNC
  Future<void> removeCoachFromTeam(String teamId, String coachUserId) async {
    ScopedFirestoreService.validateContext();

    try {
      LoggingService.info('🔄 Starting bidirectional coach removal: $coachUserId from $teamId');

      // STEP 1: Get team data and validate
      final teamDoc = await ScopedFirestoreService.teams.doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found: $teamId');
      }

      final data = teamDoc.data() as Map<String, dynamic>;

      // STEP 2: Remove from team's coaches array with detailed logging
      final coaches = List<Map<String, dynamic>>.from(data['coaches'] ?? []);
      final initialCoachCount = coaches.length;
      
      LoggingService.info('📋 Team has ${coaches.length} coaches before removal');
      for (var coach in coaches) {
        LoggingService.info('  - Coach: ${coach['userId']} (role: ${coach['role']})');
      }

      // Use more flexible removal logic to handle different field name variations
      coaches.removeWhere((coach) {
        final coachId = coach['userId'] ?? coach['user_id'] ?? coach['coach_id'] ?? '';
        final matches = coachId == coachUserId;
        if (matches) {
          LoggingService.info('🎯 Found coach to remove: $coachId');
        }
        return matches;
      });

      final finalCoachCount = coaches.length;
      LoggingService.info('📋 Team has ${coaches.length} coaches after removal (removed ${initialCoachCount - finalCoachCount})');

      if (initialCoachCount == finalCoachCount) {
        LoggingService.warning('⚠️ Coach $coachUserId was not found in team $teamId coaches array');
        // Don't throw exception - maybe coach was already removed or data is inconsistent
      }

      // STEP 3: Remove from coach_ids array
      final coachIds = List<String>.from(data['coach_ids'] ?? []);
      final initialIdCount = coachIds.length;
      coachIds.remove(coachUserId);
      LoggingService.info('📋 Removed from coach_ids: ${initialIdCount} -> ${coachIds.length}');

      // STEP 4: Update team document
      await updateTeam(teamId, {
        'coaches': coaches,
        'coach_ids': coachIds,
        'coach': null, // Clear legacy field
      });

      // STEP 5: BIDIRECTIONAL SYNC - Remove team from user's teams array
      try {
        final userDoc = await ScopedFirestoreService.users.doc(coachUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userTeams = List<dynamic>.from(userData['teams'] ?? []);
          final initialTeamCount = userTeams.length;

          LoggingService.info('👤 User has ${userTeams.length} teams before removal');

          // Remove team from user's teams array
          userTeams.removeWhere((team) {
            if (team is Map<String, dynamic>) {
              final existingTeamId = team['team_id'] ?? '';
              final matches = existingTeamId == teamId;
              if (matches) {
                LoggingService.info('🎯 Found team to remove from user: $existingTeamId');
              }
              return matches;
            }
            return false;
          });

          final finalTeamCount = userTeams.length;
          LoggingService.info('👤 User has ${userTeams.length} teams after removal (removed ${initialTeamCount - finalTeamCount})');

          // Update user document
          await ScopedFirestoreService.users.doc(coachUserId).update({
            'teams': userTeams,
            'updated_at': FieldValue.serverTimestamp(),
          });

          LoggingService.info('✅ Updated user teams array for coach: $coachUserId');
        } else {
          LoggingService.warning('⚠️ User document not found: $coachUserId');
        }
      } catch (e) {
        LoggingService.error('⚠️ Failed to update user teams array (non-critical)', e);
        // Don't throw - team removal succeeded, user sync is secondary
      }

      LoggingService.info('✅ Bidirectional coach removal completed: $coachUserId from $teamId');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to remove coach from team', e, stackTrace);
      rethrow;
    }
  }

  /// Get available coaches for assignment (scoped to current org)
  /// Only returns users with 'coach' role - admins are excluded from team assignments
  Future<List<user_model.User>> getAvailableCoaches() async {
    try {
      LoggingService.info('🚀 STARTING getAvailableCoaches method');
      
      // Defensive validation - check org context first
      if (!OrganizationContext.isInitialized) {
        LoggingService.error('❌ Organization context not initialized for getAvailableCoaches');
        throw Exception('Organization context not initialized. Please ensure organization is selected.');
      }

      LoggingService.info('✅ Organization context is initialized');
      
      ScopedFirestoreService.validateContext();
      LoggingService.info('✅ Scoped Firestore context validated');
      LoggingService.info('🔍 Getting available coaches for org: ${OrganizationContext.currentOrgId}');
      
      // 🔥 ENHANCED: Try different query strategies to find coaches
      List<QueryDocumentSnapshot> allDocs = [];
      
      // Strategy 1: Try lowercase 'coach'
      LoggingService.info('🔧 Strategy 1: Querying users with role="coach"');
      try {
        final snapshot1 = await ScopedFirestoreService.users
            .where('role', isEqualTo: 'coach')
            .get();
        allDocs.addAll(snapshot1.docs);
        LoggingService.info('📋 Found ${snapshot1.docs.length} users with role="coach"');
        
        // Log details of found users
        for (var doc in snapshot1.docs) {
          final data = doc.data() as Map<String, dynamic>;
          LoggingService.info('  - User ${doc.id}: ${data['name']} (${data['email']})');
        }
      } catch (e) {
        LoggingService.warning('⚠️ Query with role="coach" failed: $e');
      }
      
      // Strategy 2: Try capitalized 'Coach'
      LoggingService.info('🔧 Strategy 2: Querying users with role="Coach"');
      try {
        final snapshot2 = await ScopedFirestoreService.users
            .where('role', isEqualTo: 'Coach')
            .get();
        allDocs.addAll(snapshot2.docs);
        LoggingService.info('📋 Found ${snapshot2.docs.length} users with role="Coach"');
        
        // Log details of found users
        for (var doc in snapshot2.docs) {
          final data = doc.data() as Map<String, dynamic>;
          LoggingService.info('  - User ${doc.id}: ${data['name']} (${data['email']})');
        }
      } catch (e) {
        LoggingService.warning('⚠️ Query with role="Coach" failed: $e');
      }
      
      // Strategy 3: If still no results, get ALL users and filter locally
      if (allDocs.isEmpty) {
        LoggingService.warning('⚠️ No coaches found with role queries, trying to get all users');
        try {
          final snapshotAll = await ScopedFirestoreService.users.get();
          allDocs.addAll(snapshotAll.docs);
          LoggingService.info('📋 Found ${snapshotAll.docs.length} total users to filter');
        } catch (e) {
          LoggingService.error('❌ Failed to get any users', e);
          return [];
        }
      }
      
      final coaches = <user_model.User>[];
      final roleVariations = ['coach', 'Coach', 'COACH'];
      
      for (final doc in allDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final userRole = data['role']?.toString() ?? '';
          
          // Check if user is a coach (flexible role matching)
          final isCoach = roleVariations.contains(userRole);
          
          // Check if user is active (flexible field checking)
          final isActive = data['is_active'] ?? data['isActive'] ?? data['active'] ?? true;
          
          LoggingService.info('👤 User ${doc.id}: role="$userRole", isCoach=$isCoach, isActive=$isActive');
          
          if (isCoach && isActive) {
            final user = user_model.User.fromFirestore(doc);
            // Less strict validation - just check basic required fields
            if (user.id.isNotEmpty && user.name.isNotEmpty && user.email.isNotEmpty) {
              coaches.add(user);
              LoggingService.info('✅ Added coach: ${user.name} (${user.email})');
            } else {
              LoggingService.warning('⚠️ Skipping coach with missing basic data: ${doc.id}');
            }
          }
        } catch (e) {
          LoggingService.error('❌ Error parsing user document ${doc.id}', e);
          // Continue processing other documents
        }
      }
      
      LoggingService.info('✅ Successfully found ${coaches.length} valid coaches');
      
      // If still no coaches found, provide detailed debug info
      if (coaches.isEmpty) {
        LoggingService.warning('⚠️ No coaches found! Debug info:');
        LoggingService.warning('   - Total documents checked: ${allDocs.length}');
        LoggingService.warning('   - Organization ID: ${OrganizationContext.currentOrgId}');
        for (final doc in allDocs.take(5)) {  // Show first 5 for debugging
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role']?.toString() ?? 'unknown';
          final active = data['is_active'] ?? data['isActive'] ?? true;
          LoggingService.warning('   - User ${doc.id}: role="$role", active=$active');
        }
      }
      
      return coaches;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Error getting available coaches', e, stackTrace);
      // Re-throw the error so the UI can show the actual problem
      rethrow;
    }
  }

  /// Get team coach details including user info - FIXED DATA STRUCTURE
  Future<List<Map<String, dynamic>>> getTeamCoachDetails(String teamId) async {
    try {
      // Defensive validation
      if (!OrganizationContext.isInitialized) {
        throw Exception('Organization context not initialized');
      }

      ScopedFirestoreService.validateContext();
      LoggingService.info('🔍 Getting coach details for team: $teamId');

      // Get team data
      final teamDoc = await ScopedFirestoreService.teams.doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found: $teamId');
      }

      final data = teamDoc.data() as Map<String, dynamic>;
      final List<Map<String, dynamic>> coachDetails = [];

      // Process coaches array (new structure)
      if (data['coaches'] != null && data['coaches'] is List) {
        final coaches = List<dynamic>.from(data['coaches']);
        LoggingService.info('📋 Processing ${coaches.length} coaches from team data');

        for (var coach in coaches) {
          if (coach is Map<String, dynamic>) {
            String coachId =
                coach['userId'] ?? coach['user_id'] ?? coach['coach_id'] ?? '';
            if (coachId.isEmpty) {
              LoggingService.warning('⚠️ Skipping coach with empty ID');
              continue;
            }

            // Get coach user details
            try {
              final userDoc =
                  await ScopedFirestoreService.users.doc(coachId).get();
              if (userDoc.exists) {
                final userData = userDoc.data() as Map<String, dynamic>;
                
                // Create User object for proper type handling
                final user = user_model.User.fromFirestore(userDoc);
                
                // Create TeamCoach object for proper type handling
                final teamCoach = TeamCoach.fromJson(coach);

                // Return structure that matches dialog expectations
                coachDetails.add({
                  'user': user,           // ✅ PROPER User object
                  'teamCoach': teamCoach, // ✅ PROPER TeamCoach object
                  // Also include raw data for backwards compatibility
                  'userId': coachId,
                  'name': userData['name'] ?? 'Unknown',
                  'email': userData['email'] ?? '',
                  'role': coach['role'] ?? 'coach',
                  'assignedAt': coach['assignedAt'] ?? Timestamp.now(),
                  'isActive': coach['isActive'] ?? true,
                });

                LoggingService.info('✅ Added coach details: ${user.name} (${user.id})');
              } else {
                LoggingService.warning('⚠️ User document not found for coach: $coachId');
              }
            } catch (e) {
              LoggingService.error('❌ Error getting coach user details: $coachId', e);
              // Continue processing other coaches
            }
          } else {
            LoggingService.warning('⚠️ Invalid coach data structure: $coach');
          }
        }
      } else {
        LoggingService.info('ℹ️ No coaches array found in team data');
      }

      // Sort coaches by assignment date
      if (coachDetails.isNotEmpty) {
        coachDetails.sort((a, b) {
          try {
            final aDate = (a['assignedAt'] as Timestamp).toDate();
            final bDate = (b['assignedAt'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          } catch (e) {
            LoggingService.warning('⚠️ Error sorting coaches by date: $e');
            return 0;
          }
        });
      }

      LoggingService.info('✅ Successfully got details for ${coachDetails.length} coaches');
      return coachDetails;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to get team coach details', e, stackTrace);
      rethrow;
    }
  }

  /// Update coach role (scoped to current org)
  Future<void> updateCoachRole(
      String teamId, String coachId, String newRole) async {
    ScopedFirestoreService.validateContext();

    try {
      final teamDoc = await ScopedFirestoreService.teams.doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found: $teamId');
      }

      final data = teamDoc.data() as Map<String, dynamic>;
      final coaches = List<Map<String, dynamic>>.from(data['coaches'] ?? []);

      // Update role in coaches array
      bool found = false;
      for (int i = 0; i < coaches.length; i++) {
        if (coaches[i]['userId'] == coachId) {
          coaches[i]['role'] = newRole;
          found = true;
          break;
        }
      }

      if (!found) {
        throw Exception('Coach not found in team');
      }

      await updateTeam(teamId, {'coaches': coaches});
      LoggingService.info('✅ Updated role for coach $coachId to $newRole');
    } catch (e) {
      LoggingService.error('❌ Failed to update coach role', e);
      rethrow;
    }
  }

  /// Get team statistics (scoped to current org)
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    ScopedFirestoreService.validateContext();

    try {
      // Get team info
      final team = await getTeamById(teamId);
      if (team == null) {
        throw Exception('Team not found: $teamId');
      }

      // Get player count
      final playersQuery = await ScopedFirestoreService.players
          .where('team_id', isEqualTo: teamId)
          .where('is_active', isEqualTo: true)
          .count()
          .get();

      // Get recent training sessions count
      final sessionsQuery = await ScopedFirestoreService.trainingSessions
          .where('team_id', isEqualTo: teamId)
          .where('start_time',
              isGreaterThan: DateTime.now().subtract(const Duration(days: 30)))
          .count()
          .get();

      // Get payment status
      final overduePaymentsQuery = await ScopedFirestoreService.payments
          .where('team_id', isEqualTo: teamId)
          .where('status', isEqualTo: 'overdue')
          .count()
          .get();

      return {
        'team': team,
        'player_count': playersQuery.count ?? 0,
        'sessions_last_month': sessionsQuery.count ?? 0,
        'overdue_payments': overduePaymentsQuery.count ?? 0,
        'organization_id': OrganizationContext.currentOrgId,
        'organization_name': OrganizationContext.currentOrg.name,
      };
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to get team stats', e, stackTrace);
      rethrow;
    }
  }
}
