import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/enhanced_models.dart';

/// Production-Ready Assignment Management Service
class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'system';

  /// Assign coach to team (bidirectional update)
  Future<void> assignCoachToTeam({
    required String coachId,
    required String coachName,
    required String teamId,
    required String teamName,
    required String role,
  }) async {
    final batch = _firestore.batch();
    final assignedAt = DateTime.now();

    try {
      // 1. Update Users Collection - Add team assignment
      final userRef = _firestore.collection('users').doc(coachId);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) {
        throw Exception('Coach not found');
      }

      final userData = userDoc.data()!;
      final currentTeams = List<Map<String, dynamic>>.from(userData['teams'] ?? []);
      
      // Check if already assigned
      final existingIndex = currentTeams.indexWhere(
        (team) => team['team_id'] == teamId,
      );

      final newAssignment = TeamAssignment(
        teamId: teamId,
        teamName: teamName,
        role: role,
        assignedAt: assignedAt,
        assignedBy: _currentUserId,
        isActive: true,
      );

      if (existingIndex >= 0) {
        // Update existing assignment
        currentTeams[existingIndex] = newAssignment.toFirestore();
      } else {
        // Add new assignment
        currentTeams.add(newAssignment.toFirestore());
      }

      batch.update(userRef, {
        'teams': currentTeams,
        'team_count': currentTeams.where((t) => t['is_active'] == true).length,
        'primary_team': currentTeams.isNotEmpty ? currentTeams.first['team_name'] : null,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Update Teams Collection - Add coach assignment
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();
      
      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      final teamData = teamDoc.data()!;
      final currentCoaches = List<Map<String, dynamic>>.from(teamData['coaches'] ?? []);
      
      // Check if coach already assigned to team
      final existingCoachIndex = currentCoaches.indexWhere(
        (coach) => coach['coach_id'] == coachId || coach['userId'] == coachId,
      );

      final newCoachAssignment = CoachAssignment(
        coachId: coachId,
        coachName: coachName,
        role: role,
        assignedAt: assignedAt,
        assignedBy: _currentUserId,
        isActive: true,
      );

      if (existingCoachIndex >= 0) {
        // Update existing coach assignment
        currentCoaches[existingCoachIndex] = newCoachAssignment.toFirestore();
      } else {
        // Add new coach assignment
        currentCoaches.add(newCoachAssignment.toFirestore());
      }

      // Find primary coach for backwards compatibility
      final activeCoaches = currentCoaches.where((c) => c['is_active'] != false).toList();
      final primaryCoach = activeCoaches.isNotEmpty ? activeCoaches.first['coach_id'] : null;

      batch.update(teamRef, {
        'coaches': currentCoaches,
        'coach_count': activeCoaches.length,
        'primary_coach': primaryCoach,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 3. Commit all changes atomically
      await batch.commit();

    } catch (e) {
      throw Exception('Failed to assign coach to team: $e');
    }
  }

  /// Remove coach from team (bidirectional update)
  Future<void> removeCoachFromTeam({
    required String coachId,
    required String teamId,
  }) async {
    final batch = _firestore.batch();

    try {
      // 1. Update Users Collection - Remove team assignment
      final userRef = _firestore.collection('users').doc(coachId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentTeams = List<Map<String, dynamic>>.from(userData['teams'] ?? []);
        
        // Mark team assignment as inactive
        final updatedTeams = currentTeams.map((team) {
          if (team['team_id'] == teamId) {
            return {...team, 'is_active': false};
          }
          return team;
        }).toList();

        final activeTeams = updatedTeams.where((t) => t['is_active'] == true).toList();

        batch.update(userRef, {
          'teams': updatedTeams,
          'team_count': activeTeams.length,
          'primary_team': activeTeams.isNotEmpty ? activeTeams.first['team_name'] : null,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 2. Update Teams Collection - Remove coach assignment
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();
      
      if (teamDoc.exists) {
        final teamData = teamDoc.data()!;
        final currentCoaches = List<Map<String, dynamic>>.from(teamData['coaches'] ?? []);
        
        // Mark coach as inactive
        final updatedCoaches = currentCoaches.map((coach) {
          if (coach['coach_id'] == coachId || coach['userId'] == coachId) {
            return {...coach, 'is_active': false};
          }
          return coach;
        }).toList();

        final activeCoaches = updatedCoaches.where((c) => c['is_active'] != false).toList();
        final primaryCoach = activeCoaches.isNotEmpty ? activeCoaches.first['coach_id'] : null;

        batch.update(teamRef, {
          'coaches': updatedCoaches,
          'coach_count': activeCoaches.length,
          'primary_coach': primaryCoach,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // 3. Commit changes
      await batch.commit();

    } catch (e) {
      throw Exception('Failed to remove coach from team: $e');
    }
  }

  /// Update coach role in team
  Future<void> updateCoachRole({
    required String coachId,
    required String teamId,
    required String newRole,
  }) async {
    final batch = _firestore.batch();

    try {
      // Update Users Collection
      final userRef = _firestore.collection('users').doc(coachId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentTeams = List<Map<String, dynamic>>.from(userData['teams'] ?? []);
        
        final updatedTeams = currentTeams.map((team) {
          if (team['team_id'] == teamId) {
            return {...team, 'role': newRole};
          }
          return team;
        }).toList();

        batch.update(userRef, {
          'teams': updatedTeams,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      // Update Teams Collection
      final teamRef = _firestore.collection('teams').doc(teamId);
      final teamDoc = await teamRef.get();
      
      if (teamDoc.exists) {
        final teamData = teamDoc.data()!;
        final currentCoaches = List<Map<String, dynamic>>.from(teamData['coaches'] ?? []);
        
        final updatedCoaches = currentCoaches.map((coach) {
          if (coach['coach_id'] == coachId || coach['userId'] == coachId) {
            return {...coach, 'role': newRole};
          }
          return coach;
        }).toList();

        batch.update(teamRef, {
          'coaches': updatedCoaches,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

    } catch (e) {
      throw Exception('Failed to update coach role: $e');
    }
  }

  /// Get all available coaches for assignment
  Stream<List<Map<String, dynamic>>> getAvailableCoaches() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'team_count': data['team_count'] ?? 0,
          'teams': data['teams'] ?? [],
        };
      }).toList();
    });
  }

  /// Validate assignment operation
  Future<bool> canAssignCoachToTeam(String coachId, String teamId) async {
    try {
      // Check if coach exists and is active
      final coachDoc = await _firestore.collection('users').doc(coachId).get();
      if (!coachDoc.exists) return false;
      
      final coachData = coachDoc.data()!;
      if (coachData['role'] != 'coach' || coachData['is_active'] != true) {
        return false;
      }

      // Check if team exists
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) return false;

      return true;
    } catch (e) {
      return false;
    }
  }
}