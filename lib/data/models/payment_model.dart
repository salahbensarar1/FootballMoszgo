import 'package:cloud_firestore/cloud_firestore.dart';

// Your existing PaymentRecord class
class PaymentRecord {
  final String id;
  final String playerId;
  final String year;
  final String month;
  final double? amount; // Add this field

  final bool isPaid;
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
      isPaid: data['isPaid'] ?? false,
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
      'isPaid': isPaid,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }

  PaymentRecord copyWith({
    String? id,
    String? playerId,
    String? year,
    String? month,
    bool? isPaid,
    DateTime? updatedAt,
    String? notes,
    String? updatedBy,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      year: year ?? this.year,
      month: month ?? this.month,
      isPaid: isPaid ?? this.isPaid,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

// Additional models for Payment Overview Screen
class PaymentStats {
  final double totalCollected;
  final double totalOutstanding;
  final int fullyPaidPlayers;
  final int totalPlayers;
  final double thisMonthCollected;
  final Map<int, double> monthlyData;
  final double collectionRate;
  final double thisMonthProgress;

  PaymentStats({
    required this.totalCollected,
    required this.totalOutstanding,
    required this.fullyPaidPlayers,
    required this.totalPlayers,
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
      thisMonthCollected: 0.0,
      monthlyData: {},
      collectionRate: 0.0,
      thisMonthProgress: 0.0,
    );
  }

  PaymentStats copyWith({
    double? totalCollected,
    double? totalOutstanding,
    int? fullyPaidPlayers,
    int? totalPlayers,
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
      thisMonthCollected: thisMonthCollected ?? this.thisMonthCollected,
      monthlyData: monthlyData ?? this.monthlyData,
      collectionRate: collectionRate ?? this.collectionRate,
      thisMonthProgress: thisMonthProgress ?? this.thisMonthProgress,
    );
  }
}

class PlayerPaymentStatus {
  final String playerId;
  final String name;
  final String team;
  final int paidMonths;
  final int totalMonths;
  final PaymentStatus status;
  final String? email;
  final String? phoneNumber;

  PlayerPaymentStatus({
    required this.playerId,
    required this.name,
    required this.team,
    required this.paidMonths,
    required this.totalMonths,
    required this.status,
    this.email,
    this.phoneNumber,
  });

  factory PlayerPaymentStatus.fromFirestore(
    DocumentSnapshot playerDoc,
    List<PaymentRecord> payments,
  ) {
    final data = playerDoc.data() as Map<String, dynamic>;
    final paidMonths = payments.where((p) => p.isPaid).length;

    PaymentStatus status;
    if (paidMonths == 0) {
      status = PaymentStatus.unpaid;
    } else if (paidMonths == 12) {
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
      status: status,
      email: data['email'],
      phoneNumber: data['phone'],
    );
  }

  double get paymentProgress =>
      totalMonths > 0 ? paidMonths / totalMonths : 0.0;

  bool get isFullyPaid => status == PaymentStatus.paid;
  bool get hasOutstanding => status != PaymentStatus.paid;

  PlayerPaymentStatus copyWith({
    String? playerId,
    String? name,
    String? team,
    int? paidMonths,
    int? totalMonths,
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
      status: status ?? this.status,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

// Payment Status Enum
enum PaymentStatus {
  paid,
  partial,
  unpaid;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Fully Paid';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }

  bool get isPaid => this == PaymentStatus.paid;
  bool get isPartial => this == PaymentStatus.partial;
  bool get isUnpaid => this == PaymentStatus.unpaid;
}

// Payment Summary for team or individual analysis
class PaymentSummary {
  final String entityId; // playerId or teamId
  final String entityName; // player name or team name
  final EntityType entityType;
  final int totalMonths;
  final int paidMonths;
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
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    this.lastPaymentDate,
    required this.unpaidMonths,
  });

  double get paymentProgress =>
      totalMonths > 0 ? paidMonths / totalMonths : 0.0;
  bool get isFullyPaid => paidMonths >= totalMonths;
  bool get hasOutstanding => outstandingAmount > 0;
}

enum EntityType { player, team }

// Monthly payment overview
class MonthlyPaymentOverview {
  final int year;
  final int month;
  final String monthName;
  final int totalPlayers;
  final int paidPlayers;
  final int unpaidPlayers;
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
    final paidPlayers = payments.where((p) => p.isPaid).length;
    final unpaidPlayers = totalPlayers - paidPlayers;
    final expectedAmount = totalPlayers * monthlyFee;
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
      expectedAmount: expectedAmount,
      collectedAmount: collectedAmount,
      outstandingAmount: outstandingAmount,
      collectionRate: collectionRate,
    );
  }
}

// Payment reminder data
class PaymentReminder {
  final String playerId;
  final String playerName;
  final String playerEmail;
  final List<String> unpaidMonths;
  final double outstandingAmount;
  final DateTime? lastReminderSent;
  final int reminderCount;

  PaymentReminder({
    required this.playerId,
    required this.playerName,
    required this.playerEmail,
    required this.unpaidMonths,
    required this.outstandingAmount,
    this.lastReminderSent,
    required this.reminderCount,
  });

  bool get hasValidEmail => playerEmail.isNotEmpty && playerEmail.contains('@');
  bool get hasOutstanding => unpaidMonths.isNotEmpty;

  factory PaymentReminder.fromPlayerStatus(
    PlayerPaymentStatus player,
    List<PaymentRecord> payments,
    double monthlyFee,
  ) {
    final paidMonths =
        payments.where((p) => p.isPaid).map((p) => p.month).toSet();
    final unpaidMonths = <String>[];

    for (int i = 1; i <= 12; i++) {
      final monthKey = i.toString().padLeft(2, '0');
      if (!paidMonths.contains(monthKey)) {
        unpaidMonths.add(monthKey);
      }
    }

    return PaymentReminder(
      playerId: player.playerId,
      playerName: player.name,
      playerEmail: player.email ?? '',
      unpaidMonths: unpaidMonths,
      outstandingAmount: unpaidMonths.length * monthlyFee,
      reminderCount: 0,
    );
  }
}
// Add this to your existing payment_model.dart

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
    this.currency = 'HUF', // Hungarian Forint
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
