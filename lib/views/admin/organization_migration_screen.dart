import 'package:flutter/material.dart';
import 'package:footballtraining/services/organization_data_migration_service.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/services/organization_context.dart';

/// Admin utility screen for managing organization data migration
/// This helps migrate from global collections to organization-scoped collections
class OrganizationMigrationScreen extends StatefulWidget {
  const OrganizationMigrationScreen({Key? key}) : super(key: key);

  @override
  State<OrganizationMigrationScreen> createState() =>
      _OrganizationMigrationScreenState();
}

class _OrganizationMigrationScreenState
    extends State<OrganizationMigrationScreen> {
  final _migrationService = OrganizationDataMigrationService();
  bool _isMigrating = false;
  String _migrationLog = '';

  void _addToLog(String message) {
    setState(() {
      _migrationLog += '${DateTime.now().toIso8601String()}: $message\n';
    });
  }

  Future<void> _migrateCurrentOrganization() async {
    if (!OrganizationContext.isInitialized) {
      _addToLog('❌ Organization context not initialized');
      return;
    }

    setState(() {
      _isMigrating = true;
      _migrationLog = '';
    });

    try {
      final orgId = OrganizationContext.currentOrgId;
      _addToLog('🚀 Starting migration for organization: $orgId');

      await _migrationService.migrateOrganizationData(orgId);
      _addToLog('✅ Migration completed successfully');

      // Verify migration
      _addToLog('🔍 Verifying migration...');
      final isVerified = await _migrationService.verifyMigration(orgId);
      _addToLog(isVerified
          ? '✅ Migration verified'
          : '❌ Migration verification failed');
    } catch (e) {
      _addToLog('❌ Migration failed: $e');
      LoggingService.error('Migration failed', e);
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateAllOrganizations() async {
    setState(() {
      _isMigrating = true;
      _migrationLog = '';
    });

    try {
      _addToLog('🌍 Starting migration for all organizations');
      await _migrationService.migrateAllOrganizations();
      _addToLog('🎉 All migrations completed');
    } catch (e) {
      _addToLog('❌ Global migration failed: $e');
      LoggingService.error('Global migration failed', e);
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _verifyCurrentOrganization() async {
    if (!OrganizationContext.isInitialized) {
      _addToLog('❌ Organization context not initialized');
      return;
    }

    try {
      final orgId = OrganizationContext.currentOrgId;
      _addToLog('🔍 Verifying migration for organization: $orgId');

      final isVerified = await _migrationService.verifyMigration(orgId);
      _addToLog(isVerified
          ? '✅ Migration verified'
          : '❌ Migration verification failed');
    } catch (e) {
      _addToLog('❌ Verification failed: $e');
    }
  }

  Future<void> _cleanupCurrentOrganization() async {
    if (!OrganizationContext.isInitialized) {
      _addToLog('❌ Organization context not initialized');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Cleanup'),
        content: const Text(
          'This will permanently delete the original data from global collections. '
          'Make sure migration verification passed before proceeding. '
          'This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Original Data'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final orgId = OrganizationContext.currentOrgId;
      _addToLog('🗑️ Starting cleanup for organization: $orgId');

      await _migrationService.cleanupGlobalCollections(orgId);
      _addToLog('✅ Cleanup completed');
    } catch (e) {
      _addToLog('❌ Cleanup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Data Migration'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Multi-Tenant Data Migration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tool migrates data from global collections (teams, players, users) '
                      'to organization-scoped collections (organizations/{orgId}/teams, etc.) '
                      'to ensure complete data isolation between different football clubs.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current organization info
            if (OrganizationContext.isInitialized)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Organization',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Name: ${OrganizationContext.currentOrg.name}'),
                      Text('ID: ${OrganizationContext.currentOrgId}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _migrateCurrentOrganization,
                  icon: const Icon(Icons.upload),
                  label: const Text('Migrate Current Org'),
                ),
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _migrateAllOrganizations,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Migrate All Orgs'),
                ),
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _verifyCurrentOrganization,
                  icon: const Icon(Icons.verified),
                  label: const Text('Verify Migration'),
                ),
                ElevatedButton.icon(
                  onPressed: _isMigrating ? null : _cleanupCurrentOrganization,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Cleanup Original Data'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Migration status
            if (_isMigrating)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Migration in progress...'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Log display
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Migration Log',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _migrationLog = ''),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Text(
                            _migrationLog.isEmpty
                                ? 'No migration log yet.'
                                : _migrationLog,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
