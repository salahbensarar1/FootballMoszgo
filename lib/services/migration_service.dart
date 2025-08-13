import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/organization_model.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:logger/logger.dart';

/// Service for migrating from single-tenant to multi-tenant architecture
class MigrationService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Check if migration is needed for current user
  static Future<bool> needsMigration() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if user exists in old structure
      final oldUserDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!oldUserDoc.exists) return false;
      
      // Check if user exists in new structure
      final newUserQuery = await _firestore.collectionGroup('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      // Migration needed if user exists in old structure but not in new
      return newUserQuery.docs.isEmpty;
      
    } catch (e, stackTrace) {
      _logger.e('❌ Error checking migration status', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  /// Perform complete data migration for existing installation
  static Future<void> migrateToMultiTenant({
    required String organizationName,
    required String organizationSlug,
    String organizationType = 'club',
  }) async {
    try {
      _logger.i('🔄 Starting migration to multi-tenant architecture');
      
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Step 1: Create organization
      final orgId = await _createOrganization(
        name: organizationName,
        slug: organizationSlug,
        type: organizationType,
        adminUserId: user.uid,
      );
      
      // Step 2: Migrate users
      await _migrateUsers(orgId);
      
      // Step 3: Migrate teams
      await _migrateTeams(orgId);
      
      // Step 4: Migrate players
      await _migratePlayers(orgId);
      
      // Step 5: Migrate training sessions
      await _migrateTrainingSessions(orgId);
      
      // Step 6: Create default subscription
      await _createDefaultSubscription(orgId);
      
      // Step 7: Mark migration as complete
      await _markMigrationComplete(orgId);
      
      _logger.i('✅ Migration completed successfully');
      
    } catch (e, stackTrace) {
      _logger.e('❌ Migration failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  
  /// Create organization from migration
  static Future<String> _createOrganization({
    required String name,
    required String slug,
    required String type,
    required String adminUserId,
  }) async {
    _logger.i('📋 Creating organization: $name');
    
    final orgData = {
      'name': name,
      'slug': slug,
      'address': '',
      'type': type,
      'admin_user_id': adminUserId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'status': 'active',
      'timezone': 'UTC',
      'default_currency': 'USD',
      'settings': {
        'default_monthly_fee': 10000,
        'payment_methods': ['cash', 'card', 'transfer'],
        'training_session_duration': 90,
      },
    };
    
    final orgRef = await _firestore.collection('organizations').add(orgData);
    _logger.i('✅ Organization created: ${orgRef.id}');
    
    return orgRef.id;
  }
  
  /// Migrate users to organization-scoped structure
  static Future<void> _migrateUsers(String orgId) async {
    _logger.i('👥 Migrating users to organization: $orgId');
    
    final usersSnapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    int migratedCount = 0;
    
    for (final userDoc in usersSnapshot.docs) {
      final userData = userDoc.data();
      
      // Create new user document in organization
      final newUserRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('users')
          .doc(userDoc.id);
      
      final newUserData = {
        'uid': userDoc.id,
        'email': userData['email'],
        'name': userData['name'],
        'role': userData['role'] ?? 'user',
        'phone': userData['phone'],
        'avatar_url': userData['avatar_url'],
        'created_at': userData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_login': userData['last_login'],
        'is_active': userData['is_active'] ?? true,
        'permissions': userData['permissions'] ?? [],
        'created_by': userData['created_by'],
        'profile': userData['profile'] ?? {},
      };
      
      batch.set(newUserRef, newUserData);
      migratedCount++;
      
      // Batch commit every 400 operations (Firestore limit is 500)
      if (migratedCount % 400 == 0) {
        await batch.commit();
        _logger.i('📦 Batch committed: $migratedCount users migrated');
      }
    }
    
    // Commit remaining operations
    if (migratedCount % 400 != 0) {
      await batch.commit();
    }
    
    _logger.i('✅ Users migration completed: $migratedCount users migrated');
  }
  
  /// Migrate teams to organization-scoped structure
  static Future<void> _migrateTeams(String orgId) async {
    _logger.i('🏆 Migrating teams to organization: $orgId');
    
    final teamsSnapshot = await _firestore.collection('teams').get();
    final batch = _firestore.batch();
    int migratedCount = 0;
    
    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();
      
      final newTeamRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('teams')
          .doc(teamDoc.id);
      
      final newTeamData = {
        'name': teamData['team_name'] ?? teamData['name'],
        'age_group': teamData['age_group'],
        'created_at': teamData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': teamData['is_active'] ?? true,
        'coach_id': teamData['coach_id'],
        'assistant_coaches': teamData['assistant_coaches'] ?? [],
        'training_schedule': teamData['training_schedule'] ?? {},
        'number_of_players': teamData['number_of_players'] ?? 0,
        'payment_fee': teamData['payment_fee'] ?? teamData['monthly_fee'],
        'currency': teamData['currency'] ?? 'HUF',
        'season': teamData['season'] ?? DateTime.now().year.toString(),
      };
      
      batch.set(newTeamRef, newTeamData);
      migratedCount++;
      
      if (migratedCount % 400 == 0) {
        await batch.commit();
        _logger.i('📦 Batch committed: $migratedCount teams migrated');
      }
    }
    
    if (migratedCount % 400 != 0) {
      await batch.commit();
    }
    
    _logger.i('✅ Teams migration completed: $migratedCount teams migrated');
  }
  
  /// Migrate players to organization-scoped structure
  static Future<void> _migratePlayers(String orgId) async {
    _logger.i('⚽ Migrating players to organization: $orgId');
    
    final playersSnapshot = await _firestore.collection('players').get();
    final batch = _firestore.batch();
    int migratedCount = 0;
    
    for (final playerDoc in playersSnapshot.docs) {
      final playerData = playerDoc.data();
      
      final newPlayerRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('players')
          .doc(playerDoc.id);
      
      final newPlayerData = {
        'name': playerData['name'],
        'email': playerData['email'],
        'phone': playerData['phone'],
        'date_of_birth': playerData['date_of_birth'],
        'position': playerData['position'],
        'team_id': playerData['team_id'],
        'parent_contact': playerData['parent_contact'] ?? {},
        'emergency_contact': playerData['emergency_contact'] ?? {},
        'created_at': playerData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_active': playerData['is_active'] ?? true,
        'registration_date': playerData['registration_date'],
        'medical_info': playerData['medical_info'] ?? {},
        'jersey_number': playerData['jersey_number'],
        'payment_status': playerData['payment_status'] ?? 'current',
      };
      
      batch.set(newPlayerRef, newPlayerData);
      migratedCount++;
      
      if (migratedCount % 400 == 0) {
        await batch.commit();
        _logger.i('📦 Batch committed: $migratedCount players migrated');
      }
    }
    
    if (migratedCount % 400 != 0) {
      await batch.commit();
    }
    
    _logger.i('✅ Players migration completed: $migratedCount players migrated');
  }
  
  /// Migrate training sessions to organization-scoped structure
  static Future<void> _migrateTrainingSessions(String orgId) async {
    _logger.i('🏃 Migrating training sessions to organization: $orgId');
    
    final sessionsSnapshot = await _firestore.collection('training_sessions').get();
    final batch = _firestore.batch();
    int migratedCount = 0;
    
    for (final sessionDoc in sessionsSnapshot.docs) {
      final sessionData = sessionDoc.data();
      
      final newSessionRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('training_sessions')
          .doc(sessionDoc.id);
      
      final newSessionData = {
        'team_id': sessionData['team'],
        'coach_id': sessionData['coach_id'] ?? sessionData['coach'],
        'start_time': sessionData['start_time'],
        'end_time': sessionData['end_time'],
        'location': sessionData['location'] ?? '',
        'training_type': sessionData['training_type'],
        'description': sessionData['description'] ?? '',
        'created_at': sessionData['created_at'] ?? FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'attendance': sessionData['players'] ?? [],
        'notes': sessionData['notes'] ?? '',
        'weather': sessionData['weather'] ?? '',
      };
      
      batch.set(newSessionRef, newSessionData);
      migratedCount++;
      
      if (migratedCount % 400 == 0) {
        await batch.commit();
        _logger.i('📦 Batch committed: $migratedCount sessions migrated');
      }
    }
    
    if (migratedCount % 400 != 0) {
      await batch.commit();
    }
    
    _logger.i('✅ Training sessions migration completed: $migratedCount sessions migrated');
  }
  
  /// Create default subscription for migrated organization
  static Future<void> _createDefaultSubscription(String orgId) async {
    _logger.i('💳 Creating default subscription for organization: $orgId');
    
    final subscriptionData = {
      'organization_id': orgId,
      'plan_id': 'basic',
      'status': 'trialing',
      'current_period_start': Timestamp.now(),
      'current_period_end': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'trial_end': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'price_per_month': 29.0,
      'currency': 'USD',
      'max_players': 50,
      'max_teams': 3,
      'max_coaches': 2,
      'features': {
        'analytics': false,
        'reports': true,
        'api_access': false,
        'priority_support': false,
        'custom_branding': false,
      },
    };
    
    await _firestore.collection('subscriptions').add(subscriptionData);
    _logger.i('✅ Default subscription created');
  }
  
  /// Mark migration as complete
  static Future<void> _markMigrationComplete(String orgId) async {
    _logger.i('🏁 Marking migration as complete for organization: $orgId');
    
    final migrationData = {
      'organization_id': orgId,
      'migration_date': FieldValue.serverTimestamp(),
      'migrated_by': _auth.currentUser?.uid,
      'version': '1.0.0',
      'status': 'completed',
    };
    
    await _firestore.collection('migration_status').add(migrationData);
    _logger.i('✅ Migration marked as complete');
  }
  
  /// Clean up old data after successful migration (use with caution!)
  static Future<void> cleanupOldData() async {
    _logger.w('⚠️ Starting cleanup of old data - this is irreversible!');
    
    try {
      // Archive old collections instead of deleting
      final collections = ['users', 'teams', 'players', 'training_sessions'];
      
      for (final collectionName in collections) {
        _logger.i('📦 Archiving collection: $collectionName');
        
        final snapshot = await _firestore.collection(collectionName).get();
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          final archiveRef = _firestore
              .collection('archived_data')
              .doc(collectionName)
              .collection('documents')
              .doc(doc.id);
          
          batch.set(archiveRef, {
            ...doc.data(),
            'archived_at': FieldValue.serverTimestamp(),
            'original_collection': collectionName,
          });
          
          // Mark original as archived instead of deleting
          batch.update(doc.reference, {
            'archived': true,
            'archived_at': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        _logger.i('✅ Collection archived: $collectionName');
      }
      
    } catch (e, stackTrace) {
      _logger.e('❌ Cleanup failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}