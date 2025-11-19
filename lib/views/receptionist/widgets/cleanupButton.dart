// Memory-safe data cleanup utility with batch size limits
// Prevents memory crashes when processing large datasets

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/utils/batch_size_constants.dart';

class DataCleanupUtility {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🧹 MAIN CLEANUP FUNCTION - Run this to fix your current data
  Future<Map<String, dynamic>> cleanupOrphanedData() async {
    print('🧹 Starting data cleanup...');

    final results = {
      'orphaned_users_cleaned': 0,
      'orphaned_team_refs_cleaned': 0,
      'invalid_coach_assignments_fixed': 0,
      'auth_orphans_found': 0,
      'errors': <String>[],
    };

    try {
      // 1. Clean orphaned team references in users
      results['orphaned_team_refs_cleaned'] = await _cleanOrphanedTeamRefs();

      // 2. Clean orphaned coach assignments in teams
      results['invalid_coach_assignments_fixed'] =
          await _cleanInvalidCoachAssignments();

      // 3. Find authentication orphans
      results['auth_orphans_found'] = await _findAuthenticationOrphans();

      // 4. Clean orphaned users
      results['orphaned_users_cleaned'] = await _cleanOrphanedUsers();

      print('✅ Cleanup completed successfully');
      return results;
    } catch (e) {
      ((results['errors'] ??= <String>[]) as List<String>).add(e.toString());
      print('❌ Cleanup failed: $e');
      return results;
    }
  }

  // Clean team references in users that point to non-existent teams
  Future<int> _cleanOrphanedTeamRefs() async {
    print('🔍 Cleaning orphaned team references in users...');

    // MEMORY-SAFE: Get teams with pagination to prevent crashes
    final existingTeamIds = <String>{};
    final existingTeamNames = <String>{};

    await _loadTeamsInBatches(existingTeamIds, existingTeamNames);

    print('📊 Loaded ${existingTeamIds.length} teams safely');

    // MEMORY-SAFE: Get users with pagination
    return await _processUsersInBatches(existingTeamIds, existingTeamNames);
  }

