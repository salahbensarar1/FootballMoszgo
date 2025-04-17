import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SessionDetailsScreen extends StatelessWidget {
  final DocumentSnapshot sessionDoc;

  const SessionDetailsScreen({super.key, required this.sessionDoc});

  @override
  Widget build(BuildContext context) {
    // Extract data safely
    final data = sessionDoc.data() as Map<String, dynamic>? ?? {};
    final teamName = data['team'] ?? 'Session Details';

    return Scaffold(
      appBar: AppBar(
        title: Text(teamName),
        // Add AppBar gradient if desired
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Details for session ID: ${sessionDoc.id}\n\n(Implementation Pending)'),
        ),
      ),
    );
  }
}