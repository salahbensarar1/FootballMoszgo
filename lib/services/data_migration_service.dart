import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/logging_service.dart';

class DataMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Migrate flat collections to organization-scoped structure
  static Future<String> migrateToOrganizationStructure({
    required String organizationName,
    required String organizationDescription,
    String? adminEmail,
  }) async {
    try {
      LoggingService.info(
          '🚀 Starting data migration to organization structure');

      // Step 1: Create the organization
      final organizationId =
          await _createOrganization(organizationName, organizationDescription);

      LoggingService.info('✅ Created organization: $organizationId');

      // Step 2: Migrate users
      await _migrateUsers(organizationId, adminEmail);

      // Step 3: Migrate teams
      await _migrateTeams(organizationId);

      // Step 4: Migrate players
      await _migratePlayers(organizationId);

      // Step 5: Migrate payments (if exists)
      await _migratePayments(organizationId);

      LoggingService.info('🎉 Migration completed successfully!');

      return organizationId;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Migration failed', e, stackTrace);
      rethrow;
    }
  }

  /// Create a new organization
  static Future<String> _createOrganization(
      String name, String description) async {
    final organizationRef = _firestore.collection('organizations').doc();
    final organizationId = organizationRef.id;

    await organizationRef.set({
      'id': organizationId,
      'name': name,
      'description': description,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_active': true,
      'subscription_status': 'trial',
      'plan_type': 'basic',
      'settings': {
        'max_teams': 10,
        'max_players_per_team': 30,
        'max_coaches': 5,
      },
      'contact_info': {
        'email': _auth.currentUser?.email ?? '',
        'phone': '',
        'address': '',
      },
    });

    return organizationId;
  }

  /// Migrate users collection
  static Future<void> _migrateUsers(
      String organizationId, String? adminEmail) async {
    LoggingService.info('📋 Migrating users...');

    final usersSnapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();

    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      final userEmail = userData['email'] as String?;

      // Enhance user data for organization structure
      final enhancedUserData = {
        ...userData,
        'organization_id': organizationId,
        'is_active': true,
        'joined_at': userData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'permissions': _getDefaultPermissions(userData['role'] as String?),
      };

      // If this is the admin email, ensure admin role
      if (adminEmail != null && userEmail == adminEmail) {
        enhancedUserData['role'] = 'admin';
        enhancedUserData['permissions'] = _getAdminPermissions();
      }

      // Create user in organization-scoped collection
      final orgUserRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(userDoc.id);

      batch.set(orgUserRef, enhancedUserData);
    }

    await batch.commit();
    LoggingService.info('✅ Users migrated: ${usersSnapshot.docs.length}');
  }

  /// Migrate teams collection
  static Future<void> _migrateTeams(String organizationId) async {
    LoggingService.info('⚽ Migrating teams...');

    final teamsSnapshot = await _firestore.collection('teams').get();
    final batch = _firestore.batch();

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();

      // Enhance team data for organization structure
      final enhancedTeamData = {
        ...teamData,
        'organization_id': organizationId,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
        'statistics': {
          'total_players': 0,
          'total_sessions': 0,
          'last_session_date': null,
        },
      };

      // Create team in organization-scoped collection
      final orgTeamRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('teams')
          .doc(teamDoc.id);

      batch.set(orgTeamRef, enhancedTeamData);
    }

    await batch.commit();
    LoggingService.info('✅ Teams migrated: ${teamsSnapshot.docs.length}');
  }

  /// Migrate players collection
  static Future<void> _migratePlayers(String organizationId) async {
    LoggingService.info('🏃‍♂️ Migrating players...');

    final playersSnapshot = await _firestore.collection('players').get();
    final batch = _firestore.batch();

    for (final playerDoc in playersSnapshot.docs) {
      final playerData = playerDoc.data();

      // Enhance player data for organization structure
      final enhancedPlayerData = {
        ...playerData,
        'organization_id': organizationId,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
        'statistics': {
          'total_sessions_attended': 0,
          'last_attendance_date': null,
          'performance_rating': 0.0,
        },
        'payment_status': {
          'current_year': DateTime.now().year,
          'amount_paid': 0.0,
          'amount_due': 0.0,
          'last_payment_date': null,
        },
      };

      // Create player in organization-scoped collection
      final orgPlayerRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('players')
          .doc(playerDoc.id);

      batch.set(orgPlayerRef, enhancedPlayerData);
    }

    await batch.commit();
    LoggingService.info('✅ Players migrated: ${playersSnapshot.docs.length}');
  }

  /// Migrate payments collection (if exists)
  static Future<void> _migratePayments(String organizationId) async {
    LoggingService.info('💰 Migrating payments...');

    try {
      final paymentsSnapshot = await _firestore.collection('payments').get();

      if (paymentsSnapshot.docs.isEmpty) {
        LoggingService.info('ℹ️ No payments to migrate');
        return;
      }

      final batch = _firestore.batch();

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();

        // Enhance payment data for organization structure
        final enhancedPaymentData = {
          ...paymentData,
          'organization_id': organizationId,
          'updated_at': FieldValue.serverTimestamp(),
        };

        // Create payment in organization-scoped collection
        final orgPaymentRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('payments')
            .doc(paymentDoc.id);

        batch.set(orgPaymentRef, enhancedPaymentData);
      }

      await batch.commit();
      LoggingService.info(
          '✅ Payments migrated: ${paymentsSnapshot.docs.length}');
    } catch (e) {
      LoggingService.warning('⚠️ Payments collection not found or empty: $e');
    }
  }

  /// Get default permissions based on role
  static Map<String, bool> _getDefaultPermissions(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return _getAdminPermissions();
      case 'coach':
        return {
          'view_teams': true,
          'manage_teams': true,
          'view_players': true,
          'manage_players': true,
          'view_sessions': true,
          'manage_sessions': true,
          'view_reports': true,
          'manage_attendance': true,
        };
      case 'receptionist':
        return {
          'view_teams': true,
          'view_players': true,
          'manage_payments': true,
          'view_reports': true,
          'manage_player_info': true,
        };
      default:
        return {
          'view_teams': false,
          'manage_teams': false,
          'view_players': false,
          'manage_players': false,
        };
    }
  }

  /// Get admin permissions
  static Map<String, bool> _getAdminPermissions() {
    return {
      'view_teams': true,
      'manage_teams': true,
      'view_players': true,
      'manage_players': true,
      'view_sessions': true,
      'manage_sessions': true,
      'view_reports': true,
      'manage_reports': true,
      'manage_attendance': true,
      'manage_payments': true,
      'manage_users': true,
      'manage_organization': true,
      'view_analytics': true,
      'export_data': true,
    };
  }

  /// Clean up old collections (use with caution!)
  static Future<void> cleanupOldCollections() async {
    LoggingService.warning('🧹 Starting cleanup of old collections...');

    // This is dangerous - only run after confirming migration success
    final collections = ['users', 'teams', 'players', 'payments'];

    for (final collectionName in collections) {
      try {
        final snapshot = await _firestore.collection(collectionName).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        LoggingService.info(
            '🗑️ Cleaned up $collectionName: ${snapshot.docs.length} documents');
      } catch (e) {
        LoggingService.warning('⚠️ Failed to cleanup $collectionName: $e');
      }
    }

    LoggingService.info('✅ Cleanup completed');
  }
}
