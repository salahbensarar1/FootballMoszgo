import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/organization_setup_service.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/services/scoped_firestore_service.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/data/models/organization_model.dart';
import 'dart:math';

/// Service to generate realistic sample data for testing multi-tenant isolation
class SampleDataGeneratorService {
  final _setupService = OrganizationSetupService();
  final _random = Random();

  // Sample club names for different regions
  final _clubNames = [
    'FC Budapest Lions',
    'Debrecen United',
    'Szeged Athletic',
    'Pécs Football Club',
    'Győr Sports Academy',
    'Miskolc Rangers',
    'Kecskemét City FC',
    'Szombathely Warriors',
    'Eger Eagles',
    'Veszprém Valley FC',
  ];

  final _coachNames = [
    'László Kovács',
    'Péter Nagy',
    'János Szabó',
    'Zoltán Tóth',
    'András Varga',
    'Gábor Kiss',
    'Tamás Horváth',
    'Balázs Molnár',
    'Dávid Németh',
    'Máté Farkas',
    'Krisztián Balogh',
    'Viktor Papp',
  ];

  final _playerNames = [
    'Ádám Bence',
    'Zalán Máté',
    'Levente Dániel',
    'Dominik Zsombor',
    'Noel Olivér',
    'Marcell Bálint',
    'Patrik Roland',
    'Botond Krisztián',
    'Benedek Áron',
    'Milán Csaba',
    'Rafael Norbert',
    'Kevin Sándor',
    'Alex Viktor',
    'Martin László',
    'Erik Péter',
    'Zénó József',
  ];

  final _ageGroups = ['U8', 'U10', 'U12', 'U14', 'U16', 'U18', 'Senior'];

  /// Generate sample data for multiple clubs
  Future<List<String>> generateMultipleClubsData({
    int numberOfClubs = 5,
    int teamsPerClub = 3,
    int playersPerTeam = 15,
    int coachesPerClub = 4,
  }) async {
    try {
      LoggingService.info('🏗️ Starting multi-club data generation...');
      LoggingService.info(
          '📊 Plan: $numberOfClubs clubs, $teamsPerClub teams each, $playersPerTeam players per team');

      final createdClubIds = <String>[];

      for (int i = 0; i < numberOfClubs; i++) {
        final clubName = _clubNames[i % _clubNames.length];
        LoggingService.info(
            '🏢 Creating club ${i + 1}/$numberOfClubs: $clubName');

        try {
          final orgId = await _generateSingleClubData(
            clubName: clubName,
            clubIndex: i,
            numberOfTeams: teamsPerClub,
            playersPerTeam: playersPerTeam,
            numberOfCoaches: coachesPerClub,
          );

          createdClubIds.add(orgId);
          LoggingService.info(
              '✅ Club created successfully: $clubName ($orgId)');

          // Small delay to avoid overwhelming Firebase
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          LoggingService.error('❌ Failed to create club: $clubName', e);
          // Continue with next club instead of failing completely
        }
      }

      LoggingService.info(
          '🎉 Multi-club generation completed! Created ${createdClubIds.length} clubs');
      return createdClubIds;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Multi-club generation failed', e, stackTrace);
      rethrow;
    }
  }

