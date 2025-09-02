import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/organization_context.dart';
import '../services/logging_service.dart';
import '../services/batched_firestore_service.dart';

/// Service for managing pre-aggregated payment statistics
class AggregatedPaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get monthly payment summary from aggregated document
  static Future<MonthlyPaymentSummary> getMonthlyPaymentSummary(
    String year, 
    String month,
  ) async {
    OrganizationContext.enforceContext();

    try {
      final aggregateRef = OrganizationContext
          .getCollection('payment_aggregates')
          .doc('$year-$month');
      
      final doc = await aggregateRef.get();
      
      if (doc.exists) {
        LoggingService.info('Using cached payment summary for $year-$month');
        return MonthlyPaymentSummary.fromFirestore(doc);
      } else {
        LoggingService.info('Computing payment summary for $year-$month (no cache)');
        return await _computeAndCacheMonthlyPayments(year, month);
      }
    } catch (e, stackTrace) {
      LoggingService.error('Failed to get monthly payment summary', e, stackTrace);
      rethrow;
    }
  }

  /// Compute payment summary and cache it
  static Future<MonthlyPaymentSummary> _computeAndCacheMonthlyPayments(
    String year, 
    String month,
  ) async {
    try {
      // Get all players with their payments for the month
      final playersWithPayments = await BatchedFirestoreService
          .readPlayersWithPayments(year, month);

      // Aggregate statistics
      int totalPlayers = playersWithPayments.length;
      int paidPlayers = 0;
      int partialPlayers = 0;
      int unpaidPlayers = 0;
      int inactivePlayers = 0;
      double totalAmount = 0.0;
      double paidAmount = 0.0;
      Map<String, TeamPaymentStats> teamStats = {};

      for (final playerPayment in playersWithPayments) {
        final teamName = playerPayment.teamName;
        final paymentData = playerPayment.paymentData;
        
        // Initialize team stats if not exists
        teamStats.putIfAbsent(teamName, () => TeamPaymentStats(
          teamName: teamName,
          totalPlayers: 0,
          paidPlayers: 0,
          partialPlayers: 0,
          unpaidPlayers: 0,
          inactivePlayers: 0,
          totalRevenue: 0.0,
        ));

        teamStats[teamName]!.totalPlayers++;

        if (paymentData == null || paymentData['isActive'] == false) {
          inactivePlayers++;
          teamStats[teamName]!.inactivePlayers++;
        } else {
          final isPaid = paymentData['isPaid'] == true;
          final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
          final isPartial = paymentData['isPartial'] == true;
          
          totalAmount += amount;

          if (isPaid) {
            paidPlayers++;
            paidAmount += amount;
            teamStats[teamName]!.paidPlayers++;
            teamStats[teamName]!.totalRevenue += amount;
          } else if (isPartial) {
            partialPlayers++;
            paidAmount += amount;
            teamStats[teamName]!.partialPlayers++;
            teamStats[teamName]!.totalRevenue += amount;
          } else {
            unpaidPlayers++;
            teamStats[teamName]!.unpaidPlayers++;
          }
        }
      }

      final summary = MonthlyPaymentSummary(
        year: year,
        month: month,
        totalPlayers: totalPlayers,
        paidPlayers: paidPlayers,
        partialPlayers: partialPlayers,
        unpaidPlayers: unpaidPlayers,
        inactivePlayers: inactivePlayers,
        totalExpected: totalAmount,
        totalCollected: paidAmount,
        outstandingAmount: totalAmount - paidAmount,
        teamStatistics: teamStats.values.toList(),
        lastUpdated: DateTime.now(),
        organizationId: OrganizationContext.currentOrgId,
      );

      // Cache the computed summary
      await _cachePaymentSummary(summary);
      
      return summary;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to compute monthly payments', e, stackTrace);
      rethrow;
    }
  }

  /// Cache computed payment summary
  static Future<void> _cachePaymentSummary(MonthlyPaymentSummary summary) async {
    try {
      final aggregateRef = OrganizationContext
          .getCollection('payment_aggregates')
          .doc('${summary.year}-${summary.month}');
      
      await aggregateRef.set(summary.toFirestore());
      LoggingService.info('Cached payment summary for ${summary.year}-${summary.month}');
    } catch (e, stackTrace) {
      LoggingService.warning('Failed to cache payment summary', e, stackTrace);
      // Don't rethrow - caching failure shouldn't break the operation
    }
  }

  /// Invalidate cached payment summary (call when payments are updated)
  static Future<void> invalidateMonthlyCache(String year, String month) async {
    try {
      final aggregateRef = OrganizationContext
          .getCollection('payment_aggregates')
          .doc('$year-$month');
      
      await aggregateRef.delete();
      LoggingService.info('Invalidated payment cache for $year-$month');
    } catch (e, stackTrace) {
      LoggingService.warning('Failed to invalidate payment cache', e, stackTrace);
    }
  }

  /// Get annual payment summary
  static Future<AnnualPaymentSummary> getAnnualPaymentSummary(String year) async {
    OrganizationContext.enforceContext();

    try {
      final futures = List.generate(12, (index) {
        final month = (index + 1).toString().padLeft(2, '0');
        return getMonthlyPaymentSummary(year, month);
      });

      final monthlySummaries = await Future.wait(futures);
      
      // Aggregate annual statistics
      int totalPlayers = 0;
      int totalPaidCount = 0;
      double totalRevenue = 0.0;
      double totalExpected = 0.0;
      Map<String, double> monthlyRevenue = {};

      for (int i = 0; i < monthlySummaries.length; i++) {
        final summary = monthlySummaries[i];
        final monthKey = (i + 1).toString().padLeft(2, '0');
        
        totalPlayers = summary.totalPlayers; // Use latest count
        totalPaidCount += summary.paidPlayers;
        totalRevenue += summary.totalCollected;
        totalExpected += summary.totalExpected;
        monthlyRevenue[monthKey] = summary.totalCollected;
      }

      return AnnualPaymentSummary(
        year: year,
        totalPlayers: totalPlayers,
        totalExpectedRevenue: totalExpected,
        totalCollectedRevenue: totalRevenue,
        collectionRate: totalExpected > 0 ? (totalRevenue / totalExpected) : 0.0,
        monthlyBreakdown: monthlyRevenue,
        monthlySummaries: monthlySummaries,
        organizationId: OrganizationContext.currentOrgId,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      LoggingService.error('Failed to get annual payment summary', e, stackTrace);
      rethrow;
    }
  }

  /// Pre-compute payment aggregates for performance (call from Cloud Function)
  static Future<void> preComputePaymentAggregates(String year, String month) async {
    LoggingService.info('Pre-computing payment aggregates for $year-$month');
    await _computeAndCacheMonthlyPayments(year, month);
  }
}

