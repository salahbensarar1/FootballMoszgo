// Add this to your receptionist_screen.dart file

// 1. First, add these imports at the top of your receptionist screen file:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/organization_context.dart';

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

    // Get all teams to check against
    final teamsSnapshot = await _firestore.collection('teams').get();
    final existingTeamIds = teamsSnapshot.docs.map((doc) => doc.id).toSet();
    final existingTeamNames = teamsSnapshot.docs
        .map((doc) => doc.data()['team_name'] as String?)
        .where((name) => name != null)
        .cast<String>()
        .toSet();

    // Get all users
    final usersSnapshot = await _firestore.collection('users').get();
    int cleanedCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
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
              '🗑️  Removing invalid team reference: $teamRef from user ${userData['name']}');
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
              '🗑️  Cleaning team_ids for user ${userData['name']}: ${teamIds.length} -> ${validTeamIds.length}');
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
              '🗑️  Cleaning assigned_teams for user ${userData['name']}: ${assignedTeams.length} -> ${validTeams.length}');
        }
      }

      if (needsUpdate) {
        updates['updated_at'] = FieldValue.serverTimestamp();
        await userDoc.reference.update(updates);
        cleanedCount++;
      }
    }

    print('✅ Cleaned $cleanedCount users with orphaned team references');
    return cleanedCount;
  }

  // Clean invalid coach assignments in teams
  Future<int> _cleanInvalidCoachAssignments() async {
    print('🔍 Cleaning invalid coach assignments in teams...');

    // Get all users to check against
    final usersSnapshot = await _firestore.collection('users').get();
    final existingUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();

    // Get all teams
    final teamsSnapshot = await _firestore.collection('teams').get();
    int fixedCount = 0;

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();
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
              '🗑️  Cleaning coach_ids for team ${teamData['team_name']}: ${coachIds.length} -> ${validCoachIds.length}');
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
              '🗑️  Removing invalid coach reference: $coachId from team ${teamData['team_name']}');
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
              '🗑️  Cleaning coaches array for team ${teamData['team_name']}: ${coaches.length} -> ${validCoaches.length}');
        }
      }

      if (needsUpdate) {
        updates['updated_at'] = FieldValue.serverTimestamp();
        await teamDoc.reference.update(updates);
        fixedCount++;
      }
    }

    print('✅ Fixed $fixedCount teams with invalid coach assignments');
    return fixedCount;
  }

  // Find users in Firebase Auth that don't exist in Firestore
  Future<int> _findAuthenticationOrphans() async {
    print('🔍 Finding authentication orphans...');

    // Get all Firestore users
    final usersSnapshot = await _firestore.collection('users').get();
    final firestoreEmails = usersSnapshot.docs
        .map((doc) => doc.data()['email'] as String?)
        .where((email) => email != null)
        .cast<String>()
        .toSet();

    print('📊 Found ${firestoreEmails.length} users in Firestore');
    print('⚠️  Note: Firebase Auth user enumeration requires Admin SDK');
    print('💡 Suggestion: Use Firebase Console to manually clean auth orphans');

    return 0; // Can't enumerate auth users with client SDK
  }

  // Clean users that have invalid data
  Future<int> _cleanOrphanedUsers() async {
    print('🔍 Cleaning orphaned user records...');

    final usersSnapshot = await _firestore.collection('users').get();
    int cleanedCount = 0;

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();

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

    print(
        '✅ Found $cleanedCount invalid user records (not deleted - uncomment to delete)');
    return cleanedCount;
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

      // 2. Remove team references from all users
      final usersSnapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
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
        }
      }

      // 3. Delete related data (players, training sessions)
      final playersQuery = await _firestore
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('players')
          .where('team', isEqualTo: teamName)
          .get();

      for (final playerDoc in playersQuery.docs) {
        batch.delete(playerDoc.reference);
      }

      final sessionsQuery = await _firestore
          .collection('training_sessions')
          .where('team', isEqualTo: teamName)
          .get();

      for (final sessionDoc in sessionsQuery.docs) {
        batch.delete(sessionDoc.reference);
      }

      // 4. Delete the team itself
      batch.delete(teamDoc.reference);

      // 5. Commit all changes
      await batch.commit();

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

      // 2. Remove user from all team coach assignments
      final teamsSnapshot = await _firestore.collection('teams').get();
      final batch = _firestore.batch();

      for (final teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data();
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
        }
      }

      // 3. Delete related data (training sessions by this coach)
      final sessionsQuery = await _firestore
          .collection('training_sessions')
          .where('coach_uid', isEqualTo: userId)
          .get();

      for (final sessionDoc in sessionsQuery.docs) {
        batch.delete(sessionDoc.reference);
      }

      // 4. Delete the user from Firestore
      batch.delete(userDoc.reference);

      // 5. Commit Firestore changes
      await batch.commit();

      // 6. Delete from Firebase Auth (if possible)
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
  @override
  _CleanupButtonState createState() => _CleanupButtonState();
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
