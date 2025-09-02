import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/services/logging_service.dart';

class TeamDataFixerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fix team coach assignments by ensuring consistent data structure
  Future<Map<String, dynamic>> fixTeamCoachAssignments() async {
    final results = {
      'teamsChecked': 0,
      'teamsFixed': 0,
      'errors': <String>[],
      'fixedTeams': <String>[],
    };

    try {
      // Get all teams
      final teamsSnapshot = await _firestore.collection('teams').get();
      results['teamsChecked'] = teamsSnapshot.docs.length;
      LoggingService.info(
          '🔍 Checking ${teamsSnapshot.docs.length} teams for coach assignment issues');

      for (final doc in teamsSnapshot.docs) {
        try {
          final teamId = doc.id;
          final data = doc.data();
          final teamName = data['team_name'] ?? 'Unknown Team';
          bool needsFix = false;

          LoggingService.info('Checking team: $teamName (ID: $teamId)');
          final updateData = <String, dynamic>{};

          // Check coach data structures
          final coachesArray = data['coaches'] ?? [];
          final coachIdsArray = data['coach_ids'] ?? [];
          final mainCoach = data['coach'];

          // Normalize coaches array
          if (coachesArray is List) {
            final normalizedCoaches = <Map<String, dynamic>>[];
            final normalizedCoachIds = <String>[];

            for (var coachEntry in coachesArray) {
              if (coachEntry is String) {
                // Convert string to proper coach object
                normalizedCoaches.add({
                  'userId': coachEntry,
                  'role': 'coach',
                  'assignedAt': Timestamp.now(),
                  'assignedBy': 'system_fix',
                  'isActive': true,
                });
                normalizedCoachIds.add(coachEntry);
                needsFix = true;
              } else if (coachEntry is Map<String, dynamic>) {
                // Normalize keys
                final userId = coachEntry['userId'] ??
                    coachEntry['user_id'] ??
                    coachEntry['coach_id'] ??
                    coachEntry['coachId'];

                if (userId != null) {
                  final normalizedCoach = {
                    'userId': userId,
                    'role': coachEntry['role'] ?? 'coach',
                    'assignedAt': coachEntry['assignedAt'] ??
                        coachEntry['assigned_at'] ??
                        Timestamp.now(),
                    'assignedBy': coachEntry['assignedBy'] ??
                        coachEntry['assigned_by'] ??
                        'system_fix',
                    'isActive': coachEntry['isActive'] ??
                        coachEntry['is_active'] ??
                        true,
                  };

                  normalizedCoaches.add(normalizedCoach);
                  if (normalizedCoach['isActive'] == true) {
                    normalizedCoachIds.add(userId);
                  }

                  // Check if anything changed
                  if (coachEntry['userId'] != userId ||
                      !coachEntry.containsKey('isActive') ||
                      !coachEntry.containsKey('assignedAt')) {
                    needsFix = true;
                  }
                }
              }
            }

            if (normalizedCoaches.isNotEmpty && needsFix) {
              updateData['coaches'] = normalizedCoaches;
            }

            // Check coach_ids consistency
            final List<String> existingCoachIds =
                List<String>.from(coachIdsArray);
            if (!_areListsEqual(existingCoachIds, normalizedCoachIds)) {
              updateData['coach_ids'] = normalizedCoachIds;
              needsFix = true;
            }

            // Check main coach consistency
            if (mainCoach == null && normalizedCoachIds.isNotEmpty) {
              updateData['coach'] = normalizedCoachIds[0];
              needsFix = true;
            }
          }

          // Apply fixes if needed
          if (needsFix && updateData.isNotEmpty) {
            await _firestore.collection('teams').doc(teamId).update(updateData);
            results['teamsFixed'] = (results['teamsFixed'] as int) + 1;
            (results['fixedTeams'] as List<String>).add(teamName);
            LoggingService.info(
                '✅ Fixed coach assignments for team: $teamName');
          }
        } catch (e) {
          final errorMsg = 'Error fixing team ${doc.id}: $e';
          LoggingService.error(errorMsg);
          (results['errors'] as List<String>).add(errorMsg);
        }
      }
    } catch (e) {
      LoggingService.error('❌ Error in fixTeamCoachAssignments: $e');
      (results['errors'] as List<String>).add(e.toString());
    }

    return results;
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;

    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);

    return set1.difference(set2).isEmpty && set2.difference(set1).isEmpty;
  }

  // Fix specific team's coach assignments
  Future<bool> fixTeamCoachAssignmentsById(String teamId) async {
    try {
      final teamDoc = await _firestore.collection('teams').doc(teamId).get();
      if (!teamDoc.exists) {
        LoggingService.error('Team not found: $teamId');
        return false;
      }

      final data = teamDoc.data()!;
      final teamName = data['team_name'] ?? 'Unknown Team';
      bool needsFix = false;

      LoggingService.info('Fixing team: $teamName (ID: $teamId)');
      final updateData = <String, dynamic>{};

      // Check coach data structures
      final coachesArray = data['coaches'] ?? [];
      final coachIdsArray = data['coach_ids'] ?? [];

      // Normalize coaches array
      if (coachesArray is List) {
        final normalizedCoaches = <Map<String, dynamic>>[];
        final normalizedCoachIds = <String>[];

        for (var coachEntry in coachesArray) {
          if (coachEntry is String) {
            // Convert string to proper coach object
            normalizedCoaches.add({
              'userId': coachEntry,
              'role': 'coach',
              'assignedAt': Timestamp.now(),
              'assignedBy': 'system_fix',
              'isActive': true,
            });
            normalizedCoachIds.add(coachEntry);
            needsFix = true;
          } else if (coachEntry is Map<String, dynamic>) {
            // Normalize keys
            final userId = coachEntry['userId'] ??
                coachEntry['user_id'] ??
                coachEntry['coach_id'] ??
                coachEntry['coachId'];

            if (userId != null) {
              final normalizedCoach = {
                'userId': userId,
                'role': coachEntry['role'] ?? 'coach',
                'assignedAt': coachEntry['assignedAt'] ??
                    coachEntry['assigned_at'] ??
                    Timestamp.now(),
                'assignedBy': coachEntry['assignedBy'] ??
                    coachEntry['assigned_by'] ??
                    'system_fix',
                'isActive':
                    coachEntry['isActive'] ?? coachEntry['is_active'] ?? true,
              };

              normalizedCoaches.add(normalizedCoach);
              if (normalizedCoach['isActive'] == true) {
                normalizedCoachIds.add(userId);
              }

              // Check if anything changed
              if (coachEntry['userId'] != userId ||
                  !coachEntry.containsKey('isActive') ||
                  !coachEntry.containsKey('assignedAt')) {
                needsFix = true;
              }
            }
          }
        }

        if (normalizedCoaches.isNotEmpty) {
          updateData['coaches'] = normalizedCoaches;
        }

        // Check coach_ids consistency
        final List<String> existingCoachIds = List<String>.from(coachIdsArray);
        if (!_areListsEqual(existingCoachIds, normalizedCoachIds)) {
          updateData['coach_ids'] = normalizedCoachIds;
          needsFix = true;
        }

        // Add main coach if missing
        if (data['coach'] == null && normalizedCoachIds.isNotEmpty) {
          updateData['coach'] = normalizedCoachIds[0];
          needsFix = true;
        }
      }

      // Apply fixes if needed
      if (needsFix && updateData.isNotEmpty) {
        await _firestore.collection('teams').doc(teamId).update(updateData);
        LoggingService.info('✅ Fixed coach assignments for team: $teamName');
        return true;
      }

      return false;
    } catch (e) {
      LoggingService.error('❌ Error fixing team $teamId: $e');
      return false;
    }
  }
}

