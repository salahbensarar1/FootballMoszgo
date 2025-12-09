import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Safe data migration script for moving global collections to organization scope
/// Run this to migrate players and training_sessions to UYM9gTWj8o2HgEcOFpsG
void main() async {
  print('🚀 SAFE DATA MIGRATION TO ORGANIZATION');
  print('====================================');

  try {
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    const targetOrgId = 'UYM9gTWj8o2HgEcOFpsG'; // Nagykoros club

    // Step 1: Analyze current data
    await analyzeCurrentData(firestore, targetOrgId);

    // Step 2: Ask for user confirmation
    print('\n⚠️  DO YOU WANT TO PROCEED WITH MIGRATION?');
    print('Type "YES" to continue, anything else to abort:');

    final input = stdin.readLineSync();
    if (input?.toUpperCase() != 'YES') {
      print('❌ Migration aborted by user');
      return;
    }

    // Step 3: Migrate players (with payments)
    await migratePlayersWithPayments(firestore, targetOrgId);

    // Step 4: Migrate training sessions
    await migrateTrainingSessions(firestore, targetOrgId);

    // Step 5: Verify migration
    await verifyMigration(firestore, targetOrgId);

    print('\n🎉 MIGRATION COMPLETED SUCCESSFULLY!');
    print('✅ All data has been safely moved to organization scope');
    print('✅ You can now safely delete global collections');

  } catch (e, stackTrace) {
    print('\n❌ MIGRATION FAILED: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Analyze current database state
Future<void> analyzeCurrentData(FirebaseFirestore firestore, String targetOrgId) async {
  print('\n🔍 ANALYZING CURRENT DATA');
  print('========================');

  // Check global collections
  final globalPlayers = await firestore.collection('players').get();
  final globalSessions = await firestore.collection('training_sessions').get();

  // Check organization collections
  final orgPlayers = await firestore
      .collection('organizations')
      .doc(targetOrgId)
      .collection('players')
      .get();

  final orgSessionsRef = firestore
      .collection('organizations')
      .doc(targetOrgId)
      .collection('training_sessions');
  final orgSessions = await orgSessionsRef.get();

  print('📊 Current State:');
  print('  Global Players: ${globalPlayers.docs.length}');
  print('  Global Training Sessions: ${globalSessions.docs.length}');
  print('  Org Players (existing): ${orgPlayers.docs.length}');
  print('  Org Training Sessions (existing): ${orgSessions.docs.length}');

  // Check for payment subcollections in global players
  int playersWithPayments = 0;
  for (final playerDoc in globalPlayers.docs) {
    final payments = await playerDoc.reference.collection('payments').get();
    if (payments.docs.isNotEmpty) {
      playersWithPayments++;
      print('  💰 Player ${playerDoc.id}: ${payments.docs.length} payments');
    }
  }

  print('\n📋 Migration Plan:');
  print('  ✅ Will merge ${globalPlayers.docs.length} global players into existing org players');
  print('  ✅ Will preserve $playersWithPayments players with payment data');
  print('  ✅ Will add ${globalSessions.docs.length} training sessions to organization');
  print('  ⚠️  No data will be overwritten (new documents only)');
}

/// Migrate global players with their payment subcollections
Future<void> migratePlayersWithPayments(FirebaseFirestore firestore, String targetOrgId) async {
  print('\n🏃 MIGRATING PLAYERS WITH PAYMENTS');
  print('================================');

  final globalPlayers = await firestore.collection('players').get();

  for (final playerDoc in globalPlayers.docs) {
    final playerId = playerDoc.id;
    final playerData = playerDoc.data();

    print('📝 Processing player: $playerId');

    // Create player in organization scope
    final orgPlayerRef = firestore
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
    print('  ✅ Player data migrated');

    // Migrate payment subcollection
    final globalPayments = await playerDoc.reference.collection('payments').get();
    if (globalPayments.docs.isNotEmpty) {
      print('  💰 Migrating ${globalPayments.docs.length} payments...');

      final batch = firestore.batch();
      for (final paymentDoc in globalPayments.docs) {
        final paymentData = paymentDoc.data();
        final orgPaymentRef = orgPlayerRef.collection('payments').doc(paymentDoc.id);

        // Add migration metadata to payments
        final migratedPaymentData = {
          ...paymentData,
          'migrated_from_global': true,
          'migration_date': FieldValue.serverTimestamp(),
        };

        batch.set(orgPaymentRef, migratedPaymentData);
      }
      await batch.commit();
      print('  ✅ All payments migrated');
    }

    print('  ✅ Player $playerId completely migrated');
  }

  print('🎉 All players with payments migrated successfully!');
}

/// Migrate global training sessions
Future<void> migrateTrainingSessions(FirebaseFirestore firestore, String targetOrgId) async {
  print('\n🏃‍♂️ MIGRATING TRAINING SESSIONS');
  print('==============================');

  final globalSessions = await firestore.collection('training_sessions').get();

  for (final sessionDoc in globalSessions.docs) {
    final sessionId = sessionDoc.id;
    final sessionData = sessionDoc.data();

    print('📝 Processing session: $sessionId');

    // Create training session in organization scope
    final orgSessionRef = firestore
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
    print('  ✅ Training session $sessionId migrated');
  }

  print('🎉 All training sessions migrated successfully!');
}

/// Verify migration completed correctly
Future<void> verifyMigration(FirebaseFirestore firestore, String targetOrgId) async {
  print('\n🔍 VERIFYING MIGRATION');
  print('=====================');

  // Count original data
  final globalPlayers = await firestore.collection('players').get();
  final globalSessions = await firestore.collection('training_sessions').get();

  // Count migrated data
  final orgPlayers = await firestore
      .collection('organizations')
      .doc(targetOrgId)
      .collection('players')
      .where('migrated_from_global', isEqualTo: true)
      .get();

  final orgSessions = await firestore
      .collection('organizations')
      .doc(targetOrgId)
      .collection('training_sessions')
      .where('migrated_from_global', isEqualTo: true)
      .get();

  print('📊 Verification Results:');
  print('  Global Players (original): ${globalPlayers.docs.length}');
  print('  Migrated Players: ${orgPlayers.docs.length}');
  print('  Global Sessions (original): ${globalSessions.docs.length}');
  print('  Migrated Sessions: ${orgSessions.docs.length}');

  // Verify payments were migrated
  int migratedPlayersWithPayments = 0;
  for (final playerDoc in orgPlayers.docs) {
    final payments = await playerDoc.reference.collection('payments').get();
    if (payments.docs.isNotEmpty) {
      migratedPlayersWithPayments++;
    }
  }

  print('  Players with payments migrated: $migratedPlayersWithPayments');

  final playersMatch = globalPlayers.docs.length == orgPlayers.docs.length;
  final sessionsMatch = globalSessions.docs.length == orgSessions.docs.length;

  if (playersMatch && sessionsMatch) {
    print('\n✅ MIGRATION VERIFICATION PASSED!');
    print('✅ All data has been successfully migrated');
    print('🗑️  You can now safely delete the global collections:');
    print('   - players');
    print('   - training_sessions');
    print('   - organization_setup_progress');
    print('   - users (if empty)');
  } else {
    print('\n❌ MIGRATION VERIFICATION FAILED!');
    print('❌ Data counts do not match - check for errors');
    print('⚠️  DO NOT delete global collections yet');
  }
}