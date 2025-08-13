import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/organization_model.dart';
import '../data/models/user_model.dart' as app_user;
import '../services/logging_service.dart';

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
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
  /// This should be called with anonymous authentication or after user login
  Future<bool> hasExistingOrganization() async {
    try {
      // First ensure we have some kind of authentication
      if (_auth.currentUser == null) {
        // Sign in anonymously to check for existing organizations
        await _auth.signInAnonymously();
        LoggingService.info('Signed in anonymously to check organizations');
      }

      final query = await _firestore.collection('organizations').limit(1).get();
      return query.docs.isNotEmpty;
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to check existing organizations', e, stackTrace);
      // If we can't check, assume no organizations exist to allow setup
      return false;
    }
  }

  /// Create a new organization with setup progress tracking
  Future<Organization> createOrganization({
    required String name,
    required String address,
    required OrganizationType type,
    String? phoneNumber,
    String? email,
    String? website,
  }) async {
    try {
      // Ensure we have authentication - use anonymous if no user is signed in
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        LoggingService.info('Signed in anonymously for organization creation');
      }

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
        adminUserId: '', // Will be set when admin is created
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

      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user document in global users collection
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: 'admin',
        roleDescription: 'System Administrator',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());

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
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user document in global users collection
      final user = app_user.User(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: 'receptionist',
        roleDescription: 'Reception & Operations',
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toFirestore());

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
