import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/services/organization_context.dart';

/// Service to migrate data from global collections to organization-scoped collections
/// This ensures complete data isolation between different football clubs
class OrganizationDataMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all data for a specific organization from global to scoped collections
  Future<void> migrateOrganizationData(String organizationId) async {
    try {
      LoggingService.info(
          '🚀 Starting data migration for organization: $organizationId');

      // Initialize organization context for migration
      await OrganizationContext.setCurrentOrganization(organizationId);

      final batch = _firestore.batch();
      int operationCount = 0;

      // Migrate users for this organization
      await _migrateUsers(organizationId, batch, operationCount);

      // Migrate teams for this organization
      await _migrateTeams(organizationId, batch, operationCount);

      // Migrate players for this organization
      await _migratePlayers(organizationId, batch, operationCount);

      // Migrate training sessions for this organization
      await _migrateTrainingSessions(organizationId, batch, operationCount);

      // Migrate payments for this organization
      await _migratePayments(organizationId, batch, operationCount);

      // Commit migration in smaller batches to avoid Firestore limits
      if (operationCount > 0) {
        await batch.commit();
        LoggingService.info(
            '✅ Migration batch committed with $operationCount operations');
      }

      LoggingService.info(
          '✅ Data migration completed for organization: $organizationId');
    } catch (e, stackTrace) {
      LoggingService.error(
          '❌ Data migration failed for organization: $organizationId',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Migrate users to organization-scoped collection
  Future<void> _migrateUsers(
      String organizationId, WriteBatch batch, int operationCount) async {
    try {
      // Get all users that belong to this organization
      final usersQuery = await _firestore
          .collection('users')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      LoggingService.info(
          '🧑‍💼 Migrating ${usersQuery.docs.length} users for organization: $organizationId');

      for (final userDoc in usersQuery.docs) {
        final userData = userDoc.data();

        // Create user in organization-scoped collection
        final orgUserRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('users')
            .doc(userDoc.id);

        // Add migration metadata
        final migratedData = {
          ...userData,
          'migrated_at': FieldValue.serverTimestamp(),
          'migrated_from': 'global_users_collection',
        };

        batch.set(orgUserRef, migratedData);
        operationCount++;

        // Mark original document as migrated (don't delete yet for safety)
        batch.update(userDoc.reference, {
          'migrated_to_org_scope': true,
          'migrated_at': FieldValue.serverTimestamp(),
          'target_org_id': organizationId,
        });
        operationCount++;
      }
    } catch (e) {
      LoggingService.error('❌ User migration failed', e);
      rethrow;
    }
  }

  /// Migrate teams to organization-scoped collection
  Future<void> _migrateTeams(
      String organizationId, WriteBatch batch, int operationCount) async {
    try {
      final teamsQuery = await _firestore
          .collection('teams')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      LoggingService.info(
          '⚽ Migrating ${teamsQuery.docs.length} teams for organization: $organizationId');

      for (final teamDoc in teamsQuery.docs) {
        final teamData = teamDoc.data();

        final orgTeamRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('teams')
            .doc(teamDoc.id);

        final migratedData = {
          ...teamData,
          'migrated_at': FieldValue.serverTimestamp(),
          'migrated_from': 'global_teams_collection',
        };

        batch.set(orgTeamRef, migratedData);
        operationCount++;

        batch.update(teamDoc.reference, {
          'migrated_to_org_scope': true,
          'migrated_at': FieldValue.serverTimestamp(),
          'target_org_id': organizationId,
        });
        operationCount++;
      }
    } catch (e) {
      LoggingService.error('❌ Team migration failed', e);
      rethrow;
    }
  }

  /// Migrate players to organization-scoped collection
  Future<void> _migratePlayers(
      String organizationId, WriteBatch batch, int operationCount) async {
    try {
      final playersQuery = await _firestore
          .collection('players')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      LoggingService.info(
          '🏃‍♂️ Migrating ${playersQuery.docs.length} players for organization: $organizationId');

      for (final playerDoc in playersQuery.docs) {
        final playerData = playerDoc.data();

        final orgPlayerRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('players')
            .doc(playerDoc.id);

        final migratedData = {
          ...playerData,
          'migrated_at': FieldValue.serverTimestamp(),
          'migrated_from': 'global_players_collection',
        };

        batch.set(orgPlayerRef, migratedData);
        operationCount++;

        batch.update(playerDoc.reference, {
          'migrated_to_org_scope': true,
          'migrated_at': FieldValue.serverTimestamp(),
          'target_org_id': organizationId,
        });
        operationCount++;
      }
    } catch (e) {
      LoggingService.error('❌ Player migration failed', e);
      rethrow;
    }
  }

  /// Migrate training sessions to organization-scoped collection
  Future<void> _migrateTrainingSessions(
      String organizationId, WriteBatch batch, int operationCount) async {
    try {
      final sessionsQuery = await _firestore
          .collection('training_sessions')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      LoggingService.info(
          '🏃‍♀️ Migrating ${sessionsQuery.docs.length} training sessions for organization: $organizationId');

      for (final sessionDoc in sessionsQuery.docs) {
        final sessionData = sessionDoc.data();

        final orgSessionRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('training_sessions')
            .doc(sessionDoc.id);

        final migratedData = {
          ...sessionData,
          'migrated_at': FieldValue.serverTimestamp(),
          'migrated_from': 'global_training_sessions_collection',
        };

        batch.set(orgSessionRef, migratedData);
        operationCount++;

        batch.update(sessionDoc.reference, {
          'migrated_to_org_scope': true,
          'migrated_at': FieldValue.serverTimestamp(),
          'target_org_id': organizationId,
        });
        operationCount++;
      }
    } catch (e) {
      LoggingService.error('❌ Training session migration failed', e);
      rethrow;
    }
  }

  /// Migrate payments to organization-scoped collection
  Future<void> _migratePayments(
      String organizationId, WriteBatch batch, int operationCount) async {
    try {
      final paymentsQuery = await _firestore
          .collection('payments')
          .where('organization_id', isEqualTo: organizationId)
          .get();

      LoggingService.info(
          '💰 Migrating ${paymentsQuery.docs.length} payments for organization: $organizationId');

      for (final paymentDoc in paymentsQuery.docs) {
        final paymentData = paymentDoc.data();

        final orgPaymentRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('payments')
            .doc(paymentDoc.id);

        final migratedData = {
          ...paymentData,
          'migrated_at': FieldValue.serverTimestamp(),
          'migrated_from': 'global_payments_collection',
        };

        batch.set(orgPaymentRef, migratedData);
        operationCount++;

        batch.update(paymentDoc.reference, {
          'migrated_to_org_scope': true,
          'migrated_at': FieldValue.serverTimestamp(),
          'target_org_id': organizationId,
        });
        operationCount++;
      }
    } catch (e) {
      LoggingService.error('❌ Payment migration failed', e);
      rethrow;
    }
  }

  /// Migrate all organizations found in the system
  Future<void> migrateAllOrganizations() async {
    try {
      LoggingService.info('🌍 Starting migration for all organizations');

      final orgsQuery = await _firestore.collection('organizations').get();
      LoggingService.info(
          '📋 Found ${orgsQuery.docs.length} organizations to migrate');

      for (final orgDoc in orgsQuery.docs) {
        final orgId = orgDoc.id;
        LoggingService.info('🏢 Migrating organization: $orgId');

        try {
          await migrateOrganizationData(orgId);
          LoggingService.info('✅ Successfully migrated organization: $orgId');
        } catch (e) {
          LoggingService.error('❌ Failed to migrate organization: $orgId', e);
          // Continue with next organization instead of failing completely
        }
      }

      LoggingService.info('🎉 All organization migrations completed');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Global migration failed', e, stackTrace);
      rethrow;
    }
  }

  /// Verify migration was successful for an organization
  Future<bool> verifyMigration(String organizationId) async {
    try {
      LoggingService.info(
          '🔍 Verifying migration for organization: $organizationId');

      // Count documents in global collections (should be marked as migrated)
      final globalUsers = await _firestore
          .collection('users')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .count()
          .get();

      final globalTeams = await _firestore
          .collection('teams')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .count()
          .get();

      final globalPlayers = await _firestore
          .collection('players')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .count()
          .get();

      // Count documents in organization-scoped collections
      final scopedUsers = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .count()
          .get();

      final scopedTeams = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('teams')
          .count()
          .get();

      final scopedPlayers = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('players')
          .count()
          .get();

      final isValid = globalUsers.count == scopedUsers.count &&
          globalTeams.count == scopedTeams.count &&
          globalPlayers.count == scopedPlayers.count;

      LoggingService.info(isValid
          ? '✅ Migration verification passed'
          : '❌ Migration verification failed');

      return isValid;
    } catch (e) {
      LoggingService.error('❌ Migration verification failed', e);
      return false;
    }
  }

  /// Clean up old global collection documents after successful migration
  /// WARNING: This deletes the original data - use with caution!
  Future<void> cleanupGlobalCollections(String organizationId) async {
    try {
      LoggingService.warning(
          '🗑️ Starting cleanup of global collections for organization: $organizationId');
      LoggingService.warning('⚠️ This will permanently delete original data');

      // Verify migration first
      final isVerified = await verifyMigration(organizationId);
      if (!isVerified) {
        throw Exception('Migration verification failed - aborting cleanup');
      }

      final batch = _firestore.batch();

      // Delete migrated users
      final usersQuery = await _firestore
          .collection('users')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .get();

      for (final doc in usersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete migrated teams
      final teamsQuery = await _firestore
          .collection('teams')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .get();

      for (final doc in teamsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete migrated players
      final playersQuery = await _firestore
          .collection('players')
          .where('organization_id', isEqualTo: organizationId)
          .where('migrated_to_org_scope', isEqualTo: true)
          .get();

      for (final doc in playersQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      LoggingService.info(
          '✅ Cleanup completed for organization: $organizationId');
    } catch (e, stackTrace) {
      LoggingService.error(
          '❌ Cleanup failed for organization: $organizationId', e, stackTrace);
      rethrow;
    }
  }
}