  /// Load all teams in safe batches to prevent memory crashes
  Future<void> _loadTeamsInBatches(
      Set<String> teamIds, Set<String> teamNames) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('teams')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch
      for (final doc in snapshot.docs) {
        teamIds.add(doc.id);
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final teamName = data['team_name'] as String?;
          if (teamName != null && teamName.isNotEmpty) {
            teamNames.add(teamName);
          }
        }
      }

      totalProcessed += snapshot.docs.length;
      lastDoc = snapshot.docs.last;

      // Safety check to prevent infinite loops
      if (snapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Processed $totalProcessed teams (batch: ${snapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Process users in safe batches to prevent memory crashes
  Future<int> _processUsersInBatches(
      Set<String> existingTeamIds, Set<String> existingTeamNames) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int cleanedCount = 0;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('users')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final usersSnapshot = await query.get();

      if (usersSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch of users
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) continue;

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Check team field (single team reference)
        if (userData['team'] != null) {
          final teamRef = userData['team'].toString();
          if (!existingTeamNames.contains(teamRef) &&
              !existingTeamIds.contains(teamRef)) {
            updates['team'] = null;
            needsUpdate = true;
            print(
                '🗑️  Removing invalid team reference: $teamRef from user ${userData['name'] ?? 'Unknown'}');
          }
        }

        // Check team_ids array
        if (userData['team_ids'] != null && userData['team_ids'] is List) {
          final teamIds = List<String>.from(userData['team_ids']);
          final validTeamIds =
              teamIds.where((id) => existingTeamIds.contains(id)).toList();

          if (validTeamIds.length != teamIds.length) {
            updates['team_ids'] = validTeamIds;
            needsUpdate = true;
            print(
                '🗑️  Cleaning team_ids for user ${userData['name'] ?? 'Unknown'}: ${teamIds.length} -> ${validTeamIds.length}');
          }
        }

        // Check assigned_teams array
        if (userData['assigned_teams'] != null &&
            userData['assigned_teams'] is List) {
          final assignedTeams = List<String>.from(userData['assigned_teams']);
          final validTeams = assignedTeams
              .where((name) => existingTeamNames.contains(name))
              .toList();

          if (validTeams.length != assignedTeams.length) {
            updates['assigned_teams'] = validTeams;
            needsUpdate = true;
            print(
                '🗑️  Cleaning assigned_teams for user ${userData['name'] ?? 'Unknown'}: ${assignedTeams.length} -> ${validTeams.length}');
          }
        }

        if (needsUpdate) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          await userDoc.reference.update(updates);
          cleanedCount++;
        }
      }

      totalProcessed += usersSnapshot.docs.length;
      lastDoc = usersSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (usersSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print(
          '📦 Processed $totalProcessed users (batch: ${usersSnapshot.docs.length}, cleaned: $cleanedCount)');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Cleaned $cleanedCount users with orphaned team references');
    return cleanedCount;
  }

  // Clean invalid coach assignments in teams
  Future<int> _cleanInvalidCoachAssignments() async {
    print('🔍 Cleaning invalid coach assignments in teams...');

    // MEMORY-SAFE: Get all users in batches to check against
    final existingUserIds = <String>{};
    await _loadUserIdsInBatches(existingUserIds);

    print('📊 Loaded ${existingUserIds.length} user IDs safely');

    // MEMORY-SAFE: Process teams in batches
    return await _processTeamsInBatches(existingUserIds);
  }

  /// Load all user IDs in safe batches to prevent memory crashes
  Future<void> _loadUserIdsInBatches(Set<String> userIds) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('users')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch
      for (final doc in snapshot.docs) {
        userIds.add(doc.id);
      }

      totalProcessed += snapshot.docs.length;
      lastDoc = snapshot.docs.last;

      // Safety check to prevent infinite loops
      if (snapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Processed $totalProcessed user IDs (batch: ${snapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Process teams in safe batches to clean invalid coach assignments
  Future<int> _processTeamsInBatches(Set<String> existingUserIds) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int fixedCount = 0;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('teams')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final teamsSnapshot = await query.get();

      if (teamsSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch of teams
      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data() as Map<String, dynamic>?;
        if (teamData == null) continue;

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Check coach_ids array
        if (teamData['coach_ids'] != null && teamData['coach_ids'] is List) {
          final coachIds = List<String>.from(teamData['coach_ids']);
          final validCoachIds =
              coachIds.where((id) => existingUserIds.contains(id)).toList();

          if (validCoachIds.length != coachIds.length) {
            updates['coach_ids'] = validCoachIds;
            needsUpdate = true;
            print(
                '🗑️  Cleaning coach_ids for team ${teamData['team_name'] ?? 'Unknown'}: ${coachIds.length} -> ${validCoachIds.length}');
          }
        }

        // Check single coach field
        if (teamData['coach'] != null) {
          final coachId = teamData['coach'].toString();
          // Get validCoachIds for this team
          List<String> validCoachIds = [];
          if (teamData['coach_ids'] != null && teamData['coach_ids'] is List) {
            final coachIds = List<String>.from(teamData['coach_ids']);
            validCoachIds =
                coachIds.where((id) => existingUserIds.contains(id)).toList();
          }
          if (!existingUserIds.contains(coachId)) {
            updates['coach'] =
                validCoachIds.isNotEmpty ? validCoachIds.first : null;
            needsUpdate = true;
            print(
                '🗑️  Removing invalid coach reference: $coachId from team ${teamData['team_name'] ?? 'Unknown'}');
          }
        }

        // Check coaches array (complex objects)
        if (teamData['coaches'] != null && teamData['coaches'] is List) {
          final coaches = teamData['coaches'] as List<dynamic>;
          final validCoaches = coaches.where((coach) {
            if (coach is Map<String, dynamic>) {
              final userId = coach['userId'];
              return userId != null && existingUserIds.contains(userId);
            }
            return false;
          }).toList();

          if (validCoaches.length != coaches.length) {
            updates['coaches'] = validCoaches;
            needsUpdate = true;
            print(
                '🗑️  Cleaning coaches array for team ${teamData['team_name'] ?? 'Unknown'}: ${coaches.length} -> ${validCoaches.length}');
          }
        }

        if (needsUpdate) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          await teamDoc.reference.update(updates);
          fixedCount++;
        }
      }

      totalProcessed += teamsSnapshot.docs.length;
      lastDoc = teamsSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (teamsSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print(
          '📦 Processed $totalProcessed teams (batch: ${teamsSnapshot.docs.length}, fixed: $fixedCount)');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Fixed $fixedCount teams with invalid coach assignments');
    return fixedCount;
  }

  // Find users in Firebase Auth that don't exist in Firestore
  Future<int> _findAuthenticationOrphans() async {
    print('🔍 Finding authentication orphans...');

    // MEMORY-SAFE: Get all Firestore user emails in batches
    final firestoreEmails = <String>{};
    await _loadUserEmailsInBatches(firestoreEmails);

    print('📊 Found ${firestoreEmails.length} users in Firestore');
    print('⚠️  Note: Firebase Auth user enumeration requires Admin SDK');
    print('💡 Suggestion: Use Firebase Console to manually clean auth orphans');

    return 0; // Can't enumerate auth users with client SDK
  }

  /// Load all user emails in safe batches
  Future<void> _loadUserEmailsInBatches(Set<String> emails) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('users')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final email = data['email'] as String?;
          if (email != null && email.isNotEmpty) {
            emails.add(email);
          }
        }
      }

      totalProcessed += snapshot.docs.length;
      lastDoc = snapshot.docs.last;

      // Safety check to prevent infinite loops
      if (snapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Processed $totalProcessed user emails (batch: ${snapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Clean users that have invalid data
  Future<int> _cleanOrphanedUsers() async {
    print('🔍 Cleaning orphaned user records...');

    return await _processInvalidUsersInBatches();
  }

  /// Process users in batches to find and optionally clean invalid records
  Future<int> _processInvalidUsersInBatches() async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int cleanedCount = 0;
    int totalProcessed = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('users')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final usersSnapshot = await query.get();

      if (usersSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Process this batch of users
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) continue;

        // Check for essential fields
        final email = userData['email'];
        final name = userData['name'];
        final role = userData['role'];

        if (email == null ||
            email.toString().isEmpty ||
            name == null ||
            name.toString().isEmpty ||
            role == null ||
            role.toString().isEmpty) {
          print('🗑️  Found invalid user record: ${userDoc.id}');
          print('   Email: $email, Name: $name, Role: $role');

          // You can uncomment the next line to actually delete invalid users
          // await userDoc.reference.delete();
          // cleanedCount++;
        }
      }

      totalProcessed += usersSnapshot.docs.length;
      lastDoc = usersSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (usersSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print(
          '📦 Processed $totalProcessed users for validation (batch: ${usersSnapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print(
        '✅ Found $cleanedCount invalid user records (not deleted - uncomment to delete)');
    return cleanedCount;
  }

  /// MEMORY-SAFE helper method to remove team references from all users in batches
  Future<void> _removeTeamReferencesFromAllUsers(
      String teamName, String teamId) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalProcessed = 0;
    int updatedCount = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('users')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final usersSnapshot = await query.get();

      if (usersSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      final batch = _firestore.batch();
      int batchUpdates = 0;

      // Process this batch of users
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData == null) continue;

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Remove from team field
        if (userData['team'] == teamName) {
          updates['team'] = null;
          needsUpdate = true;
        }

        // Remove from team_ids
        if (userData['team_ids'] != null && userData['team_ids'] is List) {
          final teamIds = List<String>.from(userData['team_ids']);
          if (teamIds.contains(teamId)) {
            teamIds.remove(teamId);
            updates['team_ids'] = teamIds;
            needsUpdate = true;
          }
        }

        // Remove from assigned_teams
        if (userData['assigned_teams'] != null &&
            userData['assigned_teams'] is List) {
          final assignedTeams = List<String>.from(userData['assigned_teams']);
          if (assignedTeams.contains(teamName)) {
            assignedTeams.remove(teamName);
            updates['assigned_teams'] = assignedTeams;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          batch.update(userDoc.reference, updates);
          batchUpdates++;
          updatedCount++;
        }
      }

      // Commit batch updates if any
      if (batchUpdates > 0) {
        await batch.commit();
      }

      totalProcessed += usersSnapshot.docs.length;
      lastDoc = usersSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (usersSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print(
          '📦 Processed $totalProcessed users for team removal (batch: ${usersSnapshot.docs.length}, updated: $updatedCount)');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Removed team references from $updatedCount users');
  }

  /// MEMORY-SAFE helper method to remove user references from all teams in batches
  Future<void> _removeUserReferencesFromAllTeams(String userId) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalProcessed = 0;
    int updatedCount = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('teams')
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final teamsSnapshot = await query.get();

      if (teamsSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      final batch = _firestore.batch();
      int batchUpdates = 0;

      // Process this batch of teams
      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data() as Map<String, dynamic>?;
        if (teamData == null) continue;

        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        // Remove from coach_ids
        if (teamData['coach_ids'] != null && teamData['coach_ids'] is List) {
          final coachIds = List<String>.from(teamData['coach_ids']);
          if (coachIds.contains(userId)) {
            coachIds.remove(userId);
            updates['coach_ids'] = coachIds;
            needsUpdate = true;
          }
        }

        // Remove from single coach field
        if (teamData['coach'] == userId) {
          final remainingCoaches =
              updates['coach_ids'] ?? teamData['coach_ids'] ?? [];
          updates['coach'] =
              remainingCoaches.isNotEmpty ? remainingCoaches[0] : null;
          needsUpdate = true;
        }

        // Remove from coaches array
        if (teamData['coaches'] != null && teamData['coaches'] is List) {
          final coaches = teamData['coaches'] as List<dynamic>;
          final filteredCoaches = coaches.where((coach) {
            if (coach is Map<String, dynamic>) {
              return coach['userId'] != userId;
            }
            return true;
          }).toList();

          if (filteredCoaches.length != coaches.length) {
            updates['coaches'] = filteredCoaches;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          updates['updated_at'] = FieldValue.serverTimestamp();
          batch.update(teamDoc.reference, updates);
          batchUpdates++;
          updatedCount++;
        }
      }

      // Commit batch updates if any
      if (batchUpdates > 0) {
        await batch.commit();
      }

      totalProcessed += teamsSnapshot.docs.length;
      lastDoc = teamsSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (teamsSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print(
          '📦 Processed $totalProcessed teams for user removal (batch: ${teamsSnapshot.docs.length}, updated: $updatedCount)');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Removed user references from $updatedCount teams');
  }

  /// MEMORY-SAFE helper method to delete players in batches
  Future<void> _deletePlayersInBatches(String teamName) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalDeleted = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('players')
          .where('team', isEqualTo: teamName)
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final playersSnapshot = await query.get();

      if (playersSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Create a new batch for this set of deletions
      final batch = _firestore.batch();
      for (final playerDoc in playersSnapshot.docs) {
        batch.delete(playerDoc.reference);
      }

      // Commit this batch
      await batch.commit();

      totalDeleted += playersSnapshot.docs.length;
      lastDoc = playersSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (playersSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Deleted $totalDeleted players (batch: ${playersSnapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Deleted $totalDeleted players total');
  }

  /// MEMORY-SAFE helper method to delete training sessions in batches
  Future<void> _deleteTrainingSessionsInBatches(String teamName) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalDeleted = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('training_sessions')
          .where('team', isEqualTo: teamName)
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final sessionsSnapshot = await query.get();

      if (sessionsSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Create a new batch for this set of deletions
      final batch = _firestore.batch();
      for (final sessionDoc in sessionsSnapshot.docs) {
        batch.delete(sessionDoc.reference);
      }

      // Commit this batch
      await batch.commit();

      totalDeleted += sessionsSnapshot.docs.length;
      lastDoc = sessionsSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (sessionsSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Deleted $totalDeleted training sessions (batch: ${sessionsSnapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Deleted $totalDeleted training sessions total');
  }

  /// MEMORY-SAFE helper method to delete training sessions by coach in batches
  Future<void> _deleteTrainingSessionsByCoach(String coachId) async {
    QueryDocumentSnapshot? lastDoc;
    bool hasMore = true;
    int totalDeleted = 0;

    while (hasMore) {
      Query query = _firestore
          .collection('training_sessions')
          .where('coach_uid', isEqualTo: coachId)
          .limit(BatchSizeConstants.cleanupBatchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final sessionsSnapshot = await query.get();

      if (sessionsSnapshot.docs.isEmpty) {
        hasMore = false;
        break;
      }

      // Create a new batch for this set of deletions
      final batch = _firestore.batch();
      for (final sessionDoc in sessionsSnapshot.docs) {
        batch.delete(sessionDoc.reference);
      }

      // Commit this batch
      await batch.commit();

      totalDeleted += sessionsSnapshot.docs.length;
      lastDoc = sessionsSnapshot.docs.last;

      // Safety check to prevent infinite loops
      if (sessionsSnapshot.docs.length < BatchSizeConstants.cleanupBatchSize) {
        hasMore = false;
      }

      print('📦 Deleted $totalDeleted training sessions by coach (batch: ${sessionsSnapshot.docs.length})');

      // Memory safety: Small delay to prevent overwhelming Firestore
      await Future.delayed(const Duration(milliseconds: 100));
    }

    print('✅ Deleted $totalDeleted training sessions by coach $coachId');
  }

  // 🚀 PROPER DELETION METHODS - Use these for future deletions

  // Properly delete a team and clean all references
  Future<void> deleteTeamProperly(String teamId) async {
    print('🗑️  Properly deleting team: $teamId');

    try {
      // 1. Get team data first
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data()!;
      final teamName = teamData['team_name'];

      // 2. Remove team references from all users (MEMORY-SAFE: use batches)
      await _removeTeamReferencesFromAllUsers(teamName, teamId);

      // 3. Delete related data (players, training sessions) using batch operations

      // Delete players in batches to avoid memory issues
      await _deletePlayersInBatches(teamName);

      // Delete training sessions in batches to avoid memory issues
      await _deleteTrainingSessionsInBatches(teamName);

      // 4. Delete the team itself
      await teamDoc.reference.delete();

      print('✅ Team deleted properly with all references cleaned');
    } catch (e) {
      print('❌ Error deleting team properly: $e');
      rethrow;
    }
  }

  // Properly delete a user and clean all references
  Future<void> deleteUserProperly(String userId) async {
    print('🗑️  Properly deleting user: $userId');

    try {
      // 1. Get user data first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final userEmail = userData['email'];

      // 2. Remove user from all team coach assignments (MEMORY-SAFE: use batches)
      await _removeUserReferencesFromAllTeams(userId);

      // 3. Delete related data (training sessions by this coach) - MEMORY-SAFE
      await _deleteTrainingSessionsByCoach(userId);

      // 4. Delete the user from Firestore
      await userDoc.reference.delete();

      // 5. Delete from Firebase Auth (if possible)
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email == userEmail) {
          print('⚠️  Cannot delete currently logged in user from Auth');
        } else {
          print(
              '💡 Note: Delete user $userEmail from Firebase Auth manually in console');
        }
      } catch (e) {
        print('⚠️  Could not delete from Auth: $e');
      }

      print('✅ User deleted properly with all references cleaned');
    } catch (e) {
      print('❌ Error deleting user properly: $e');
      rethrow;
    }
  }

  // Properly assign coach to team
  Future<void> assignCoachToTeamProperly(
      String coachId, String teamId, String role) async {
    print(
        '👨‍🏫 Properly assigning coach $coachId to team $teamId with role $role');

    try {
      final batch = _firestore.batch();

      // 1. Update team with coach
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data()!;

      // Update coach_ids array
      final coachIds = List<String>.from(teamData['coach_ids'] ?? []);
      if (!coachIds.contains(coachId)) {
        coachIds.add(coachId);
      }

      // Update coaches array
      final coaches = List<Map<String, dynamic>>.from(
          (teamData['coaches'] ?? []).map((c) => Map<String, dynamic>.from(c)));

      // Remove existing assignment for this coach
      coaches.removeWhere((c) => c['userId'] == coachId);

      // Add new assignment
      coaches.add({
        'userId': coachId,
        'role': role,
        'assignedAt': Timestamp.now(),
        'assignedBy': _auth.currentUser?.uid ?? 'system',
        'isActive': true,
      });

      batch.update(teamRef, {
        'coach_ids': coachIds,
        'coaches': coaches,
        'coach': coachIds.isNotEmpty
            ? coachIds.first
            : null, // For backward compatibility
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Update user with team assignment
      final userRef = _firestore.collection('users').doc(coachId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw Exception('Coach not found');
      }

      final userData = userDoc.data()!;
      final teamName = teamData['team_name'];

      // Update team_ids
      final userTeamIds = List<String>.from(userData['team_ids'] ?? []);
      if (!userTeamIds.contains(teamId)) {
        userTeamIds.add(teamId);
      }

      // Update assigned_teams
      final assignedTeams = List<String>.from(userData['assigned_teams'] ?? []);
      if (!assignedTeams.contains(teamName)) {
        assignedTeams.add(teamName);
      }

      batch.update(userRef, {
        'team_ids': userTeamIds,
        'assigned_teams': assignedTeams,
        'team': teamName, // For backward compatibility
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Commit all changes
      await batch.commit();

      print('✅ Coach assigned properly with bidirectional references');
    } catch (e) {
      print('❌ Error assigning coach properly: $e');
      rethrow;
    }
  }
}

// Widget to run cleanup from your app
class CleanupButton extends StatefulWidget {
  const CleanupButton({super.key});

  @override
  State<CleanupButton> createState() => _CleanupButtonState();
}

class _CleanupButtonState extends State<CleanupButton> {
  final DataCleanupUtility _cleanup = DataCleanupUtility();
  bool _isRunning = false;
  Map<String, dynamic>? _results;

  Future<void> _runCleanup() async {
    setState(() {
      _isRunning = true;
      _results = null;
    });

    try {
      final results = await _cleanup.cleanupOrphanedData();
      setState(() {
        _results = results;
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _results = {'error': e.toString()};
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isRunning ? null : _runCleanup,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isRunning
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Cleaning...'),
                  ],
                )
              : Text('🧹 Clean Orphaned Data'),
        ),
        if (_results != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cleanup Results:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ..._results!.entries.map((entry) {
                  return Text('${entry.key}: ${entry.value}');
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// 4. In your ReceptionistScreen build method, add the CleanupButton widget
// Find your main Column or ListView in the receptionist screen and add:

Widget build(BuildContext context) {
  return Scaffold(
    // ... your existing app bar
    body: SingleChildScrollView(
      child: Column(
        children: [
          // ... your existing widgets (payment overview, etc.)

          // ADD THIS CLEANUP BUTTON HERE:
          CleanupButton(),

          // ... rest of your existing widgets
        ],
      ),
    ),
  );
}
