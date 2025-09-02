import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/environment.dart';
import '../services/logging_service.dart';

/// Service for managing demo organizations and cleanup
class DemoToolsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mark an organization as demo
  static Future<void> markAsDemo(String orgId) async {
    try {
      await _firestore.collection('organizations').doc(orgId).update({
        'is_demo': true,
        'demo_created_at': FieldValue.serverTimestamp(),
        'demo_created_by': _auth.currentUser?.email ?? 'system',
      });
      
      LoggingService.info('Organization marked as demo: $orgId');
    } catch (e, stackTrace) {
      LoggingService.error('Failed to mark organization as demo', e, stackTrace);
      rethrow;
    }
  }

  /// Get all demo organizations
  static Future<List<DocumentSnapshot>> getDemoOrganizations() async {
    try {
      final query = await _firestore
          .collection('organizations')
          .where('is_demo', isEqualTo: true)
          .orderBy('demo_created_at', descending: true)
          .get();
      
      return query.docs;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to get demo organizations', e, stackTrace);
      return [];
    }
  }

  /// Clean up old demo organizations (only in debug mode)
  static Future<CleanupResult> cleanupDemoOrganizations({
    Duration? olderThan,
  }) async {
    if (!Environment.debugMode) {
      throw Exception('Demo cleanup is only available in debug mode');
    }

    final cutoffTime = olderThan ?? const Duration(hours: 24);
    final cutoffTimestamp = DateTime.now().subtract(cutoffTime);
    
    try {
      LoggingService.info('Starting demo organization cleanup');
      
      final demoOrgs = await _firestore
          .collection('organizations')
          .where('is_demo', isEqualTo: true)
          .where('demo_created_at', isLessThan: Timestamp.fromDate(cutoffTimestamp))
          .get();

      if (demoOrgs.docs.isEmpty) {
        LoggingService.info('No old demo organizations found');
        return CleanupResult(
          deletedCount: 0,
          errors: [],
          message: 'No demo organizations older than ${cutoffTime.inHours} hours found',
        );
      }

      final batch = _firestore.batch();
      final errors = <String>[];
      int deletedCount = 0;

      for (final orgDoc in demoOrgs.docs) {
        try {
          await _deleteOrganizationCascade(orgDoc.id, batch);
          deletedCount++;
        } catch (e) {
          errors.add('Failed to delete org ${orgDoc.id}: $e');
          LoggingService.error('Failed to delete demo org ${orgDoc.id}', e);
        }
      }

      // Commit the batch
      if (deletedCount > 0) {
        await batch.commit();
        LoggingService.info('Successfully cleaned up $deletedCount demo organizations');
      }

      return CleanupResult(
        deletedCount: deletedCount,
        errors: errors,
        message: 'Cleaned up $deletedCount demo organizations',
      );
    } catch (e, stackTrace) {
      LoggingService.error('Failed to cleanup demo organizations', e, stackTrace);
      return CleanupResult(
        deletedCount: 0,
        errors: ['Cleanup failed: $e'],
        message: 'Cleanup failed',
      );
    }
  }

  /// Delete organization and all its subcollections
  static Future<void> _deleteOrganizationCascade(String orgId, WriteBatch batch) async {
    final orgRef = _firestore.collection('organizations').doc(orgId);
    
    // Delete subcollections
    final subcollections = ['users', 'teams', 'players', 'training_sessions', 'payments'];
    
    for (final subcollection in subcollections) {
      final query = await orgRef.collection(subcollection).limit(500).get();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
    }
    
    // Delete the organization document itself
    batch.delete(orgRef);
  }

  /// Create demo organization for testing
  static Future<String> createDemoOrganization({
    String? name,
    bool withSampleData = true,
  }) async {
    if (!Environment.debugMode) {
      throw Exception('Demo organization creation is only available in debug mode');
    }

    try {
      final orgName = name ?? 'Demo Organization ${DateTime.now().millisecondsSinceEpoch}';
      
      // Create organization
      final orgRef = _firestore.collection('organizations').doc();
      await orgRef.set({
        'id': orgRef.id,
        'name': orgName,
        'address': '123 Demo Street, Demo City',
        'type': 'club',
        'is_demo': true,
        'demo_created_at': FieldValue.serverTimestamp(),
        'demo_created_by': _auth.currentUser?.email ?? 'system',
        'status': 'active',
        'created_at': FieldValue.serverTimestamp(),
        'settings': {
          'currency': 'HUF',
          'default_monthly_fee': 10000.0,
          'timezone': 'Europe/Budapest',
          'language': 'en',
        },
      });

      if (withSampleData) {
        await _createDemoData(orgRef.id);
      }

      LoggingService.info('Demo organization created: ${orgRef.id}');
      return orgRef.id;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create demo organization', e, stackTrace);
      rethrow;
    }
  }

  /// Create sample data for demo organization
  static Future<void> _createDemoData(String orgId) async {
    final batch = _firestore.batch();

    // Create demo teams
    final teamNames = ['Team A', 'Team B', 'Youth Team'];
    final teamIds = <String>[];

    for (final teamName in teamNames) {
      final teamRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('teams')
          .doc();
      
      teamIds.add(teamRef.id);
      batch.set(teamRef, {
        'team_name': teamName,
        'organization_id': orgId,
        'number_of_players': 5,
        'payment_fee': 10000.0,
        'currency': 'HUF',
        'created_at': FieldValue.serverTimestamp(),
        'is_active': true,
      });
    }

    // Create demo players
    final playerNames = [
      'Demo Player 1', 'Demo Player 2', 'Demo Player 3',
      'Demo Player 4', 'Demo Player 5', 'Demo Player 6',
    ];

    for (int i = 0; i < playerNames.length; i++) {
      final playerRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('players')
          .doc();
      
      final teamName = teamNames[i % teamNames.length];
      
      batch.set(playerRef, {
        'name': playerNames[i],
        'team': teamName,
        'organization_id': orgId,
        'position': ['Forward', 'Midfielder', 'Defender'][i % 3],
        'email': 'demo.player${i + 1}@example.com',
        'phone': '+36 20 ${1000000 + i}',
        'age': 18 + (i % 10),
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    LoggingService.info('Demo data created for organization: $orgId');
  }

  /// Show demo banner widget
  static bool shouldShowDemoBanner() {
    return Environment.isDemo && Environment.debugMode;
  }
}

/// Result of cleanup operations
class CleanupResult {
  final int deletedCount;
  final List<String> errors;
  final String message;

  const CleanupResult({
    required this.deletedCount,
    required this.errors,
    required this.message,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => deletedCount > 0 && errors.isEmpty;
}