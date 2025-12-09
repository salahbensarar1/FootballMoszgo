import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/organization_model.dart';
import '../data/models/user_model.dart' as app_user;
import '../services/logging_service.dart';
import '../services/organization_context.dart';

/// Result class for organization setup operations
class OrganizationSetupResult {
  final Organization? organization;
  final app_user.User? admin;
  final bool success;
  final String? error;

  const OrganizationSetupResult({
    this.organization,
    this.admin,
    required this.success,
    this.error,
  });
}

/// Tracks the progress of organization setup
class OrganizationSetupProgress {
  final String organizationId;
  final bool basicInfoCompleted;
  final bool adminCreated;
  final bool teamsCreated;
  final bool playersAdded;
  final bool paymentsConfigured;
  final DateTime lastUpdated;

  OrganizationSetupProgress({
    required this.organizationId,
    this.basicInfoCompleted = false,
    this.adminCreated = false,
    this.teamsCreated = false,
    this.playersAdded = false,
    this.paymentsConfigured = false,
    required this.lastUpdated,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'organization_id': organizationId,
      'basic_info_completed': basicInfoCompleted,
      'admin_created': adminCreated,
      'teams_created': teamsCreated,
      'players_added': playersAdded,
      'payments_configured': paymentsConfigured,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }

  static OrganizationSetupProgress fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrganizationSetupProgress(
      organizationId: data['organization_id'] ?? doc.id,
      basicInfoCompleted: data['basic_info_completed'] ?? false,
      adminCreated: data['admin_created'] ?? false,
      teamsCreated: data['teams_created'] ?? false,
      playersAdded: data['players_added'] ?? false,
      paymentsConfigured: data['payments_configured'] ?? false,
      lastUpdated:
          (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isCompleted {
    return basicInfoCompleted &&
        adminCreated &&
        teamsCreated &&
        paymentsConfigured;
  }

  double get completionPercentage {
    int completed = 0;
    if (basicInfoCompleted) completed++;
    if (adminCreated) completed++;
    if (teamsCreated) completed++;
    if (paymentsConfigured) completed++;
    return completed / 4.0;
  }
}

/// Service for handling organization setup and onboarding
class OrganizationSetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if any organization exists in the system
  /// If no authenticated user, assumes no organizations exist (setup needed)
  Future<bool> hasExistingOrganization() async {
    try {
      // Wait briefly for Firebase Auth to restore any persisted user after hot restart
      await _restoreAuthState();

      // If no authenticated user, assume setup is needed (no orgs exist)
      if (_auth.currentUser == null) {
        LoggingService.info('No authenticated user; assuming setup needed');
        return false;
      }

      // Query organizations collection with authenticated user
      final query = await _firestore.collection('organizations').limit(1).get();
      final hasOrgs = query.docs.isNotEmpty;
      LoggingService.info('Organization existence check: $hasOrgs');
      return hasOrgs;
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to check existing organizations', e, stackTrace);
      // If we can't check, assume no organizations exist to allow setup
      return false;
    }
  }

  /// Waits for auth state rehydration after hot restart (non-fatal timeout)
  Future<void> _restoreAuthState(
      {Duration timeout = const Duration(seconds: 2)}) async {
    if (_auth.currentUser != null) return; // Already have user
    try {
      final completer = Completer<void>();
      late StreamSubscription<User?> sub;
      sub = _auth.authStateChanges().listen((user) {
        completer.complete();
        sub.cancel();
      });
      await completer.future.timeout(timeout, onTimeout: () {
        try {
          sub.cancel();
        } catch (_) {}
      });
    } catch (_) {
      // Non-critical; continue without restored user
    }
  }

  /// Create a new organization with setup progress tracking
  /// Requires an authenticated user (admin) to be signed in first
  Future<Organization> createOrganization({
    required String name,
    required String address,
    required OrganizationType type,
    String? phoneNumber,
    String? email,
    String? website,
    String? adminUserId,
  }) async {
    try {
      // Ensure we have an authenticated user
      if (_auth.currentUser == null) {
        throw Exception(
            'User must be authenticated before creating organization');
      }

      final currentUserId = _auth.currentUser!.uid;

      // Create organization document
      final organizationRef = _firestore.collection('organizations').doc();

      final organization = Organization(
        id: organizationRef.id,
        name: name,
        address: address,
        type: type,
        phoneNumber: phoneNumber,
        email: email,
        website: website,
        adminUserId:
            adminUserId ?? currentUserId, // Use provided admin or current user
        createdAt: DateTime.now(),
        settings: const {
          'currency': 'HUF',
          'default_monthly_fee': 2500.0,
          'timezone': 'Europe/Budapest',
          'language': 'en',
        },
        slug: '',
      );

      await organizationRef.set(organization.toFirestore());

      // Create setup progress tracking
      await _firestore
          .collection('organization_setup_progress')
          .doc(organization.id)
          .set(OrganizationSetupProgress(
            organizationId: organization.id,
            basicInfoCompleted: true,
            lastUpdated: DateTime.now(),
          ).toFirestore());

      LoggingService.info(
          'Organization created successfully: ${organization.name}');
      return organization;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create organization', e, stackTrace);
      rethrow;
    }
  }

  /// Create admin user first (before organization creation)
  /// This establishes authentication for subsequent Firestore operations
  Future<app_user.User> createAdminUserFirst({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Ensure we start clean (sign out any existing user)
      if (_auth.currentUser != null) {
        await _auth.signOut();
        LoggingService.info('Signed out existing user before admin creation');
      }

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user model
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: 'admin',
        roleDescription: 'System Administrator',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // NOTE: User will be created in organization-scoped collection later
      // Global user collection removed for security - no cross-org access

      LoggingService.info('Admin user created and authenticated: $email');
      return user;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create admin user first', e, stackTrace);
      rethrow;
    }
  }

  /// Create a complete organization setup in the right order
  Future<OrganizationSetupResult> createCompleteOrganizationSetup({
    required String organizationName,
    required String organizationAddress,
    required OrganizationType organizationType,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    String? organizationPhone,
    String? organizationEmailContact,
    String? organizationWebsite,
  }) async {
    try {
      LoggingService.info(
          'Starting complete organization setup for: $organizationName');

      // Step 1: Create and authenticate admin user first
      final admin = await createAdminUserFirst(
        name: adminName,
        email: adminEmail,
        password: adminPassword,
      );

      // Step 2: Create organization with authenticated admin
      final organization = await createOrganization(
        name: organizationName,
        address: organizationAddress,
        type: organizationType,
        phoneNumber: organizationPhone,
        email: organizationEmailContact,
        website: organizationWebsite,
        adminUserId: admin.id,
      );

      // Step 3: Initialize organization context for scoped operations
      await OrganizationContext.setCurrentOrganization(organization.id);

      // Step 4: Create organization-scoped admin user document
      await _firestore
          .collection('organizations')
          .doc(organization.id)
          .collection('users')
          .doc(admin.id)
          .set({
        'name': adminName,
        'email': adminEmail,
        'role': 'admin',
        'role_description': 'System Administrator',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'permissions': ['all'],
        'uid': admin.id, // Firebase Auth UID
      });

      // Step 5: Create initial collections structure for the organization
      await _createInitialCollectionsStructure(organization.id);

      LoggingService.info('Complete organization setup successful');

      return OrganizationSetupResult(
        organization: organization,
        admin: admin,
        success: true,
      );
    } catch (e, stackTrace) {
      LoggingService.error('Complete organization setup failed', e, stackTrace);
      return OrganizationSetupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Create initial collection structure for a new organization
  Future<void> _createInitialCollectionsStructure(String organizationId) async {
    try {
      LoggingService.info(
          '📁 Creating initial collection structure for org: $organizationId');

      final batch = _firestore.batch();

      // Create a placeholder document in each collection to ensure they exist
      // Firestore collections are created only when they contain at least one document

      // Teams collection placeholder
      final teamsRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('teams')
          .doc('_placeholder');

      batch.set(teamsRef, {
        '_placeholder': true,
        'created_at': FieldValue.serverTimestamp(),
        'note': 'This document will be removed when first real team is created',
      });

      // Players collection placeholder
      final playersRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('players')
          .doc('_placeholder');

      batch.set(playersRef, {
        '_placeholder': true,
        'created_at': FieldValue.serverTimestamp(),
        'note':
            'This document will be removed when first real player is created',
      });

      // Training sessions collection placeholder
      final sessionsRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('training_sessions')
          .doc('_placeholder');

      batch.set(sessionsRef, {
        '_placeholder': true,
        'created_at': FieldValue.serverTimestamp(),
        'note':
            'This document will be removed when first real session is created',
      });

      // Payments collection placeholder
      final paymentsRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('payments')
          .doc('_placeholder');

      batch.set(paymentsRef, {
        '_placeholder': true,
        'created_at': FieldValue.serverTimestamp(),
        'note':
            'This document will be removed when first real payment is created',
      });

      // Reports collection placeholder
      final reportsRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('reports')
          .doc('_placeholder');

      batch.set(reportsRef, {
        '_placeholder': true,
        'created_at': FieldValue.serverTimestamp(),
        'note':
            'This document will be removed when first real report is created',
      });

      await batch.commit();
      LoggingService.info(
          '✅ Initial collection structure created successfully');
    } catch (e, stackTrace) {
      LoggingService.error(
          '❌ Failed to create initial collection structure', e, stackTrace);
      throw Exception('Failed to create initial organization structure: $e');
    }
  }

  /// Create admin user for the organization
  Future<app_user.User> createAdminUser({
    required String organizationId,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Sign out from anonymous account if present
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        await _auth.signOut();
        LoggingService.info('Signed out from anonymous account');
      }

      // Create Firebase Auth user with fallback
      UserCredential userCredential;
      User? firebaseUser;

      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        if (e.toString().contains('admin-restricted-operation')) {
          LoggingService.warning(
              'Admin restricted operation, using anonymous auth fallback');
          userCredential = await _auth.signInAnonymously();
          firebaseUser = userCredential.user;
        } else {
          rethrow;
        }
      }
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user model (for scoped collection only)
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: 'admin',
        roleDescription: 'System Administrator',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // NOTE: Global user collection removed for security
      // User will only exist in organization-scoped collection

      // Create organization-scoped user document (required by Firestore rules)
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'admin',
        'role_description': 'System Administrator',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'permissions': ['all'],
      });

      // Update organization with admin user ID
      await _firestore.collection('organizations').doc(organizationId).update({
        'admin_user_id': firebaseUser.uid,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update setup progress
      await _updateSetupProgress(organizationId, adminCreated: true);

      LoggingService.info('Admin user created successfully: $email');
      return user;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create admin user', e, stackTrace);
      rethrow;
    }
  }

  /// Create receptionist user for the organization
  Future<app_user.User> createReceptionistUser({
    required String organizationId,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user with fallback
      UserCredential userCredential;
      User? firebaseUser;

      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        if (e.toString().contains('admin-restricted-operation')) {
          LoggingService.warning(
              'Admin restricted operation, using anonymous auth fallback');
          userCredential = await _auth.signInAnonymously();
          firebaseUser = userCredential.user;
        } else {
          rethrow;
        }
      }
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user model (for scoped collection only)
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: 'receptionist',
        roleDescription: 'Reception & Operations',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // NOTE: Global user collection removed for security
      // User will only exist in organization-scoped collection

      // Create organization-scoped user document (required by Firestore rules)
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'name': name,
        'email': email,
        'role': 'receptionist',
        'role_description': 'Reception & Operations',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'permissions': ['attendance', 'players', 'payments'],
      });

      LoggingService.info('Receptionist user created successfully: $email');
      return user;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create receptionist user', e, stackTrace);
      rethrow;
    }
  }

  /// Create initial teams for the organization
  Future<List<String>> createInitialTeams({
    required String organizationId,
    required List<String> teamNames,
    double defaultMonthlyFee = 10000.0,
  }) async {
    try {
      final batch = _firestore.batch();
      final teamIds = <String>[];

      for (final teamName in teamNames) {
        final teamRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('teams')
            .doc();
        teamIds.add(teamRef.id);

        final teamData = {
          'team_name': teamName,
          'organization_id': organizationId,
          'number_of_players': 0,
          'payment_fee': defaultMonthlyFee,
          'currency': 'HUF',
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'is_active': true,
        };

        batch.set(teamRef, teamData);
      }

      await batch.commit();

      // Update setup progress
      await _updateSetupProgress(organizationId, teamsCreated: true);

      LoggingService.info('Created ${teamNames.length} initial teams');
      return teamIds;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create initial teams', e, stackTrace);
      rethrow;
    }
  }

  /// Create sample players for demonstration
  Future<List<String>> createSamplePlayers({
    required String organizationId,
    required String teamName,
    int playerCount = 5,
  }) async {
    try {
      final batch = _firestore.batch();
      final playerIds = <String>[];

      final sampleNames = [
        'Kovács János',
        'Nagy Péter',
        'Szabó Márk',
        'Tóth László',
        'Varga Attila',
        'Horváth Gábor',
        'Kiss Zoltán',
        'Molnár Dávid',
        'Lakatos András',
        'Balogh Tamás'
      ];

      final positions = ['Forward', 'Midfielder', 'Defender', 'Goalkeeper'];

      for (int i = 0; i < playerCount; i++) {
        final playerRef = _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('players')
            .doc();
        playerIds.add(playerRef.id);

        final playerData = {
          'name': sampleNames[i % sampleNames.length],
          'team': teamName,
          'organization_id': organizationId,
          'position': positions[i % positions.length],
          'email': 'player${i + 1}@example.com',
          'phone': '+36 20 ${(1000000 + i).toString()}',
          'age': 18 + (i % 15), // Ages 18-32
          'is_active': true,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        };

        batch.set(playerRef, playerData);
      }

      await batch.commit();

      // Update team player count
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('teams')
          .where('team_name', isEqualTo: teamName)
          .get()
          .then((query) {
        if (query.docs.isNotEmpty) {
          final teamDoc = query.docs.first;
          teamDoc.reference.update({
            'number_of_players': FieldValue.increment(playerCount),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });

      // Update setup progress
      await _updateSetupProgress(organizationId, playersAdded: true);

      LoggingService.info(
          'Created $playerCount sample players for team: $teamName');
      return playerIds;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to create sample players', e, stackTrace);
      rethrow;
    }
  }

  /// Configure payment settings
  Future<void> configurePaymentSettings({
    required String organizationId,
    required double defaultMonthlyFee,
    required String currency,
  }) async {
    try {
      // Update organization settings
      await _firestore.collection('organizations').doc(organizationId).update({
        'settings.default_monthly_fee': defaultMonthlyFee,
        'settings.currency': currency,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update setup progress
      await _updateSetupProgress(organizationId, paymentsConfigured: true);

      LoggingService.info(
          'Payment settings configured for organization: $organizationId');
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to configure payment settings', e, stackTrace);
      rethrow;
    }
  }

  /// Get organization setup progress
  Future<OrganizationSetupProgress?> getSetupProgress(
      String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organization_setup_progress')
          .doc(organizationId)
          .get();

      if (doc.exists) {
        return OrganizationSetupProgress.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to get setup progress', e, stackTrace);
      return null;
    }
  }

  /// Update setup progress
  Future<void> _updateSetupProgress(
    String organizationId, {
    bool? basicInfoCompleted,
    bool? adminCreated,
    bool? teamsCreated,
    bool? playersAdded,
    bool? paymentsConfigured,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'last_updated': FieldValue.serverTimestamp(),
      };

      if (basicInfoCompleted != null) {
        updateData['basic_info_completed'] = basicInfoCompleted;
      }
      if (adminCreated != null) {
        updateData['admin_created'] = adminCreated;
      }
      if (teamsCreated != null) {
        updateData['teams_created'] = teamsCreated;
      }
      if (playersAdded != null) {
        updateData['players_added'] = playersAdded;
      }
      if (paymentsConfigured != null) {
        updateData['payments_configured'] = paymentsConfigured;
      }

      await _firestore
          .collection('organization_setup_progress')
          .doc(organizationId)
          .update(updateData);
    } catch (e, stackTrace) {
      LoggingService.error('Failed to update setup progress', e, stackTrace);
    }
  }

  /// Complete organization setup
  Future<void> completeSetup(String organizationId) async {
    try {
      await _firestore.collection('organizations').doc(organizationId).update({
        'is_active': true,
        'settings.setup_completed': true,
        'settings.setup_completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.info('Organization setup completed: $organizationId');
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to complete organization setup', e, stackTrace);
      rethrow;
    }
  }

  /// Get organization by ID
  Future<Organization?> getOrganization(String organizationId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (doc.exists) {
        return Organization.fromFirestore(doc);
      }
      return null;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to get organization', e, stackTrace);
      return null;
    }
  }

  /// Validate organization setup data
  Map<String, String> validateOrganizationData({
    required String name,
    required String address,
    String? email,
    String? phoneNumber,
  }) {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Organization name is required';
    } else if (name.trim().length < 3) {
      errors['name'] = 'Organization name must be at least 3 characters';
    }

    if (address.trim().isEmpty) {
      errors['address'] = 'Address is required';
    } else if (address.trim().length < 5) {
      errors['address'] = 'Address must be at least 5 characters';
    }

    if (email != null && email.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        errors['email'] = 'Please enter a valid email address';
      }
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,}$');
      if (!phoneRegex.hasMatch(phoneNumber)) {
        errors['phoneNumber'] = 'Please enter a valid phone number';
      }
    }

    return errors;
  }

  /// Validate admin user data
  Map<String, String> validateAdminData({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <String, String>{};

    if (name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    } else if (name.trim().length < 2) {
      errors['name'] = 'Name must be at least 2 characters';
    }

    if (email.trim().isEmpty) {
      errors['email'] = 'Email is required';
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        errors['email'] = 'Please enter a valid email address';
      }
    }

    if (password.isEmpty) {
      errors['password'] = 'Password is required';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    }

    if (confirmPassword.isEmpty) {
      errors['confirmPassword'] = 'Please confirm your password';
    } else if (password != confirmPassword) {
      errors['confirmPassword'] = 'Passwords do not match';
    }

    return errors;
  }
}
