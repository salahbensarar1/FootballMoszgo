import 'package:flutter/material.dart';
import '../../utils/migration_helper.dart';

class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  bool _isRunning = false;
  String? _result;

  Future<void> _runIsActiveMigration() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final results = await MigrationHelper.addIsActiveFieldToAllUsers();

      setState(() {
        _result = '''
Migration completed successfully!

📈 Results:
• Organizations processed: ${results['organizationsProcessed']}
• Users updated: ${results['usersUpdated']}
• Users already had field: ${results['usersAlreadyHaveField']}
• Total users: ${results['totalUsers']}

✅ All users now have the is_active field and can authenticate properly.
        ''';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Migration'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add is_active Field Migration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This migration will add the "is_active: true" field to all users who don\'t have it. '
                      'This is needed for authentication to work properly.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isRunning ? null : _runIsActiveMigration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                          child: _isRunning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Run Migration'),
                        ),
                        if (_isRunning) ...[
                          const SizedBox(width: 16),
                          const Text('Running migration...'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Card(
                color: _result!.contains('Error')
                  ? Colors.red[50]
                  : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Migration Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _result!.contains('Error')
                            ? Colors.red[800]
                            : Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}