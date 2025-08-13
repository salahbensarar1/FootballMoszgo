import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/organization_model.dart';
import '../data/models/user_model.dart' as app_user;
import 'logging_service.dart';

/// SaaS-ready onboarding service for instant club setup
class SaaSOnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Complete club setup in one flow
  Future<ClubOnboardingResult> setupNewClub({
    required String clubName,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String clubAddress,
    required String clubPhone,
    required OrganizationType clubType,
    String? receptionistName,
    String? receptionistEmail,
    List<String> initialTeams = const [],
    double monthlyFee = 10000,
    String currency = 'HUF',
  }) async {
    try {
      // 1. Create organization with unique slug
      final organization = await _createOrganization(
        name: clubName,
        address: clubAddress,
        phone: clubPhone,
        type: clubType,
      );

      // 2. Create admin user
      final admin = await _createAdminUser(
        organizationId: organization.id,
        name: adminName,
        email: adminEmail,
        password: adminPassword,
      );

      // 3. Create default receptionist if provided
      app_user.User? receptionist;
      if (receptionistName != null && receptionistEmail != null) {
        receptionist = await _createReceptionistUser(
          organizationId: organization.id,
          name: receptionistName,
          email: receptionistEmail,
          password: _generateSecurePassword(),
        );
      }

      // 4. Create initial teams
      final teams = await _createInitialTeams(
        organizationId: organization.id,
        teamNames: initialTeams.isNotEmpty ? initialTeams : _getDefaultTeams(),
        monthlyFee: monthlyFee,
        currency: currency,
      );

      // 5. Create sample data for demo purposes
      await _createSampleData(organization.id, teams);

      // 6. Set up organization settings
      await _setupOrganizationDefaults(organization.id, currency, monthlyFee);

      // 7. Create subscription record
      await _createTrialSubscription(organization.id);

      LoggingService.info(
          'Club setup completed successfully: ${organization.name}');

      return ClubOnboardingResult(
        organization: organization,
        admin: admin,
        receptionist: receptionist,
        teams: teams,
        adminPassword: adminPassword,
        receptionistPassword:
            receptionist != null ? _lastGeneratedPassword : null,
        isSuccess: true,
      );
    } catch (e, stackTrace) {
      LoggingService.error('Club setup failed', e, stackTrace);
      return ClubOnboardingResult(
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  String _lastGeneratedPassword = '';

  String _generateSecurePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final password =
        List.generate(8, (index) => chars[(random + index) % chars.length])
            .join();
    _lastGeneratedPassword = password;
    return password;
  }

  List<String> _getDefaultTeams() {
    return [
      'U6 Beginners',
      'U8 Junior',
      'U10 Youth',
      'U12 Intermediate',
      'U14 Advanced'
    ];
  }

  Future<Organization> _createOrganization({
    required String name,
    required String address,
    required String phone,
    required OrganizationType type,
  }) async {
    try {
      // Ensure we have authentication - use anonymous if no user is signed in
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        LoggingService.info('Signed in anonymously for organization creation');
      }

      final organizationRef = _firestore.collection('organizations').doc();
      final slug = _generateSlug(name);

      final organization = Organization(
        id: organizationRef.id,
        name: name,
        slug: slug,
        address: address,
        phoneNumber: phone,
        type: type,
        adminUserId: '',
        createdAt: DateTime.now(),
        status: 'trial', // Start with trial
        timezone: 'Europe/Budapest',
        defaultCurrency: 'HUF',
        settings: {
          'trial_expires':
              DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'features_enabled': [
            'basic_management',
            'payment_tracking',
            'reports'
          ],
          'max_players': 100,
          'max_teams': 10,
        },
      );

      await organizationRef.set(organization.toFirestore());
      return organization;
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to create organization in SaaS service', e, stackTrace);
      rethrow;
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<app_user.User> _createAdminUser({
    required String organizationId,
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Sign out from anonymous account if present
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        await _auth.signOut();
        LoggingService.info(
            'Signed out from anonymous account before creating admin');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = app_user.User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        role: 'admin',
        roleDescription: 'Club Administrator',
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Save to organization-scoped users collection
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());

      // Update organization with admin ID
      await _firestore.collection('organizations').doc(organizationId).update({
        'admin_user_id': user.id,
      });

      return user;
    } catch (e, stackTrace) {
      LoggingService.error(
          'Failed to create admin user in SaaS service', e, stackTrace);
      rethrow;
    }
  }

  Future<app_user.User> _createReceptionistUser({
    required String organizationId,
    required String name,
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = app_user.User(
      id: userCredential.user!.uid,
      name: name,
      email: email,
      role: 'receptionist',
      roleDescription: 'Club Receptionist',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('users')
        .doc(user.id)
        .set(user.toFirestore());

    return user;
  }

  Future<List<Map<String, dynamic>>> _createInitialTeams({
    required String organizationId,
    required List<String> teamNames,
    required double monthlyFee,
    required String currency,
  }) async {
    final teams = <Map<String, dynamic>>[];

    for (String teamName in teamNames) {
      final teamRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('teams')
          .doc();

      final teamData = {
        'id': teamRef.id,
        'name': teamName,
        'description': 'Auto-created team',
        'monthly_fee': monthlyFee,
        'currency': currency,
        'coach_id': null,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'player_count': 0,
        'max_players': 25,
      };

      await teamRef.set(teamData);
      teams.add(teamData);
    }

    return teams;
  }

  Future<void> _createSampleData(
      String organizationId, List<Map<String, dynamic>> teams) async {
    // Create 2-3 sample players per team for demonstration
    for (var team in teams.take(2)) {
      await _createSamplePlayers(organizationId, team['id'], team['name']);
    }
  }

  Future<void> _createSamplePlayers(
      String organizationId, String teamId, String teamName) async {
    final samplePlayers = [
      {'name': 'John Doe', 'age': 8},
      {'name': 'Jane Smith', 'age': 9},
      {'name': 'Mike Johnson', 'age': 8},
    ];

    for (var player in samplePlayers) {
      final playerRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('players')
          .doc();

      await playerRef.set({
        'id': playerRef.id,
        'name': player['name'],
        'age': player['age'],
        'team_id': teamId,
        'team_name': teamName,
        'parent_name': 'Parent of ${player['name']}',
        'parent_phone': '+36 30 123 4567',
        'parent_email':
            '${player['name'].toString().toLowerCase().replaceAll(' ', '.')}@example.com',
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'payment_status': 'unpaid',
        'notes': 'Demo player - created during setup',
      });
    }
  }

  Future<void> _setupOrganizationDefaults(
      String organizationId, String currency, double monthlyFee) async {
    await _firestore.collection('organizations').doc(organizationId).update({
      'settings.default_currency': currency,
      'settings.default_monthly_fee': monthlyFee,
      'settings.payment_due_day': 5, // 5th of each month
      'settings.late_fee_percentage': 5.0,
      'settings.send_reminders': true,
      'settings.reminder_days_before': [7, 3, 1],
    });
  }

  Future<void> _createTrialSubscription(String organizationId) async {
    final subscriptionRef = _firestore.collection('subscriptions').doc();

    await subscriptionRef.set({
      'id': subscriptionRef.id,
      'organization_id': organizationId,
      'plan': 'trial',
      'status': 'active',
      'started_at': FieldValue.serverTimestamp(),
      'expires_at': Timestamp.fromDate(DateTime.now().add(Duration(days: 30))),
      'features': {
        'max_players': 100,
        'max_teams': 10,
        'max_coaches': 5,
        'payment_tracking': true,
        'reports': true,
        'api_access': false,
        'custom_branding': false,
      },
      'billing': {
        'currency': 'USD',
        'amount': 0, // Trial is free
        'interval': 'monthly',
      },
    });
  }
}

class ClubOnboardingResult {
  final Organization? organization;
  final app_user.User? admin;
  final app_user.User? receptionist;
  final List<Map<String, dynamic>>? teams;
  final String? adminPassword;
  final String? receptionistPassword;
  final bool isSuccess;
  final String? error;

  ClubOnboardingResult({
    this.organization,
    this.admin,
    this.receptionist,
    this.teams,
    this.adminPassword,
    this.receptionistPassword,
    required this.isSuccess,
    this.error,
  });
}