  /// Generate data for a single club
  Future<String> _generateSingleClubData({
    required String clubName,
    required int clubIndex,
    required int numberOfTeams,
    required int playersPerTeam,
    required int numberOfCoaches,
  }) async {
    // 1. Create organization with admin
    final adminEmail =
        'admin${clubIndex + 1}@${_sanitizeForEmail(clubName)}.com';
    final adminPassword = 'admin123'; // For testing only!

    final setupResult = await _setupService.createCompleteOrganizationSetup(
      organizationName: clubName,
      organizationAddress: _generateRandomAddress(),
      organizationType: OrganizationType.club,
      adminName: 'Admin ${clubIndex + 1}',
      adminEmail: adminEmail,
      adminPassword: adminPassword,
      organizationPhone: _generateRandomPhone(),
      organizationEmailContact:
          'contact${clubIndex + 1}@${_sanitizeForEmail(clubName)}.com',
    );

    if (!setupResult.success || setupResult.organization == null) {
      throw Exception('Failed to create organization: ${setupResult.error}');
    }

    final orgId = setupResult.organization!.id;

    // Initialize organization context for this club
    await OrganizationContext.setCurrentOrganization(orgId);

    // 2. Create additional coaches
    final coachIds = <String>[];
    for (int i = 0; i < numberOfCoaches; i++) {
      final coachId = await _createCoach(clubIndex, i);
      coachIds.add(coachId);
    }

    // 3. Create teams
    final teamIds = <String>[];
    for (int i = 0; i < numberOfTeams; i++) {
      final teamId = await _createTeam(clubIndex, i, coachIds);
      teamIds.add(teamId);
    }

    // 4. Create players for each team
    for (int teamIndex = 0; teamIndex < teamIds.length; teamIndex++) {
      await _createPlayersForTeam(
          teamIds[teamIndex], teamIndex, playersPerTeam, clubIndex);
    }

    // 5. Create some training sessions
    for (final teamId in teamIds) {
      await _createTrainingSessionsForTeam(teamId, clubIndex);
    }

    LoggingService.info('📋 Club data summary:');
    LoggingService.info('  - Organization: $clubName ($orgId)');
    LoggingService.info('  - Admin: $adminEmail / $adminPassword');
    LoggingService.info('  - Coaches: ${coachIds.length}');
    LoggingService.info('  - Teams: ${teamIds.length}');
    LoggingService.info(
        '  - Total players: ${teamIds.length * playersPerTeam}');

    return orgId;
  }

  Future<String> _createCoach(int clubIndex, int coachIndex) async {
    final coachName = _coachNames[_random.nextInt(_coachNames.length)];
    final coachEmail =
        'coach${coachIndex + 1}.club${clubIndex + 1}@example.com';

    final coachRef =
        await ScopedFirestoreService.createScopedDocument('users', {
      'name': coachName,
      'email': coachEmail,
      'role': 'coach',
      'role_description': 'Team Coach',
      'is_active': true,
      'phone': _generateRandomPhone(),
      'experience_years': _random.nextInt(15) + 1,
      'certifications':
          _random.nextBool() ? ['UEFA B', 'First Aid'] : ['Basic Coaching'],
    });

    return coachRef.id;
  }

  Future<String> _createTeam(
      int clubIndex, int teamIndex, List<String> availableCoaches) async {
    final ageGroup = _ageGroups[teamIndex % _ageGroups.length];
    final teamName =
        '$ageGroup Team ${String.fromCharCode(65 + teamIndex)}'; // A, B, C...

    final assignedCoach =
        availableCoaches[_random.nextInt(availableCoaches.length)];

    final teamRef = await ScopedFirestoreService.createScopedDocument('teams', {
      'name': teamName,
      'age_group': ageGroup,
      'coach_ids': [assignedCoach],
      'coaches': [
        {
          'userId': assignedCoach,
          'role': 'head_coach',
          'assigned_at': FieldValue.serverTimestamp(),
        }
      ],
      'is_active': true,
      'number_of_players': 0, // Will be updated as players are added
      'training_schedule': {
        'monday': {'time': '17:00', 'duration': 90},
        'wednesday': {'time': '17:00', 'duration': 90},
        'friday': {'time': '17:00', 'duration': 90},
      },
      'payment_fee': _generateRandomFee(),
      'currency': 'HUF',
      'season': DateTime.now().year.toString(),
    });

    return teamRef.id;
  }

