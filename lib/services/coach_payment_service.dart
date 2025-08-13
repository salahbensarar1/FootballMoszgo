import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart' as app_user;

/// Coach payment and salary management system
class CoachPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create coach payment record
  Future<void> createCoachPayment({
    required String organizationId,
    required String coachId,
    required double amount,
    required DateTime paymentPeriodStart,
    required DateTime paymentPeriodEnd,
    required CoachPaymentType paymentType,
    String? notes,
    Map<String, dynamic>? bonuses,
  }) async {
    final paymentRef = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('coach_payments')
        .doc();

    final payment = CoachPayment(
      id: paymentRef.id,
      coachId: coachId,
      amount: amount,
      paymentPeriodStart: paymentPeriodStart,
      paymentPeriodEnd: paymentPeriodEnd,
      paymentType: paymentType,
      status: CoachPaymentStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
      bonuses: bonuses ?? {},
    );

    await paymentRef.set(payment.toFirestore());
  }

  /// Get coach payments for a specific period
  Stream<List<CoachPayment>> getCoachPayments({
    required String organizationId,
    String? coachId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('coach_payments');

    if (coachId != null) {
      query = query.where('coach_id', isEqualTo: coachId);
    }

    if (startDate != null) {
      query = query.where('payment_period_start',
          isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('payment_period_end', isLessThanOrEqualTo: endDate);
    }

    return query.orderBy('created_at', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CoachPayment.fromFirestore(doc))
              .toList(),
        );
  }

  /// Mark coach payment as paid
  Future<void> markPaymentAsPaid({
    required String organizationId,
    required String paymentId,
    required DateTime paidAt,
    String? paymentMethod,
    String? transactionId,
  }) async {
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('coach_payments')
        .doc(paymentId)
        .update({
      'status': CoachPaymentStatus.paid.name,
      'paid_at': Timestamp.fromDate(paidAt),
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Calculate coach payment based on teams and sessions
  Future<double> calculateCoachPayment({
    required String organizationId,
    required String coachId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get coach's assigned teams
    final teamsSnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('teams')
        .where('coach_id', isEqualTo: coachId)
        .get();

    if (teamsSnapshot.docs.isEmpty) return 0.0;

    double totalPayment = 0.0;

    for (final teamDoc in teamsSnapshot.docs) {
      final teamData = teamDoc.data();
      final coachFeePerSession =
          (teamData['coach_fee_per_session'] ?? 5000.0).toDouble();

      // Count training sessions for this team in the period
      final sessionsSnapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('training_sessions')
          .where('team_id', isEqualTo: teamDoc.id)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'completed')
          .get();

      totalPayment += sessionsSnapshot.docs.length * coachFeePerSession;
    }

    return totalPayment;
  }

  /// Generate monthly coach payments for all coaches
  Future<void> generateMonthlyCoachPayments({
    required String organizationId,
    required DateTime month,
  }) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    // Get all coaches in organization
    final coachesSnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .get();

    for (final coachDoc in coachesSnapshot.docs) {
      final coach = app_user.User.fromFirestore(coachDoc);

      // Check if payment already exists for this period
      final existingPayment = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('coach_payments')
          .where('coach_id', isEqualTo: coach.id)
          .where('payment_period_start',
              isEqualTo: Timestamp.fromDate(startDate))
          .where('payment_period_end', isEqualTo: Timestamp.fromDate(endDate))
          .get();

      if (existingPayment.docs.isNotEmpty)
        continue; // Skip if already generated

      // Calculate payment amount
      final amount = await calculateCoachPayment(
        organizationId: organizationId,
        coachId: coach.id,
        startDate: startDate,
        endDate: endDate,
      );

      if (amount > 0) {
        await createCoachPayment(
          organizationId: organizationId,
          coachId: coach.id,
          amount: amount,
          paymentPeriodStart: startDate,
          paymentPeriodEnd: endDate,
          paymentType: CoachPaymentType.monthly,
          notes: 'Auto-generated monthly payment',
        );
      }
    }
  }

  /// Get coach payment summary
  Future<CoachPaymentSummary> getCoachPaymentSummary({
    required String organizationId,
    required String coachId,
    required DateTime year,
  }) async {
    final startDate = DateTime(year.year, 1, 1);
    final endDate = DateTime(year.year, 12, 31);

    final paymentsSnapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('coach_payments')
        .where('coach_id', isEqualTo: coachId)
        .where('payment_period_start',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('payment_period_end',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    double totalEarned = 0.0;
    double totalPaid = 0.0;
    double totalPending = 0.0;
    int totalSessions = 0;

    final monthlyBreakdown = <int, double>{};

    for (final doc in paymentsSnapshot.docs) {
      final payment = CoachPayment.fromFirestore(doc);
      totalEarned += payment.amount;

      if (payment.status == CoachPaymentStatus.paid) {
        totalPaid += payment.amount;
      } else {
        totalPending += payment.amount;
      }

      final month = payment.paymentPeriodStart.month;
      monthlyBreakdown[month] = (monthlyBreakdown[month] ?? 0) + payment.amount;
    }

    return CoachPaymentSummary(
      coachId: coachId,
      year: year.year,
      totalEarned: totalEarned,
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalSessions: totalSessions,
      monthlyBreakdown: monthlyBreakdown,
    );
  }
}

enum CoachPaymentType {
  monthly,
  perSession,
  bonus,
  adjustment;

  String get displayName {
    switch (this) {
      case CoachPaymentType.monthly:
        return 'Monthly Salary';
      case CoachPaymentType.perSession:
        return 'Per Session';
      case CoachPaymentType.bonus:
        return 'Bonus';
      case CoachPaymentType.adjustment:
        return 'Adjustment';
    }
  }
}

enum CoachPaymentStatus {
  pending,
  paid,
  cancelled;

  String get displayName {
    switch (this) {
      case CoachPaymentStatus.pending:
        return 'Pending';
      case CoachPaymentStatus.paid:
        return 'Paid';
      case CoachPaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class CoachPayment {
  final String id;
  final String coachId;
  final double amount;
  final DateTime paymentPeriodStart;
  final DateTime paymentPeriodEnd;
  final CoachPaymentType paymentType;
  final CoachPaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;
  final Map<String, dynamic> bonuses;

  const CoachPayment({
    required this.id,
    required this.coachId,
    required this.amount,
    required this.paymentPeriodStart,
    required this.paymentPeriodEnd,
    required this.paymentType,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.paymentMethod,
    this.transactionId,
    this.notes,
    this.bonuses = const {},
  });

  factory CoachPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachPayment(
      id: doc.id,
      coachId: data['coach_id'],
      amount: (data['amount'] ?? 0).toDouble(),
      paymentPeriodStart: (data['payment_period_start'] as Timestamp).toDate(),
      paymentPeriodEnd: (data['payment_period_end'] as Timestamp).toDate(),
      paymentType: CoachPaymentType.values.firstWhere(
        (e) => e.name == data['payment_type'],
        orElse: () => CoachPaymentType.monthly,
      ),
      status: CoachPaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CoachPaymentStatus.pending,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      paidAt: data['paid_at'] != null
          ? (data['paid_at'] as Timestamp).toDate()
          : null,
      paymentMethod: data['payment_method'],
      transactionId: data['transaction_id'],
      notes: data['notes'],
      bonuses: Map<String, dynamic>.from(data['bonuses'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'coach_id': coachId,
      'amount': amount,
      'payment_period_start': Timestamp.fromDate(paymentPeriodStart),
      'payment_period_end': Timestamp.fromDate(paymentPeriodEnd),
      'payment_type': paymentType.name,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'paid_at': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'notes': notes,
      'bonuses': bonuses,
    };
  }
}

class CoachPaymentSummary {
  final String coachId;
  final int year;
  final double totalEarned;
  final double totalPaid;
  final double totalPending;
  final int totalSessions;
  final Map<int, double> monthlyBreakdown;

  const CoachPaymentSummary({
    required this.coachId,
    required this.year,
    required this.totalEarned,
    required this.totalPaid,
    required this.totalPending,
    required this.totalSessions,
    required this.monthlyBreakdown,
  });

  double get outstandingBalance => totalEarned - totalPaid;
  double get averageMonthlyEarnings => totalEarned / 12;
}
