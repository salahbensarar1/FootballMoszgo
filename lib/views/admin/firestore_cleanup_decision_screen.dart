import 'package:flutter/material.dart';
import 'package:footballtraining/services/organization_isolation_analyzer.dart';
import 'package:footballtraining/services/organization_data_migration_service.dart';
import 'package:footballtraining/services/logging_service.dart';

/// Simple screen to check Firestore structure and decide on cleanup strategy
class FirestoreCleanupDecisionScreen extends StatefulWidget {
  const FirestoreCleanupDecisionScreen({super.key});

  @override
  State<FirestoreCleanupDecisionScreen> createState() =>
      _FirestoreCleanupDecisionScreenState();
}

class _FirestoreCleanupDecisionScreenState
    extends State<FirestoreCleanupDecisionScreen> {
  final _analyzer = OrganizationIsolationAnalyzer();
  final _migrationService = OrganizationDataMigrationService();

  Map<String, dynamic>? _analysis;
  bool _isLoading = false;
  String? _recommendation;

  @override
  void initState() {
    super.initState();
    _analyzeCurrentStructure();
  }

  Future<void> _analyzeCurrentStructure() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analysis = await _analyzer.analyzeIsolationStatus();
      final recommendation = _generateRecommendation(analysis);

      setState(() {
        _analysis = analysis;
        _recommendation = recommendation;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error('Failed to analyze Firestore structure', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateRecommendation(Map<String, dynamic> analysis) {
    final orgCount = analysis['organizations_count'] as int;
    final globalCollections =
        analysis['global_collections'] as Map<String, dynamic>;

    int globalDataCount = 0;
    for (final entry in globalCollections.entries) {
      final data = entry.value as Map<String, dynamic>;
      globalDataCount += (data['count'] as int);
    }

    if (orgCount == 0 && globalDataCount == 0) {
      return "✅ FRESH START: Your Firestore is clean! You can start creating organizations with proper isolation.";
    } else if (orgCount > 0 && globalDataCount == 0) {
      return "✅ PERFECT SETUP: You already have properly isolated organizations! No action needed.";
    } else if (orgCount == 0 && globalDataCount > 0) {
      return "🧹 CLEAN SLATE RECOMMENDED: You have old global data but no organizations. Clear everything and start fresh.";
    } else if (orgCount == 1 && globalDataCount > 0) {
      return "📦 MIGRATION RECOMMENDED: You have one organization and some global data. Migrate the global data to your organization.";
    } else {
      return "⚠️ COMPLEX SITUATION: Multiple organizations with global data. Careful migration needed.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Cleanup Decision'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalysisContent(),
    );
  }

  Widget _buildAnalysisContent() {
    if (_analysis == null) {
      return const Center(
        child: Text('Failed to analyze Firestore structure'),
      );
    }

    final isolation = _analysis!['isolation_status'] as Map<String, dynamic>;
    final orgCount = isolation['organizations_count'] as int;
    final globalDataCount = isolation['global_data_count'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Current Firestore Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Organizations: $orgCount'),
                  Text('Global Documents: $globalDataCount'),
                  Text(
                      'Isolation Score: ${isolation['isolation_percentage']}%'),
                  Text('Status: ${isolation['status']}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Recommendation Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Recommendation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _recommendation ?? 'No recommendation available',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          const Text(
            '🎯 Choose Your Action',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildActionButtons(orgCount, globalDataCount),

          const SizedBox(height: 24),

          // Detailed Analysis
          _buildDetailedAnalysis(),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int orgCount, int globalDataCount) {
    return Column(
      children: [
        // Option 1: Clean Slate
        if (orgCount <= 1)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCleanSlateDialog,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('🧹 Clean Slate (Delete Everything)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Option 2: Migrate Data
        if (orgCount > 0 && globalDataCount > 0)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showMigrationDialog,
              icon: const Icon(Icons.move_to_inbox),
              label: const Text('📦 Migrate Global Data to Organizations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Option 3: Do Nothing
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check_circle),
            label: const Text('✅ Keep Current Setup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedAnalysis() {
    final organizations = _analysis!['organizations'] as Map<String, dynamic>;
    final globalCollections =
        _analysis!['global_collections'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📋 Detailed Analysis',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Organizations
        if (organizations.isNotEmpty) ...[
          const Text('🏢 Organizations:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...organizations.entries.map((entry) {
            final orgData = entry.value as Map<String, dynamic>;
            final collections = orgData['collections'] as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                  '• ${orgData['name']} (${collections.values.fold<int>(0, (sum, count) => sum + (count as int))} documents)'),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Global Collections
        if (globalCollections.isNotEmpty) ...[
          const Text('🌍 Global Collections:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...globalCollections.entries.map((entry) {
            final collectionData = entry.value as Map<String, dynamic>;
            final count = collectionData['count'] as int;
            if (count > 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• ${entry.key}: $count documents'),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ],
    );
  }

  void _showCleanSlateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Clean Slate Warning'),
        content: const Text(
            'This will DELETE ALL DATA in your Firestore database!\n\n'
            'This action cannot be undone. You will start completely fresh.\n\n'
            'Are you absolutely sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performCleanSlate();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📦 Migrate Data'),
        content: const Text(
            'This will move all global data to organization-scoped collections.\n\n'
            'Your data will be preserved but moved to proper isolation.\n\n'
            'This is the safer option if you have important data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performMigration();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Migrate Data'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCleanSlate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // This would require implementing a cleanup service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Clean slate feature not implemented yet. Please clear manually in Firebase Console.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performMigration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _migrationService.migrateAllOrganizations();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Migration completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh analysis
      await _analyzeCurrentStructure();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Migration failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