  Future<void> _createPlayersForTeam(
      String teamId, int teamIndex, int numberOfPlayers, int clubIndex) async {
    final batch = FirebaseFirestore.instance.batch();
    int createdCount = 0;

    for (int i = 0; i < numberOfPlayers; i++) {
      final playerName = _playerNames[_random.nextInt(_playerNames.length)];
      final age = _calculateAgeFromTeamIndex(teamIndex);

      final playerRef = ScopedFirestoreService.getCollection('players').doc();

      batch.set(playerRef, {
        'name': playerName,
        'team_id': teamId,
        'age': age,
        'date_of_birth': _generateDateOfBirth(age),
        'position': _generateRandomPosition(),
        'jersey_number': i + 1,
        'parent_name': 'Parent of $playerName',
        'parent_phone': _generateRandomPhone(),
        'parent_email':
            'parent${i + 1}.team${teamIndex + 1}.club${clubIndex + 1}@example.com',
        'emergency_contact': {
          'name': 'Emergency Contact',
          'phone': _generateRandomPhone(),
          'relationship': 'Guardian',
        },
        'is_active': true,
        'registration_date': FieldValue.serverTimestamp(),
        'payment_status': _random.nextBool() ? 'current' : 'overdue',
        'organization_id': OrganizationContext.currentOrgId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      createdCount++;
    }

    await batch.commit();

    // Update team player count
    await ScopedFirestoreService.updateScopedDocument('teams', teamId, {
      'number_of_players': numberOfPlayers,
    });

    LoggingService.info('👥 Created $createdCount players for team $teamId');
  }

  Future<void> _createTrainingSessionsForTeam(
      String teamId, int clubIndex) async {
    // Create a few training sessions in the past month
    final now = DateTime.now();

    for (int i = 0; i < 8; i++) {
      final sessionDate = now.subtract(Duration(days: i * 3 + 1));

      await ScopedFirestoreService.createScopedDocument('training_sessions', {
        'team_id': teamId,
        'date': Timestamp.fromDate(sessionDate),
        'start_time': Timestamp.fromDate(sessionDate),
        'end_time': Timestamp.fromDate(
            sessionDate.add(const Duration(hours: 1, minutes: 30))),
        'location': 'Training Ground ${clubIndex + 1}',
        'training_type': _getRandomTrainingType(),
        'description': 'Regular team training session',
        'attendance': [], // Would be populated during session
        'notes': 'Good training session with focus on ball control',
        'weather': _getRandomWeather(),
      });
    }
  }

  // Utility methods
  String _sanitizeForEmail(String input) {
    return input
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _generateRandomAddress() {
    final streets = [
      'Fő utca',
      'Petőfi utca',
      'Kossuth utca',
      'József Attila utca'
    ];
    final street = streets[_random.nextInt(streets.length)];
    final number = _random.nextInt(100) + 1;
    return '$street $number, Budapest';
  }

  String _generateRandomPhone() {
    return '+36 30 ${_random.nextInt(900) + 100} ${_random.nextInt(9000) + 1000}';
  }

  double _generateRandomFee() {
    final fees = [2500.0, 3000.0, 3500.0, 4000.0, 4500.0];
    return fees[_random.nextInt(fees.length)];
  }

  int _calculateAgeFromTeamIndex(int teamIndex) {
    // Map team index to age groups
    switch (teamIndex % _ageGroups.length) {
      case 0:
        return 7 + _random.nextInt(2); // U8: 6-8
      case 1:
        return 9 + _random.nextInt(2); // U10: 8-10
      case 2:
        return 11 + _random.nextInt(2); // U12: 10-12
      case 3:
        return 13 + _random.nextInt(2); // U14: 12-14
      case 4:
        return 15 + _random.nextInt(2); // U16: 14-16
      case 5:
        return 17 + _random.nextInt(2); // U18: 16-18
      default:
        return 20 + _random.nextInt(10); // Senior: 18-28
    }
  }

  Timestamp _generateDateOfBirth(int age) {
    final now = DateTime.now();
    final birthYear = now.year - age;
    final birthDate =
        DateTime(birthYear, _random.nextInt(12) + 1, _random.nextInt(28) + 1);
    return Timestamp.fromDate(birthDate);
  }

  String _generateRandomPosition() {
    final positions = ['Goalkeeper', 'Defender', 'Midfielder', 'Forward'];
    return positions[_random.nextInt(positions.length)];
  }

  String _getRandomTrainingType() {
    final types = [
      'Technical Skills',
      'Physical Conditioning',
      'Tactical Training',
      'Scrimmage'
    ];
    return types[_random.nextInt(types.length)];
  }

  String _getRandomWeather() {
    final weather = ['Sunny', 'Cloudy', 'Light Rain', 'Overcast'];
    return weather[_random.nextInt(weather.length)];
  }

  /// Generate test credentials for all created clubs
  Future<List<Map<String, String>>> generateTestCredentials(
      int numberOfClubs) async {
    final credentials = <Map<String, String>>[];

    for (int i = 0; i < numberOfClubs; i++) {
      final clubName = _clubNames[i % _clubNames.length];
      credentials.add({
        'club_name': clubName,
        'admin_email': 'admin${i + 1}@${_sanitizeForEmail(clubName)}.com',
        'admin_password': 'admin123',
        'description': 'Admin account for $clubName',
      });
    }

    return credentials;
  }
}