/// Monthly payment summary model
class MonthlyPaymentSummary {
  final String year;
  final String month;
  final int totalPlayers;
  final int paidPlayers;
  final int partialPlayers;
  final int unpaidPlayers;
  final int inactivePlayers;
  final double totalExpected;
  final double totalCollected;
  final double outstandingAmount;
  final List<TeamPaymentStats> teamStatistics;
  final DateTime lastUpdated;
  final String organizationId;

  const MonthlyPaymentSummary({
    required this.year,
    required this.month,
    required this.totalPlayers,
    required this.paidPlayers,
    required this.partialPlayers,
    required this.unpaidPlayers,
    required this.inactivePlayers,
    required this.totalExpected,
    required this.totalCollected,
    required this.outstandingAmount,
    required this.teamStatistics,
    required this.lastUpdated,
    required this.organizationId,
  });

  double get collectionRate => 
      totalExpected > 0 ? (totalCollected / totalExpected) : 0.0;

  int get activePlayers => totalPlayers - inactivePlayers;

  Map<String, dynamic> toFirestore() {
    return {
      'year': year,
      'month': month,
      'total_players': totalPlayers,
      'paid_players': paidPlayers,
      'partial_players': partialPlayers,
      'unpaid_players': unpaidPlayers,
      'inactive_players': inactivePlayers,
      'total_expected': totalExpected,
      'total_collected': totalCollected,
      'outstanding_amount': outstandingAmount,
      'collection_rate': collectionRate,
      'team_statistics': teamStatistics.map((t) => t.toMap()).toList(),
      'last_updated': Timestamp.fromDate(lastUpdated),
      'organization_id': organizationId,
    };
  }

