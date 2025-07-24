// lib/data/models/payment_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced Payment Status Enum
enum PaymentStatus {
  paid,
  partial,
  unpaid,
  notActive; // New status for inactive players

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Fully Paid';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.notActive:
        return 'Not Active';
    }
  }

  String get shortName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.notActive:
        return 'Inactive';
    }
  }

  bool get isPaid => this == PaymentStatus.paid;
  bool get isPartial => this == PaymentStatus.partial;
  bool get isUnpaid => this == PaymentStatus.unpaid;
  bool get isNotActive => this == PaymentStatus.notActive;
  bool get isActive => this != PaymentStatus.notActive;

  // Helper method to determine if this status should count toward payment calculations
  bool get countsTowardPayment => this != PaymentStatus.notActive;
}

// Enhanced PaymentRecord class
class PaymentRecord {
  final String id;
  final String playerId;
  final String year;
  final String month;
  final double? amount;
  final bool isPaid;
  final bool isActive; // New field to track if player is active for this month
  final DateTime updatedAt;
  final String? notes;
  final String? updatedBy;

  PaymentRecord({
    required this.id,
    required this.playerId,
    required this.year,
    this.amount,
    required this.month,
    required this.isPaid,
    this.isActive = true, // Default to active
    required this.updatedAt,
    this.notes,
    this.updatedBy,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRecord(
      id: doc.id,
      playerId: data['playerId'] ?? '',
      year: data['year'] ?? '',
      month: data['month'] ?? '',
      amount: data['amount']?.toDouble(),
      isPaid: data['isPaid'] ?? false,
      isActive: data['isActive'] ??
          true, // Default to active for backward compatibility
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'year': year,
      'month': month,
      'amount': amount,
      'isPaid': isPaid,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }

  // Get the payment status based on isPaid and isActive
  PaymentStatus get status {
    if (!isActive) return PaymentStatus.notActive;
    if (isPaid) return PaymentStatus.paid;
    return PaymentStatus.unpaid;
  }

  PaymentRecord copyWith({
    String? id,
    String? playerId,
    String? year,
    String? month,
    double? amount,
    bool? isPaid,
    bool? isActive,
    DateTime? updatedAt,
    String? notes,
    String? updatedBy,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

// Enhanced PaymentStats class
enum PaymentStatsStatus {
  paid,
  pending,
  late,
}

class PaymentStats {
  final double totalCollected;
  final double totalOutstanding;
  final int fullyPaidPlayers;
  final int totalPlayers;
  final int inactivePlayers;
  final double thisMonthCollected;
  final Map<int, double> monthlyData;
  final double collectionRate;
  final double thisMonthProgress;

  PaymentStats({
    required this.totalCollected,
    required this.totalOutstanding,
    required this.fullyPaidPlayers,
    required this.totalPlayers,
    this.inactivePlayers = 0,
    required this.thisMonthCollected,
    required this.monthlyData,
    required this.collectionRate,
    required this.thisMonthProgress,
  });

  factory PaymentStats.empty() {
    return PaymentStats(
      totalCollected: 0.0,
      totalOutstanding: 0.0,
      fullyPaidPlayers: 0,
      totalPlayers: 0,
      inactivePlayers: 0,
      thisMonthCollected: 0.0,
      monthlyData: {},
      collectionRate: 0.0,
      thisMonthProgress: 0.0,
    );
  }

  // Calculate active players
  int get activePlayers => totalPlayers - inactivePlayers;

  // Calculate collection rate based on active players only
  double get activeCollectionRate {
    if (activePlayers == 0) return 0.0;
    final totalExpectedFromActive = totalCollected + totalOutstanding;
    return totalExpectedFromActive > 0
        ? (totalCollected / totalExpectedFromActive) * 100
        : 0.0;
  }

  PaymentStats copyWith({
    double? totalCollected,
    double? totalOutstanding,
    int? fullyPaidPlayers,
    int? totalPlayers,
    int? inactivePlayers,
    double? thisMonthCollected,
    Map<int, double>? monthlyData,
    double? collectionRate,
    double? thisMonthProgress,
  }) {
    return PaymentStats(
      totalCollected: totalCollected ?? this.totalCollected,
      totalOutstanding: totalOutstanding ?? this.totalOutstanding,
      fullyPaidPlayers: fullyPaidPlayers ?? this.fullyPaidPlayers,
      totalPlayers: totalPlayers ?? this.totalPlayers,
      inactivePlayers: inactivePlayers ?? this.inactivePlayers,
      thisMonthCollected: thisMonthCollected ?? this.thisMonthCollected,
      monthlyData: monthlyData ?? this.monthlyData,
      collectionRate: collectionRate ?? this.collectionRate,
      thisMonthProgress: thisMonthProgress ?? this.thisMonthProgress,
    );
  }
}

// Enhanced PlayerPaymentStatus class
class PlayerPaymentStatus {
  final String playerId;
  final String name;
  final String team;
  final int paidMonths;
  final int totalMonths;
  final int inactiveMonths; // New field for inactive months
  final PaymentStatus status;
  final String? email;
  final String? phoneNumber;

  PlayerPaymentStatus({
    required this.playerId,
    required this.name,
    required this.team,
    required this.paidMonths,
    required this.totalMonths,
    this.inactiveMonths = 0,
    required this.status,
    this.email,
    this.phoneNumber,
  });

  factory PlayerPaymentStatus.fromFirestore(
    DocumentSnapshot playerDoc,
    List<PaymentRecord> payments,
  ) {
    final data = playerDoc.data() as Map<String, dynamic>;
    final paidMonths = payments.where((p) => p.isPaid && p.isActive).length;
    final inactiveMonths = payments.where((p) => !p.isActive).length;
    final activeMonths = 12 - inactiveMonths;

    PaymentStatus status;
    if (inactiveMonths == 12) {
      status = PaymentStatus.notActive;
    } else if (paidMonths == 0) {
      status = PaymentStatus.unpaid;
    } else if (paidMonths == activeMonths) {
      status = PaymentStatus.paid;
    } else {
      status = PaymentStatus.partial;
    }

    return PlayerPaymentStatus(
      playerId: playerDoc.id,
      name: data['name'] ?? 'Unknown Player',
      team: data['team'] ?? 'No Team',
      paidMonths: paidMonths,
      totalMonths: 12,
      inactiveMonths: inactiveMonths,
      status: status,
      email: data['email'],
      phoneNumber: data['phone'],
    );
  }

  // Calculate payment progress excluding inactive months
  double get paymentProgress {
    final activeMonths = totalMonths - inactiveMonths;
    return activeMonths > 0 ? paidMonths / activeMonths : 0.0;
  }

  // Get effective total months (excluding inactive)
  int get effectiveTotalMonths => totalMonths - inactiveMonths;

  // Get outstanding months (active but unpaid)
  int get outstandingMonths => effectiveTotalMonths - paidMonths;

  bool get isFullyPaid => status == PaymentStatus.paid;
  bool get hasOutstanding =>
      status != PaymentStatus.paid && status != PaymentStatus.notActive;
  bool get isActive => status != PaymentStatus.notActive;

  PlayerPaymentStatus copyWith({
    String? playerId,
    String? name,
    String? team,
    int? paidMonths,
    int? totalMonths,
    int? inactiveMonths,
    PaymentStatus? status,
    String? email,
    String? phoneNumber,
  }) {
    return PlayerPaymentStatus(
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      team: team ?? this.team,
      paidMonths: paidMonths ?? this.paidMonths,
      totalMonths: totalMonths ?? this.totalMonths,
      inactiveMonths: inactiveMonths ?? this.inactiveMonths,
      status: status ?? this.status,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// Enhanced PaymentSummary class
class PaymentSummary {
  final String entityId;
  final String entityName;
  final EntityType entityType;
  final int totalMonths;
  final int paidMonths;
  final int inactiveMonths; // New field
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? lastPaymentDate;
  final List<String> unpaidMonths;

  PaymentSummary({
    required this.entityId,
    required this.entityName,
    required this.entityType,
    required this.totalMonths,
    required this.paidMonths,
    this.inactiveMonths = 0,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    this.lastPaymentDate,
    required this.unpaidMonths,
  });

  // Calculate payment progress excluding inactive months
  double get paymentProgress {
    final activeMonths = totalMonths - inactiveMonths;
    return activeMonths > 0 ? paidMonths / activeMonths : 0.0;
  }

  int get effectiveTotalMonths => totalMonths - inactiveMonths;
  bool get isFullyPaid => paidMonths >= effectiveTotalMonths;
  bool get hasOutstanding => outstandingAmount > 0;
}

enum EntityType { player, team }

// Enhanced MonthlyPaymentOverview class
class MonthlyPaymentOverview {
  final int year;
  final int month;
  final String monthName;
  final int totalPlayers;
  final int paidPlayers;
  final int unpaidPlayers;
  final int inactivePlayers; // New field
  final double expectedAmount;
  final double collectedAmount;
  final double outstandingAmount;
  final double collectionRate;

  MonthlyPaymentOverview({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalPlayers,
    required this.paidPlayers,
    required this.unpaidPlayers,
    this.inactivePlayers = 0,
    required this.expectedAmount,
    required this.collectedAmount,
    required this.outstandingAmount,
    required this.collectionRate,
  });

  factory MonthlyPaymentOverview.fromData({
    required int year,
    required int month,
    required String monthName,
    required int totalPlayers,
    required List<PaymentRecord> payments,
    required double monthlyFee,
  }) {
    final paidPlayers = payments.where((p) => p.isPaid && p.isActive).length;
    final inactivePlayers = payments.where((p) => !p.isActive).length;
    final activePlayers = totalPlayers - inactivePlayers;
    final unpaidPlayers = activePlayers - paidPlayers;

    final expectedAmount =
        activePlayers * monthlyFee; // Only count active players
    final collectedAmount = paidPlayers * monthlyFee;
    final outstandingAmount = expectedAmount - collectedAmount;
    final collectionRate =
        expectedAmount > 0 ? (collectedAmount / expectedAmount) * 100 : 0.0;

    return MonthlyPaymentOverview(
      year: year,
      month: month,
      monthName: monthName,
      totalPlayers: totalPlayers,
      paidPlayers: paidPlayers,
      unpaidPlayers: unpaidPlayers,
      inactivePlayers: inactivePlayers,
      expectedAmount: expectedAmount,
      collectedAmount: collectedAmount,
      outstandingAmount: outstandingAmount,
      collectionRate: collectionRate,
    );
  }

  int get activePlayers => totalPlayers - inactivePlayers;
}

// Enhanced PaymentReminder class
class PaymentReminder {
  final String playerId;
  final String playerName;
  final String playerEmail;
  final List<String> unpaidMonths;
  final List<String> inactiveMonths; // New field
  final double outstandingAmount;
  final DateTime? lastReminderSent;
  final int reminderCount;

  PaymentReminder({
    required this.playerId,
    required this.playerName,
    required this.playerEmail,
    required this.unpaidMonths,
    this.inactiveMonths = const [],
    required this.outstandingAmount,
    this.lastReminderSent,
    required this.reminderCount,
  });

  bool get hasValidEmail => playerEmail.isNotEmpty && playerEmail.contains('@');
  bool get hasOutstanding => unpaidMonths.isNotEmpty;
  bool get isPartiallyInactive =>
      inactiveMonths.isNotEmpty && inactiveMonths.length < 12;
  bool get isFullyInactive => inactiveMonths.length == 12;

  factory PaymentReminder.fromPlayerStatus(
    PlayerPaymentStatus player,
    List<PaymentRecord> payments,
    double monthlyFee,
  ) {
    final paidMonths =
        payments.where((p) => p.isPaid).map((p) => p.month).toSet();
    final inactiveMonths =
        payments.where((p) => !p.isActive).map((p) => p.month).toList();
    final unpaidMonths = <String>[];

    for (int i = 1; i <= 12; i++) {
      final monthKey = i.toString().padLeft(2, '0');
      if (!paidMonths.contains(monthKey) &&
          !inactiveMonths.contains(monthKey)) {
        unpaidMonths.add(monthKey);
      }
    }

    return PaymentReminder(
      playerId: player.playerId,
      playerName: player.name,
      playerEmail: player.email ?? '',
      unpaidMonths: unpaidMonths,
      inactiveMonths: inactiveMonths,
      outstandingAmount: unpaidMonths.length * monthlyFee,
      reminderCount: 0,
    );
  }
}

// Enhanced TeamPaymentSettings class
class TeamPaymentSettings {
  final String teamId;
  final String teamName;
  final double monthlyFee;
  final String currency;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TeamPaymentSettings({
    required this.teamId,
    required this.teamName,
    required this.monthlyFee,
    this.currency = 'HUF',
    required this.createdAt,
    this.updatedAt,
  });

  factory TeamPaymentSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamPaymentSettings(
      teamId: doc.id,
      teamName: data['team_name'] ?? '',
      monthlyFee: (data['payment_fee'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'HUF',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'team_name': teamName,
      'payment_fee': monthlyFee,
      'currency': currency,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
  }

  String formatAmount(double amount) {
    if (currency == 'HUF') {
      return '${amount.toStringAsFixed(0)} Ft';
    }
    return '${amount.toStringAsFixed(2)} $currency';
  }
}

// Additional utility classes for better organization

// Payment Analytics class for advanced reporting
class PaymentAnalytics {
  final int totalActiveMonths;
  final int totalInactiveMonths;
  final double averageCollectionRate;
  final List<MonthlyPaymentOverview> monthlyOverviews;
  final Map<String, double> teamPerformance;
  final List<String> topPerformingTeams;
  final List<String> underperformingTeams;

  PaymentAnalytics({
    required this.totalActiveMonths,
    required this.totalInactiveMonths,
    required this.averageCollectionRate,
    required this.monthlyOverviews,
    required this.teamPerformance,
    required this.topPerformingTeams,
    required this.underperformingTeams,
  });

  double get activeMonthsPercentage => totalActiveMonths > 0
      ? (totalActiveMonths / (totalActiveMonths + totalInactiveMonths)) * 100
      : 0.0;

  double get inactiveMonthsPercentage => totalInactiveMonths > 0
      ? (totalInactiveMonths / (totalActiveMonths + totalInactiveMonths)) * 100
      : 0.0;

  factory PaymentAnalytics.fromData({
    required List<PlayerPaymentStatus> players,
    required Map<String, double> teamFees,
    required int year,
  }) {
    int totalActiveMonths = 0;
    int totalInactiveMonths = 0;
    Map<String, double> teamPerformance = {};

    for (final player in players) {
      totalActiveMonths += player.effectiveTotalMonths;
      totalInactiveMonths += player.inactiveMonths;

      // Calculate team performance
      final teamKey = player.team;
      if (!teamPerformance.containsKey(teamKey)) {
        teamPerformance[teamKey] = 0.0;
      }
      teamPerformance[teamKey] =
          teamPerformance[teamKey]! + player.paymentProgress;
    }

    // Calculate average team performance
    teamPerformance.forEach((team, totalProgress) {
      final playersInTeam = players.where((p) => p.team == team).length;
      if (playersInTeam > 0) {
        teamPerformance[team] = totalProgress / playersInTeam * 100;
      }
    });

    // Sort teams by performance
    final sortedTeams = teamPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topPerformingTeams = sortedTeams.take(3).map((e) => e.key).toList();
    final underperformingTeams =
        sortedTeams.reversed.take(3).map((e) => e.key).toList();

    final averageCollectionRate = players.isNotEmpty
        ? players.map((p) => p.paymentProgress).reduce((a, b) => a + b) /
            players.length *
            100
        : 0.0;

    return PaymentAnalytics(
      totalActiveMonths: totalActiveMonths,
      totalInactiveMonths: totalInactiveMonths,
      averageCollectionRate: averageCollectionRate,
      monthlyOverviews: [], // This would be populated with actual monthly data
      teamPerformance: teamPerformance,
      topPerformingTeams: topPerformingTeams,
      underperformingTeams: underperformingTeams,
    );
  }
}

// Payment Configuration class for system settings
class PaymentConfiguration {
  final bool enableNotActiveStatus;
  final bool requireNotesForStatusChange;
  final bool sendAutoReminders;
  final int reminderFrequencyDays;
  final bool enablePartialPayments;
  final double lateFeePercentage;
  final List<String> excludedMonths;

  PaymentConfiguration({
    this.enableNotActiveStatus = true,
    this.requireNotesForStatusChange = false,
    this.sendAutoReminders = true,
    this.reminderFrequencyDays = 7,
    this.enablePartialPayments = false,
    this.lateFeePercentage = 0.0,
    this.excludedMonths = const [],
  });

  factory PaymentConfiguration.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentConfiguration(
      enableNotActiveStatus: data['enableNotActiveStatus'] ?? true,
      requireNotesForStatusChange: data['requireNotesForStatusChange'] ?? false,
      sendAutoReminders: data['sendAutoReminders'] ?? true,
      reminderFrequencyDays: data['reminderFrequencyDays'] ?? 7,
      enablePartialPayments: data['enablePartialPayments'] ?? false,
      lateFeePercentage: (data['lateFeePercentage'] ?? 0.0).toDouble(),
      excludedMonths: List<String>.from(data['excludedMonths'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableNotActiveStatus': enableNotActiveStatus,
      'requireNotesForStatusChange': requireNotesForStatusChange,
      'sendAutoReminders': sendAutoReminders,
      'reminderFrequencyDays': reminderFrequencyDays,
      'enablePartialPayments': enablePartialPayments,
      'lateFeePercentage': lateFeePercentage,
      'excludedMonths': excludedMonths,
    };
  }
}

// Payment Audit Trail for tracking changes
class PaymentAuditTrail {
  final String id;
  final String playerId;
  final String monthKey;
  final String year;
  final PaymentStatus oldStatus;
  final PaymentStatus newStatus;
  final String changedBy;
  final DateTime changedAt;
  final String? reason;
  final String? notes;

  PaymentAuditTrail({
    required this.id,
    required this.playerId,
    required this.monthKey,
    required this.year,
    required this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    required this.changedAt,
    this.reason,
    this.notes,
  });

  factory PaymentAuditTrail.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentAuditTrail(
      id: doc.id,
      playerId: data['playerId'] ?? '',
      monthKey: data['monthKey'] ?? '',
      year: data['year'] ?? '',
      oldStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['oldStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      newStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == data['newStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      changedBy: data['changedBy'] ?? '',
      changedAt: (data['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'monthKey': monthKey,
      'year': year,
      'oldStatus': oldStatus.name,
      'newStatus': newStatus.name,
      'changedBy': changedBy,
      'changedAt': Timestamp.fromDate(changedAt),
      'reason': reason,
      'notes': notes,
    };
  }
}

// Extension methods for better usability
extension PaymentRecordExtensions on PaymentRecord {
  bool get isOverdue {
    final now = DateTime.now();
    final paymentMonth = DateTime(int.parse(year), int.parse(month));
    return !isPaid && isActive && paymentMonth.isBefore(now);
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year.toString() &&
        month == now.month.toString().padLeft(2, '0');
  }

  bool get isFutureMonth {
    final now = DateTime.now();
    final paymentMonth = DateTime(int.parse(year), int.parse(month));
    return paymentMonth.isAfter(now);
  }
}

extension PaymentStatusExtensions on PaymentStatus {
  bool get requiresPayment =>
      this == PaymentStatus.unpaid || this == PaymentStatus.partial;
  bool get isCompleted => this == PaymentStatus.paid;
  bool get isExcluded => this == PaymentStatus.notActive;
}

extension PlayerPaymentStatusExtensions on PlayerPaymentStatus {
  List<String> get unpaidMonthsList {
    final List<String> unpaidMonths = [];
    for (int i = 1; i <= 12; i++) {
      final monthKey = i.toString().padLeft(2, '0');
      // This would need to be populated with actual payment data
      // For now, it's a placeholder
    }
    return unpaidMonths;
  }

  double get completionPercentage => paymentProgress * 100;

  String get statusDescription {
    if (isFullyPaid) return 'All active months paid';
    if (inactiveMonths == 12) return 'Inactive for entire year';
    if (paidMonths == 0) return 'No payments made';
    return '$paidMonths of $effectiveTotalMonths active months paid';
  }
}
