import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/data/models/enhanced_models.dart';
import 'package:footballtraining/data/models/user_model.dart' as user_model;

/// Production-Ready Coach Dashboard Service
class CoachDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get real-time coach dashboard data
  Stream<CoachDashboardData> getCoachDashboard(String coachId) {
    return _getCoachTeams(coachId).asyncMap((teams) async {
      return CoachDashboardData(
        coachId: coachId,
        assignedTeams: teams,
        teamPlayers: [],
        recentSessions: [],
      );
    });
  }

  /// Get coach's assigned teams (real-time)
  Stream<List<TeamAssignment>> _getCoachTeams(String coachId) {
    return _firestore
        .collection('users')
        .doc(coachId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <TeamAssignment>[];
      
      final data = doc.data()!;
      final teamsData = data['teams'] as List<dynamic>? ?? [];
      
      return teamsData
          .map((team) => TeamAssignment.fromFirestore(team as Map<String, dynamic>))
          .where((team) => team.isActive)
          .toList();
    });
  }

  /// Get players for specific team (real-time)
  Stream<List<PlayerAttendance>> getTeamPlayers(String teamName) {
    return _firestore
        .collection('players')
        .where('team', isEqualTo: teamName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PlayerAttendance(
          playerId: doc.id,
          playerName: data['name'] ?? '',
          present: false, // Default for new session
        );
      }).toList();
    });
  }

  /// Get recent training sessions for team
  Stream<List<TrainingSession>> getTeamSessions(String teamName, {int limit = 10}) {
    return _firestore
        .collection('training_sessions')
        .where('team_name', isEqualTo: teamName)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TrainingSession.fromFirestore(doc))
          .toList();
    });
  }

  /// Create new training session
  Future<String> createTrainingSession(TrainingSession session) async {
    try {
      final docRef = await _firestore
          .collection('training_sessions')
          .add(session.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create training session: $e');
    }
  }

  /// Update training session attendance
  Future<void> updateSessionAttendance(
    String sessionId,
    List<PlayerAttendance> updatedPlayers,
  ) async {
    try {
      await _firestore
          .collection('training_sessions')
          .doc(sessionId)
          .update({
        'players': updatedPlayers.map((p) => p.toFirestore()).toList(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  /// Real-time attendance updates during session
  Stream<List<PlayerAttendance>> getSessionAttendance(String sessionId) {
    return _firestore
        .collection('training_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return <PlayerAttendance>[];
      
      final data = doc.data()!;
      final playersData = data['players'] as List<dynamic>? ?? [];
      
      return playersData
          .map((p) => PlayerAttendance.fromFirestore(p as Map<String, dynamic>))
          .toList();
    });
  }

  /// Get coach profile with team assignments
  Future<user_model.User?> getCoachProfile(String coachId) async {
    try {
      final doc = await _firestore.collection('users').doc(coachId).get();
      return doc.exists ? user_model.User.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get coach profile: $e');
    }
  }

  /// Validate coach has access to team
  Future<bool> validateCoachTeamAccess(String coachId, String teamName) async {
    try {
      final teams = await _getCoachTeams(coachId).first;
      return teams.any((team) => team.teamName == teamName && team.isActive);
    } catch (e) {
      return false;
    }
  }
}