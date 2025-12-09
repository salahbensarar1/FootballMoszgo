import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/data/models/mlsz_models.dart';
import 'dart:math' as Math;

class MLSZIntegrationService {
  static const String _baseUrl = 'https://adatbank.mlsz.hu';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Your existing testConnection method...

  /// Save team configuration to Firestore
  static Future<void> saveConfiguration(MLSZLeagueConfig config) async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) throw Exception('Organization not initialized');

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('mlsz_config')
          .doc('current')
          .set(config.toMap());

      LoggingService.info('✅ MLSZ configuration saved');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to save MLSZ config', e, stackTrace);
      rethrow;
    }
  }

  /// Get team configuration from Firestore
  static Future<MLSZLeagueConfig?> getConfiguration() async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return null;

      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('mlsz_config')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      return MLSZLeagueConfig.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to load MLSZ config', e, stackTrace);
      return null;
    }
  }

  /// Save multiple team configurations
  static Future<void> saveTeamConfiguration(MLSZTeamConfiguration config) async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) throw Exception('Organization not initialized');

      await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('mlsz_teams')
          .doc(config.id)
          .set(config.toMap());

      LoggingService.info('✅ Team configuration saved: ${config.displayName}');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to save team config', e, stackTrace);
      rethrow;
    }
  }

  /// Get all team configurations for the organization
  static Future<List<MLSZTeamConfiguration>> getAllTeamConfigurations() async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return [];

      final snapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('mlsz_teams')
          .where('isActive', isEqualTo: true)
          .get();

      final teams = snapshot.docs
          .map((doc) => MLSZTeamConfiguration.fromMap(doc.data()))
          .toList();

      // Sort by sortOrder then displayName
      teams.sort((a, b) {
        final orderComparison = a.sortOrder.compareTo(b.sortOrder);
        if (orderComparison != 0) return orderComparison;
        return a.displayName.compareTo(b.displayName);
      });

      return teams;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to load team configs', e, stackTrace);
      return [];
    }
  }

  /// Get a specific team configuration
  static Future<MLSZTeamConfiguration?> getTeamConfiguration(String teamId) async {
    try {
      final orgId = OrganizationContext.currentOrgId;
      if (orgId == null) return null;

      final doc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('mlsz_teams')
          .doc(teamId)
          .get();

      if (!doc.exists) return null;

      return MLSZTeamConfiguration.fromMap(doc.data()!);
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to load team config: $teamId', e, stackTrace);
      return null;
    }
  }

  /// Fetch standings for a specific team
  static Future<List<MLSZStanding>> fetchStandingsForTeam(MLSZTeamConfiguration teamConfig) async {
    try {
      final url = '${teamConfig.mlszUrl}/13.html';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Charset': 'utf-8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      final document = html.parse(response.body);
      final tables = document.querySelectorAll('table');
      if (tables.length < 6) throw Exception('Not enough tables found');

      final standingsTable = tables[5];
      final rows = standingsTable.querySelectorAll('tr');
      final standings = <MLSZStanding>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        if (cells.length < 11) continue;

        try {
          final standing = MLSZStanding(
            position: int.tryParse(cells[0].text.trim()) ?? i,
            teamName: _smartFixEncoding(cells[2].text.trim()),
            matchesPlayed: int.tryParse(cells[3].text.trim()) ?? 0,
            wins: int.tryParse(cells[4].text.trim()) ?? 0,
            draws: int.tryParse(cells[5].text.trim()) ?? 0,
            losses: int.tryParse(cells[6].text.trim()) ?? 0,
            goalsFor: int.tryParse(cells[7].text.trim()) ?? 0,
            goalsAgainst: int.tryParse(cells[8].text.trim()) ?? 0,
            goalDifference: int.tryParse(cells[9].text.trim()) ?? 0,
            points: int.tryParse(cells[10].text.trim()) ?? 0,
            recentForm: [],
          );

          standings.add(standing);
        } catch (e) {
          LoggingService.warning('⚠️ Failed to parse row $i: $e');
          continue;
        }
      }

      LoggingService.info('✅ Parsed ${standings.length} teams for ${teamConfig.displayName}');
      return standings;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to fetch standings for ${teamConfig.displayName}', e, stackTrace);
      rethrow;
    }
  }

  /// Fetch real standings from MLSZ website
  static Future<List<MLSZStanding>> fetchStandings() async {
    try {
      final config = await getConfiguration();
      if (config == null) throw Exception('No configuration found');

      final url = '${config.mlszUrl}/13.html';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept-Charset': 'utf-8',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      // Just use response.body directly - simpler approach like Python
      final document = html.parse(response.body);

      // Get all tables and find the standings table (Table 5)
      final tables = document.querySelectorAll('table');
      if (tables.length < 6) throw Exception('Not enough tables found');

      // Table 5 contains the league standings
      final standingsTable = tables[5];
      final rows = standingsTable.querySelectorAll('tr');

      final standings = <MLSZStanding>[];

      // Skip header row (start from index 1)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final cells = row.querySelectorAll('td');

        if (cells.length < 11) continue; // Need at least 11 cells

        try {
          final standing = MLSZStanding(
            position: int.tryParse(cells[0].text.trim()) ?? i,
            teamName: _smartFixEncoding(cells[2].text.trim()), // Cell 2 has team name
            matchesPlayed: int.tryParse(cells[3].text.trim()) ?? 0,
            wins: int.tryParse(cells[4].text.trim()) ?? 0,
            draws: int.tryParse(cells[5].text.trim()) ?? 0,
            losses: int.tryParse(cells[6].text.trim()) ?? 0,
            goalsFor: int.tryParse(cells[7].text.trim()) ?? 0,
            goalsAgainst: int.tryParse(cells[8].text.trim()) ?? 0,
            goalDifference: int.tryParse(cells[9].text.trim()) ?? 0,
            points: int.tryParse(cells[10].text.trim()) ?? 0,
            recentForm: [], // We'll add this later
          );

          standings.add(standing);
        } catch (e) {
          LoggingService.warning('⚠️ Failed to parse row $i: $e');
          continue;
        }
      }

      LoggingService.info('✅ Parsed ${standings.length} teams from Table 5');
      return standings;
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to fetch standings', e, stackTrace);
      rethrow;
    }
  }

  /// Smart encoding fix - only apply if text appears corrupted
  static String _smartFixEncoding(String text) {
    String result = text.trim();

    // First, check if the text actually needs fixing
    // If it contains common encoding corruption patterns, then fix it
    bool needsFix = result.contains('Ã') ||
                   result.contains('Å') ||
                   result.contains('&') ||
                   result.contains('?');

    if (!needsFix) {
      return result; // Return as-is if it looks fine
    }

    // Only apply fixes if corruption is detected
    result = result
        .replaceAll('Ã¡', 'á') // á - a with acute
        .replaceAll('Ã©', 'é') // é - e with acute
        .replaceAll('Ã­', 'í') // í - i with acute
        .replaceAll('Ã³', 'ó') // ó - o with acute
        .replaceAll('Ã¶', 'ö') // ö - o with diaeresis
        .replaceAll('Ã¼', 'ü') // ü - u with diaeresis
        .replaceAll('Å\u0091', '\u0151') // ő - o with double acute
        .replaceAll('Å±', '\u0171') // ű - u with double acute
        // Upper case versions
        .replaceAll('Ã\u0081', 'Á') // Á
        .replaceAll('Ã‰', 'É') // É
        .replaceAll('Ã\u008D', 'Í') // Í
        .replaceAll('Ã"', 'Ó') // Ó
        .replaceAll('Ã–', 'Ö') // Ö
        .replaceAll('Ã\u009C', 'Ü') // Ü
        .replaceAll('Å\u0090', '\u0150') // Ő
        .replaceAll('Å°', '\u0170') // Ű
        // HTML entities
        .replaceAll('&aacute;', 'á')
        .replaceAll('&eacute;', 'é')
        .replaceAll('&iacute;', 'í')
        .replaceAll('&oacute;', 'ó')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    return result;
  }

  /// Debug version to see HTML structure
  static Future<void> debugHTMLStructure() async {
    try {
      final config = await getConfiguration();
      if (config == null) throw Exception('No configuration found');

      final url = '${config.mlszUrl}/13.html';
      final response = await http.get(Uri.parse(url));
      final document = html.parse(response.body);

      // Debug: Find all table elements
      final tables = document.querySelectorAll('table');
      print('🔍 Found ${tables.length} tables');

      for (int tableIndex = 0; tableIndex < tables.length; tableIndex++) {
        final table = tables[tableIndex];
        final rows = table.querySelectorAll('tr');
        print('\n📊 Table $tableIndex has ${rows.length} rows');

        // Look at first few data rows (skip header)
        for (int rowIndex = 1;
            rowIndex < Math.min(4, rows.length);
            rowIndex++) {
          final row = rows[rowIndex];
          final cells = row.querySelectorAll('td');

          print('Row $rowIndex has ${cells.length} cells:');
          for (int cellIndex = 0;
              cellIndex < Math.min(12, cells.length);
              cellIndex++) {
            final cellText = cells[cellIndex].text.trim();
            final cellHTML = cells[cellIndex].innerHtml;
            print('  Cell $cellIndex: "$cellText"');
            if (cellHTML.contains('img') || cellHTML.contains('<')) {
              print(
                  '    HTML: ${cellHTML.substring(0, Math.min(100, cellHTML.length))}');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// Create sample team configurations for testing
  static Future<void> createSampleTeamConfigurations() async {
    try {
      final sampleTeams = [
        MLSZTeamConfiguration(
          id: 'senior',
          displayName: 'Senior Team',
          teamName: 'MozGo-Nagykörös SE',
          leagueId: '31019',
          seasonId: '14',
          categoryId: '65',
          leagueName: 'III. osztályú felnőtt bajnokság, Délkelet csoport',
          region: 'Pest',
          ageCategory: 'Senior',
          division: 'III.',
          isActive: true,
          lastUpdated: DateTime.now(),
          sortOrder: 1,
        ),
        MLSZTeamConfiguration(
          id: 'u19',
          displayName: 'U19 Team',
          teamName: 'MozGo-Nagykörös SE U19',
          leagueId: '31020',
          seasonId: '14',
          categoryId: '66',
          leagueName: 'U19 bajnokság, Pest megye',
          region: 'Pest',
          ageCategory: 'U19',
          division: 'I.',
          isActive: true,
          lastUpdated: DateTime.now(),
          sortOrder: 2,
        ),
        MLSZTeamConfiguration(
          id: 'u17',
          displayName: 'U17 Team',
          teamName: 'MozGo-Nagykörös SE U17',
          leagueId: '31021',
          seasonId: '14',
          categoryId: '67',
          leagueName: 'U17 bajnokság, Pest megye',
          region: 'Pest',
          ageCategory: 'U17',
          division: 'I.',
          isActive: true,
          lastUpdated: DateTime.now(),
          sortOrder: 3,
        ),
      ];

      for (final team in sampleTeams) {
        await saveTeamConfiguration(team);
      }

      LoggingService.info('✅ Sample team configurations created');
    } catch (e, stackTrace) {
      LoggingService.error('❌ Failed to create sample configs', e, stackTrace);
      rethrow;
    }
  }

  /// Get unique regions from team configurations
  static Future<List<String>> getAvailableRegions() async {
    try {
      final teams = await getAllTeamConfigurations();
      final regions = teams.map((team) => team.region).toSet().toList();
      regions.sort();
      return regions;
    } catch (e) {
      LoggingService.error('❌ Failed to get regions', e);
      return [];
    }
  }

  /// Get unique age categories from team configurations
  static Future<List<String>> getAvailableAgeCategories() async {
    try {
      final teams = await getAllTeamConfigurations();
      final categories = teams.map((team) => team.ageCategory).toSet().toList();
      categories.sort((a, b) {
        // Custom sort: Senior first, then U21, U19, U17, etc.
        if (a == 'Senior') return -1;
        if (b == 'Senior') return 1;
        if (a.startsWith('U') && b.startsWith('U')) {
          final numA = int.tryParse(a.substring(1)) ?? 0;
          final numB = int.tryParse(b.substring(1)) ?? 0;
          return numB.compareTo(numA); // Descending order for U categories
        }
        return a.compareTo(b);
      });
      return categories;
    } catch (e) {
      LoggingService.error('❌ Failed to get age categories', e);
      return [];
    }
  }

  /// Get unique divisions from team configurations
  static Future<List<String>> getAvailableDivisions() async {
    try {
      final teams = await getAllTeamConfigurations();
      final divisions = teams.map((team) => team.division).toSet().toList();
      divisions.sort();
      return divisions;
    } catch (e) {
      LoggingService.error('❌ Failed to get divisions', e);
      return [];
    }
  }

  /// Filter teams by criteria (like MLSZ website)
  static List<MLSZTeamConfiguration> filterTeams(
    List<MLSZTeamConfiguration> teams, {
    String? region,
    String? ageCategory,
    String? division,
  }) {
    return teams.where((team) {
      if (region != null && team.region != region) return false;
      if (ageCategory != null && team.ageCategory != ageCategory) return false;
      if (division != null && team.division != division) return false;
      return true;
    }).toList();
  }
}