// UI Widget for fixing team data
class TeamDataFixerWidget extends StatefulWidget {
  const TeamDataFixerWidget({super.key});

  @override
  State<TeamDataFixerWidget> createState() => _TeamDataFixerWidgetState();
}

class _TeamDataFixerWidgetState extends State<TeamDataFixerWidget> {
  final TeamDataFixerService _fixerService = TeamDataFixerService();
  bool _isFixing = false;
  Map<String, dynamic>? _results;
  String? _error;

  Future<void> _fixAllTeams() async {
    setState(() {
      _isFixing = true;
      _error = null;
      _results = null;
    });

    try {
      final results = await _fixerService.fixTeamCoachAssignments();
      setState(() {
        _results = results;
        _isFixing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Data Fixer'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fix Team Coach Assignments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'This tool will fix inconsistencies in team coach assignments data structure. '
              'Use this if coaches cannot see their assigned teams or if teams are not showing '
              'their coaches correctly.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isFixing ? null : _fixAllTeams,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              child: _isFixing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Fixing Teams...'),
                      ],
                    )
                  : const Text('Fix All Teams'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_error!),
                  ],
                ),
              ),
            if (_results != null) ...[
              const SizedBox(height: 24),
              Text(
                'Results:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teams Checked: ${_results!['teamsChecked']}'),
                    Text('Teams Fixed: ${_results!['teamsFixed']}'),
                    const SizedBox(height: 16),
                    if ((_results!['fixedTeams'] as List).isNotEmpty) ...[
                      const Text(
                        'Fixed Teams:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_results!['fixedTeams'] as List)
                          .map((team) => Text('• $team')),
                    ],
                    if ((_results!['errors'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Errors:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_results!['errors'] as List).map(
                        (error) => Text(
                          '• $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
