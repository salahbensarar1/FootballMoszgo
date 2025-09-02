import 'package:flutter/material.dart';
import 'package:footballtraining/views/admin/firestore_cleanup_decision_screen.dart';

/// Quick way to add the cleanup decision screen to your admin menu
class AdminFirestoreMenu extends StatelessWidget {
  const AdminFirestoreMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Firestore Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Manage your database structure and organization isolation',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FirestoreCleanupDecisionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Analyze & Decide Cleanup Strategy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
