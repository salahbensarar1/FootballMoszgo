import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Professional data migration button for admin interface
/// Safely moves global collections to organization scope
class DataMigrationButton extends StatefulWidget {
  const DataMigrationButton({super.key});

  @override
  State<DataMigrationButton> createState() => _DataMigrationButtonState();
}

class _DataMigrationButtonState extends State<DataMigrationButton> {
  bool _isLoading = false;
  String? _status;
  bool _showConfirmation = false;
  Map<String, int>? _analysisResults;

  static const String targetOrgId = 'UYM9gTWj8o2HgEcOFpsG'; // Nagykoros
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.move_up_rounded, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Migration to Organization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Move global collections to secure organization scope',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_status != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status!.contains('❌') ? Colors.red.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status!.contains('❌') ? Colors.red.shade200 : Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  _status!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],

            const SizedBox(height: 16),

            if (!_showConfirmation) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isLoading ? 'Analyzing...' : 'Analyze Migration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            ] else ...[
              // Confirmation section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'MIGRATION CONFIRMATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_analysisResults != null) ...[
                      Text('Will migrate:'),
                      Text('• ${_analysisResults!['globalPlayers']} players with payments'),
                      Text('• ${_analysisResults!['globalSessions']} training sessions'),
                      Text('• Into organization: $targetOrgId'),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'This will move global data to organization scope. Original data stays until you manually delete it.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _executeMigration,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(_isLoading ? 'Migrating...' : 'Execute Migration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      setState(() {
                        _showConfirmation = false;
                        _status = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeData() async {
    setState(() {
      _isLoading = true;
      _status = 'Analyzing current database structure...';
    });

    try {
      LoggingService.info('🔍 Starting data migration analysis');

      // Check global collections
      final globalPlayers = await _firestore.collection('players').get();
      final globalSessions = await _firestore.collection('training_sessions').get();

      // Check organization collections
      final orgPlayers = await _firestore
          .collection('organizations')
          .doc(targetOrgId)
          .collection('players')
          .get();

      final orgSessions = await _firestore
          .collection('organizations')
          .doc(targetOrgId)
          .collection('training_sessions')
          .get();

      // Count players with payments
      int playersWithPayments = 0;
      for (final playerDoc in globalPlayers.docs) {
        final payments = await playerDoc.reference.collection('payments').get();
        if (payments.docs.isNotEmpty) {
          playersWithPayments++;
        }
      }

      _analysisResults = {
        'globalPlayers': globalPlayers.docs.length,
        'globalSessions': globalSessions.docs.length,
        'orgPlayers': orgPlayers.docs.length,
        'orgSessions': orgSessions.docs.length,
        'playersWithPayments': playersWithPayments,
      };

      setState(() {
        _isLoading = false;
        _status = '''Analysis Complete:
Global Collections:
• ${globalPlayers.docs.length} players ($playersWithPayments with payments)
• ${globalSessions.docs.length} training sessions

Organization ($targetOrgId):
• ${orgPlayers.docs.length} existing players
• ${orgSessions.docs.length} existing training sessions

Migration Required: ${globalPlayers.docs.length > 0 || globalSessions.docs.length > 0 ? 'YES' : 'NO'}''';
        _showConfirmation = globalPlayers.docs.length > 0 || globalSessions.docs.length > 0;
      });

      if (!_showConfirmation) {
        _showSuccessMessage('No migration needed - all data already in organization scope');
      }

    } catch (e) {
      LoggingService.error('Migration analysis failed', e);
      setState(() {
        _isLoading = false;
        _status = '❌ Analysis failed: $e';
      });
      _showErrorMessage('Failed to analyze database: $e');
    }
  }

  Future<void> _executeMigration() async {
    setState(() {
      _isLoading = true;
      _status = 'Executing migration... This may take a few moments.';
    });

    try {
      LoggingService.info('🚀 Starting data migration execution');

      // Migrate players with payments
      await _migratePlayersWithPayments();

      // Migrate training sessions
      await _migrateTrainingSessions();

      // Verify migration
      await _verifyMigration();

      setState(() {
        _isLoading = false;
        _showConfirmation = false;
        _status = '✅ Migration completed successfully!\n\n'
            '${_analysisResults!['globalPlayers']} players and ${_analysisResults!['globalSessions']} training sessions '
            'have been moved to organization scope.\n\n'
            '⚠️ You can now safely delete the global collections: players, training_sessions, organization_setup_progress';
      });

      _showSuccessMessage('Data migration completed successfully!');
      LoggingService.info('✅ Data migration completed successfully');

    } catch (e) {
      LoggingService.error('Migration execution failed', e);
      setState(() {
        _isLoading = false;
        _status = '❌ Migration failed: $e\n\nPlease check logs and try again.';
      });
      _showErrorMessage('Migration failed: $e');
    }
  }

  Future<void> _migratePlayersWithPayments() async {
    LoggingService.info('🏃 Migrating players with payments');

    final globalPlayers = await _firestore.collection('players').get();

    for (final playerDoc in globalPlayers.docs) {
      final playerId = playerDoc.id;
      final playerData = playerDoc.data();

      // Create player in organization scope
      final orgPlayerRef = _firestore
          .collection('organizations')
          .doc(targetOrgId)
          .collection('players')
          .doc(playerId);

      // Add migration metadata
      final migratedPlayerData = {
        ...playerData,
        'organization_id': targetOrgId,
        'migrated_from_global': true,
        'migration_date': FieldValue.serverTimestamp(),
        'original_source': 'global_players_collection',
      };

      await orgPlayerRef.set(migratedPlayerData);

      // Migrate payment subcollection
      final globalPayments = await playerDoc.reference.collection('payments').get();
      if (globalPayments.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final paymentDoc in globalPayments.docs) {
          final paymentData = paymentDoc.data();
          final orgPaymentRef = orgPlayerRef.collection('payments').doc(paymentDoc.id);

          final migratedPaymentData = {
            ...paymentData,
            'migrated_from_global': true,
            'migration_date': FieldValue.serverTimestamp(),
          };

          batch.set(orgPaymentRef, migratedPaymentData);
        }
        await batch.commit();
      }

      LoggingService.info('✅ Migrated player: $playerId');
    }
  }

  Future<void> _migrateTrainingSessions() async {
    LoggingService.info('🏃‍♂️ Migrating training sessions');

    final globalSessions = await _firestore.collection('training_sessions').get();

    for (final sessionDoc in globalSessions.docs) {
      final sessionId = sessionDoc.id;
      final sessionData = sessionDoc.data();

      // Create training session in organization scope
      final orgSessionRef = _firestore
          .collection('organizations')
          .doc(targetOrgId)
          .collection('training_sessions')
          .doc(sessionId);

      // Add migration metadata
      final migratedSessionData = {
        ...sessionData,
        'organization_id': targetOrgId,
        'migrated_from_global': true,
        'migration_date': FieldValue.serverTimestamp(),
        'original_source': 'global_training_sessions_collection',
      };

      await orgSessionRef.set(migratedSessionData);
      LoggingService.info('✅ Migrated training session: $sessionId');
    }
  }

  Future<void> _verifyMigration() async {
    LoggingService.info('🔍 Verifying migration');

    final globalPlayers = await _firestore.collection('players').get();
    final globalSessions = await _firestore.collection('training_sessions').get();

    final orgPlayers = await _firestore
        .collection('organizations')
        .doc(targetOrgId)
        .collection('players')
        .where('migrated_from_global', isEqualTo: true)
        .get();

    final orgSessions = await _firestore
        .collection('organizations')
        .doc(targetOrgId)
        .collection('training_sessions')
        .where('migrated_from_global', isEqualTo: true)
        .get();

    final playersMatch = globalPlayers.docs.length == orgPlayers.docs.length;
    final sessionsMatch = globalSessions.docs.length == orgSessions.docs.length;

    if (!playersMatch || !sessionsMatch) {
      throw Exception('Migration verification failed: data counts do not match');
    }

    LoggingService.info('✅ Migration verification passed');
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }
}