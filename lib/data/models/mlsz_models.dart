import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for MLSZ team standings in league table
class MLSZStanding {
  final int position;
  final String teamName;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;
  final List<String> recentForm; // ['W', 'L', 'D', 'W', 'L']

  const MLSZStanding({
    required this.position,
    required this.teamName,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
    required this.recentForm,
  });

  factory MLSZStanding.fromMap(Map<String, dynamic> map) {
    return MLSZStanding(
      position: map['position'] ?? 0,
      teamName: map['teamName'] ?? '',
      matchesPlayed: map['matchesPlayed'] ?? 0,
      wins: map['wins'] ?? 0,
      draws: map['draws'] ?? 0,
      losses: map['losses'] ?? 0,
      goalsFor: map['goalsFor'] ?? 0,
      goalsAgainst: map['goalsAgainst'] ?? 0,
      goalDifference: map['goalDifference'] ?? 0,
      points: map['points'] ?? 0,
      recentForm: List<String>.from(map['recentForm'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'teamName': teamName,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalDifference': goalDifference,
      'points': points,
      'recentForm': recentForm,
    };
  }
}

/// Model for MLSZ match data
class MLSZMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchDate;
  final String venue;
  final int? homeScore;
  final int? awayScore;
  final bool isFinished;
  final int round;
  final String status; // 'upcoming', 'live', 'finished'

  const MLSZMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchDate,
    required this.venue,
    this.homeScore,
    this.awayScore,
    required this.isFinished,
    required this.round,
    required this.status,
  });

  factory MLSZMatch.fromMap(Map<String, dynamic> map) {
    return MLSZMatch(
      id: map['id'] ?? '',
      homeTeam: map['homeTeam'] ?? '',
      awayTeam: map['awayTeam'] ?? '',
      matchDate: (map['matchDate'] as Timestamp).toDate(),
      venue: map['venue'] ?? '',
      homeScore: map['homeScore'],
      awayScore: map['awayScore'],
      isFinished: map['isFinished'] ?? false,
      round: map['round'] ?? 0,
      status: map['status'] ?? 'upcoming',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'matchDate': Timestamp.fromDate(matchDate),
      'venue': venue,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'isFinished': isFinished,
      'round': round,
      'status': status,
    };
  }

  String get scoreDisplay {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  String resultForTeam(String team) {
    if (!isFinished || homeScore == null || awayScore == null)
      return 'U'; // Unknown/Upcoming

    if (team == homeTeam) {
      if (homeScore! > awayScore!) return 'W';
      if (homeScore! < awayScore!) return 'L';
      return 'D';
    } else {
      if (awayScore! > homeScore!) return 'W';
      if (awayScore! < homeScore!) return 'L';
      return 'D';
    }
  }
}

/// Model for MLSZ league configuration
class MLSZLeagueConfig {
  final String organizationId;
  final String teamName;
  final String leagueId;
  final String seasonId;
  final String categoryId;
  final String leagueName;
  final DateTime lastUpdated;
  final bool isActive;

  const MLSZLeagueConfig({
    required this.organizationId,
    required this.teamName,
    required this.leagueId,
    required this.seasonId,
    required this.categoryId,
    required this.leagueName,
    required this.lastUpdated,
    required this.isActive,
  });

  factory MLSZLeagueConfig.fromMap(Map<String, dynamic> map) {
    return MLSZLeagueConfig(
      organizationId: map['organizationId'] ?? '',
      teamName: map['teamName'] ?? '',
      leagueId: map['leagueId'] ?? '',
      seasonId: map['seasonId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      leagueName: map['leagueName'] ?? '',
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'teamName': teamName,
      'leagueId': leagueId,
      'seasonId': seasonId,
      'categoryId': categoryId,
      'leagueName': leagueName,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
    };
  }

  String get mlszUrl {
    return 'https://adatbank.mlsz.hu/league/$categoryId/$seasonId/$leagueId';
  }
}

/// Model for managing multiple team configurations
class MLSZTeamConfiguration {
  final String id; // unique identifier like "u19", "senior", "u21"
  final String displayName; // "U19 Team", "Senior Team", "U21 Team"
  final String teamName; // The actual team name in MLSZ system
  final String leagueId;
  final String seasonId;
  final String categoryId;
  final String leagueName;
  final String region; // e.g., "Pest", "Csongrád", etc.
  final String ageCategory; // e.g., "Senior", "U19", "U21", "U17"
  final String division; // e.g., "I.", "II.", "III."
  final bool isActive;
  final DateTime lastUpdated;
  final int sortOrder; // for organizing teams in UI

  const MLSZTeamConfiguration({
    required this.id,
    required this.displayName,
    required this.teamName,
    required this.leagueId,
    required this.seasonId,
    required this.categoryId,
    required this.leagueName,
    required this.region,
    required this.ageCategory,
    required this.division,
    required this.isActive,
    required this.lastUpdated,
    this.sortOrder = 0,
  });

  factory MLSZTeamConfiguration.fromMap(Map<String, dynamic> map) {
    return MLSZTeamConfiguration(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      teamName: map['teamName'] ?? '',
      leagueId: map['leagueId'] ?? '',
      seasonId: map['seasonId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      leagueName: map['leagueName'] ?? '',
      region: map['region'] ?? '',
      ageCategory: map['ageCategory'] ?? '',
      division: map['division'] ?? '',
      isActive: map['isActive'] ?? true,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      sortOrder: map['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'teamName': teamName,
      'leagueId': leagueId,
      'seasonId': seasonId,
      'categoryId': categoryId,
      'leagueName': leagueName,
      'region': region,
      'ageCategory': ageCategory,
      'division': division,
      'isActive': isActive,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'sortOrder': sortOrder,
    };
  }

  String get mlszUrl {
    return 'https://adatbank.mlsz.hu/league/$categoryId/$seasonId/$leagueId';
  }

  // Convert to legacy MLSZLeagueConfig for backward compatibility
  MLSZLeagueConfig toLegacyConfig(String organizationId) {
    return MLSZLeagueConfig(
      organizationId: organizationId,
      teamName: teamName,
      leagueId: leagueId,
      seasonId: seasonId,
      categoryId: categoryId,
      leagueName: leagueName,
      lastUpdated: lastUpdated,
      isActive: isActive,
    );
  }
}

/// Cache model for MLSZ data
class MLSZDataCache {
  final String leagueId;
  final List<MLSZStanding> standings;
  final List<MLSZMatch> matches;
  final DateTime lastFetched;
  final bool isStale;

  const MLSZDataCache({
    required this.leagueId,
    required this.standings,
    required this.matches,
    required this.lastFetched,
    required this.isStale,
  });

  factory MLSZDataCache.fromMap(Map<String, dynamic> map) {
    return MLSZDataCache(
      leagueId: map['leagueId'] ?? '',
      standings: (map['standings'] as List<dynamic>)
          .map((standing) => MLSZStanding.fromMap(standing))
          .toList(),
      matches: (map['matches'] as List<dynamic>)
          .map((match) => MLSZMatch.fromMap(match))
          .toList(),
      lastFetched: (map['lastFetched'] as Timestamp).toDate(),
      isStale: map['isStale'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leagueId': leagueId,
      'standings': standings.map((standing) => standing.toMap()).toList(),
      'matches': matches.map((match) => match.toMap()).toList(),
      'lastFetched': Timestamp.fromDate(lastFetched),
      'isStale': isStale,
    };
  }

  bool get needsRefresh {
    final cacheAge = DateTime.now().difference(lastFetched);
    return isStale || cacheAge.inHours > 2; // Refresh every 2 hours
  }
}