  static MonthlyPaymentSummary fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyPaymentSummary(
      year: data['year'] ?? '',
      month: data['month'] ?? '',
      totalPlayers: data['total_players'] ?? 0,
      paidPlayers: data['paid_players'] ?? 0,
      partialPlayers: data['partial_players'] ?? 0,
      unpaidPlayers: data['unpaid_players'] ?? 0,
      inactivePlayers: data['inactive_players'] ?? 0,
      totalExpected: (data['total_expected'] as num?)?.toDouble() ?? 0.0,
      totalCollected: (data['total_collected'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (data['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      teamStatistics: ((data['team_statistics'] as List?) ?? [])
          .map<TeamPaymentStats>((t) => TeamPaymentStats.fromMap(t))
          .toList(),
      lastUpdated: (data['last_updated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      organizationId: data['organization_id'] ?? '',
    );
  }
}

/// Team payment statistics
class TeamPaymentStats {
  final String teamName;
  int totalPlayers;
  int paidPlayers;
  int partialPlayers;
  int unpaidPlayers;
  int inactivePlayers;
  double totalRevenue;

  TeamPaymentStats({
    required this.teamName,
    required this.totalPlayers,
    required this.paidPlayers,
    required this.partialPlayers,
    required this.unpaidPlayers,
    required this.inactivePlayers,
    required this.totalRevenue,
  });

  double get collectionRate => 
      totalPlayers > 0 ? ((paidPlayers + partialPlayers) / totalPlayers) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'team_name': teamName,
      'total_players': totalPlayers,
      'paid_players': paidPlayers,
      'partial_players': partialPlayers,
      'unpaid_players': unpaidPlayers,
      'inactive_players': inactivePlayers,
      'total_revenue': totalRevenue,
      'collection_rate': collectionRate,
    };
  }

  static TeamPaymentStats fromMap(Map<String, dynamic> map) {
    return TeamPaymentStats(
      teamName: map['team_name'] ?? '',
      totalPlayers: map['total_players'] ?? 0,
      paidPlayers: map['paid_players'] ?? 0,
      partialPlayers: map['partial_players'] ?? 0,
      unpaidPlayers: map['unpaid_players'] ?? 0,
      inactivePlayers: map['inactive_players'] ?? 0,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Annual payment summary
class AnnualPaymentSummary {
  final String year;
  final int totalPlayers;
  final double totalExpectedRevenue;
  final double totalCollectedRevenue;
  final double collectionRate;
  final Map<String, double> monthlyBreakdown;
  final List<MonthlyPaymentSummary> monthlySummaries;
  final String organizationId;
  final DateTime lastUpdated;

  const AnnualPaymentSummary({
    required this.year,
    required this.totalPlayers,
    required this.totalExpectedRevenue,
    required this.totalCollectedRevenue,
    required this.collectionRate,
    required this.monthlyBreakdown,
    required this.monthlySummaries,
    required this.organizationId,
    required this.lastUpdated,
  });

  double get outstandingAmount => totalExpectedRevenue - totalCollectedRevenue;

  MonthlyPaymentSummary? getMonthSummary(int month) {
    final monthString = month.toString().padLeft(2, '0');
    return monthlySummaries.firstWhere(
      (s) => s.month == monthString,
      orElse: () => throw StateError('No summary for month $month'),
    );
  }
}