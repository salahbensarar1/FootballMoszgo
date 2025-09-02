import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/organization_model.dart';
import '../data/models/user_model.dart' as app_user;
import '../services/logging_service.dart';

/// Enhanced organization setup service that handles Firebase Auth restrictions
class EnhancedOrganizationSetupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create organization with better error handling
  static Future<Organization> createOrganization({
    required String name,
    required String address,
    required String type,
  }) async {
    try {
      LoggingService.info('Creating organization: $name');

      // Check if organization already exists
      final existingOrgs = await _firestore
          .collection('organizations')
          .where('name', isEqualTo: name)
          .get();

      if (existingOrgs.docs.isNotEmpty) {
        throw Exception('Organization with name "$name" already exists');
      }

      // Create organization document
      final orgRef = _firestore.collection('organizations').doc();
      
      // Convert string type to enum
      OrganizationType orgType;
      switch (type.toLowerCase()) {
        case 'club':
          orgType = OrganizationType.club;
          break;
        case 'academy':
          orgType = OrganizationType.academy;
          break;
        case 'school':
          orgType = OrganizationType.school;
          break;
        default:
          orgType = OrganizationType.other;
      }
      
      final organization = Organization(
        id: orgRef.id,
        name: name,
        slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        address: address,
        type: orgType,
        adminUserId: '', // Will be set later
        status: 'active',
        createdAt: DateTime.now(),
        timezone: 'Europe/Budapest',
        defaultCurrency: 'HUF',
        settings: const {
          'currency': 'HUF',
          'default_monthly_fee': 2500.0,
          'timezone': 'Europe/Budapest',
          'language': 'en',
        },
      );

      await orgRef.set(organization.toFirestore());
      LoggingService.info('Organization created successfully: ${orgRef.id}');

      return organization;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create organization', e, stackTrace);
      rethrow;
    }
  }

  /// Enhanced admin user creation with fallback strategies
  static Future<SetupResult> createAdminUser({
    required String organizationId,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      LoggingService.info('Creating admin user: $email');

      // Strategy 1: Try normal user creation
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        final firebaseUser = userCredential.user!;
        await _createUserDocuments(organizationId, firebaseUser.uid, name, email, 'admin');
        
        LoggingService.info('Admin user created successfully: $email');
        return SetupResult.success('Admin account created successfully');
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'admin-restricted-operation') {
          LoggingService.warning('Admin-restricted operation detected, trying fallback strategy');
          return await _handleAdminRestrictedOperation(organizationId, name, email, password);
        } else {
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create admin user', e, stackTrace);
      return SetupResult.failure('Failed to create admin user: $e');
    }
  }

  /// Fallback strategy when Firebase Auth restricts user creation
  static Future<SetupResult> _handleAdminRestrictedOperation(
    String organizationId,
    String name,
    String email,
    String password,
  ) async {
    // Strategy 2: Check if user already exists and is signed in
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == email) {
      LoggingService.info('Using currently signed-in user as admin');
      await _createUserDocuments(organizationId, currentUser.uid, name, email, 'admin');
      return SetupResult.success('Admin setup completed with current user');
    }

    // Strategy 3: Try anonymous authentication upgrade
    try {
      LoggingService.info('Attempting anonymous auth upgrade');
      
      // Sign in anonymously first
      final anonymousCredential = await _auth.signInAnonymously();
      final tempUser = anonymousCredential.user!;
      
      // Create user documents with temp ID
      await _createUserDocuments(organizationId, tempUser.uid, name, email, 'admin');
      
      return SetupResult.manualSetup(
        'Organization created successfully. Please manually create an admin account with email: $email',
        email,
        password,
      );
    } catch (e) {
      LoggingService.error('Anonymous auth upgrade failed', e);
      return SetupResult.manualSetup(
        'Organization created. Please contact support to set up admin access.',
        email,
        password,
      );
    }
  }

  /// Create user documents in both global and organization collections
  static Future<void> _createUserDocuments(
    String organizationId,
    String userId,
    String name,
    String email,
    String role,
  ) async {
    final batch = _firestore.batch();

    // Global user document
    final globalUser = app_user.User(
      id: userId,
      name: name,
      email: email,
      role: role,
      roleDescription: role == 'admin' ? 'System Administrator' : 'User',
      isActive: true,
      createdAt: DateTime.now(),
    );

    batch.set(
      _firestore.collection('users').doc(userId),
      globalUser.toFirestore(),
    );

    // Organization-scoped user document
    batch.set(
      _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(userId),
      {
        'name': name,
        'email': email,
        'role': role,
        'role_description': role == 'admin' ? 'System Administrator' : 'User',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'permissions': role == 'admin' ? ['all'] : [],
      },
    );

    // Update organization with admin user ID
    batch.update(
      _firestore.collection('organizations').doc(organizationId),
      {
        'admin_user_id': userId,
        'updated_at': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
    LoggingService.info('User documents created successfully');
  }

  /// Enhanced team creation with better error handling
  static Future<List<String>> createInitialTeams(
    String organizationId,
    List<String> teamNames,
    int playersPerTeam,
  ) async {
    try {
      LoggingService.info('Creating ${teamNames.length} teams with $playersPerTeam players each');

      final batch = _firestore.batch();
      final teamIds = <String>[];

      // Create teams
      for (final teamName in teamNames) {
        final teamRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('teams')
            .doc();
        
        teamIds.add(teamRef.id);

        batch.set(teamRef, {
          'team_name': teamName,
          'organization_id': organizationId,
          'number_of_players': playersPerTeam,
          'payment_fee': 10000.0,
          'currency': 'HUF',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'is_active': true,
        });

        // Create sample players for each team
        for (int i = 0; i < playersPerTeam; i++) {
          final playerRef = _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('players')
              .doc();

          batch.set(playerRef, {
            'name': 'Sample Player ${i + 1}',
            'team': teamName,
            'organization_id': organizationId,
            'position': ['Forward', 'Midfielder', 'Defender'][i % 3],
            'email': 'player${teamIds.length}${i + 1}@example.com',
            'phone': '+36 20 ${1000000 + teamIds.length * 100 + i}',
            'age': 18 + (i % 10),
            'is_active': true,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      LoggingService.info('Teams and players created successfully');
      return teamIds;

    } catch (e, stackTrace) {
      LoggingService.error('Failed to create teams', e, stackTrace);
      rethrow;
    }
  }
}

/// Result of setup operations
class SetupResult {
  final bool success;
  final String message;
  final String? adminEmail;
  final String? adminPassword;
  final bool requiresManualSetup;

  const SetupResult._({
    required this.success,
    required this.message,
    this.adminEmail,
    this.adminPassword,
    this.requiresManualSetup = false,
  });

  factory SetupResult.success(String message) {
    return SetupResult._(success: true, message: message);
  }

  factory SetupResult.failure(String message) {
    return SetupResult._(success: false, message: message);
  }

  factory SetupResult.manualSetup(String message, String email, String password) {
    return SetupResult._(
      success: true,
      message: message,
      adminEmail: email,
      adminPassword: password,
      requiresManualSetup: true,
    );
  }
}