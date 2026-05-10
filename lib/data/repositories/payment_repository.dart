import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:footballtraining/services/organization_context.dart';
import '../models/payment_model.dart';

// Batch processing constants
const int kStreamListenerLimit = 1000;

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the org-scoped payments collection reference.
  CollectionReference get _paymentsCollection =>
      OrganizationContext.getCollection('payments');

  /// Returns the org-scoped players collection reference.
  CollectionReference get _playersCollection =>
      OrganizationContext.getCollection('players');

  // Deprecated: Use getDetailedPaymentStats instead.
  // MEMORY-SAFE: Added limit to prevent crashes with 10K+ payment records
  Stream<PaymentStats> getBasicPaymentStats() {
    return _paymentsCollection
        .limit(kStreamListenerLimit)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      double totalCollected = 0;
      double totalOutstanding = 0;
      int fullyPaidPlayers = 0;
      int totalPlayers = 0;
      Map<int, double> monthlyData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalCollected += data['amount'] ?? 0;
        totalPlayers++;

        if (data['isPaid'] == true) {
          fullyPaidPlayers++;
        } else {
          totalOutstanding += data['pendingAmount'] ?? 0;
        }

        final paymentDate = (data['paymentDate'] as Timestamp).toDate();
        final month = paymentDate.month;
        monthlyData[month] = (monthlyData[month] ?? 0) + (data['amount'] ?? 0);
      }

      return PaymentStats(
        totalCollected: totalCollected,
        totalOutstanding: totalOutstanding,
        fullyPaidPlayers: fullyPaidPlayers,
        totalPlayers: totalPlayers,
        thisMonthCollected: monthlyData[DateTime.now().month] ?? 0,
        monthlyData: monthlyData,
        collectionRate: totalPlayers > 0 ? fullyPaidPlayers / totalPlayers : 0,
        thisMonthProgress: 0,
      );
    });
  }

  // MEMORY-SAFE: Added limit to prevent crashes with large payment histories
  Stream<List<PaymentRecord>> getPlayerPayments() {
    return _paymentsCollection
        .limit(kStreamListenerLimit)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  // MEMORY-SAFE: Added limit to prevent crashes with large payment datasets
  Stream<PaymentStats> getPaymentStats() {
    return _paymentsCollection
        .limit(kStreamListenerLimit)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) {
      double totalCollected = 0;
      double totalOutstanding = 0;
      int fullyPaidPlayers = 0;
      int totalPlayers = 0;
      Map<int, double> monthlyData = {};
      Set<String> playerIds = {};

      for (var doc in snapshot.docs) {
        final payment = PaymentRecord.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>);
        if (!payment.isActive) continue;

        if (!playerIds.contains(payment.playerId)) {
          playerIds.add(payment.playerId);
          totalPlayers++;
        }

        if (payment.isPaid && payment.amount != null) {
          totalCollected += payment.amount!;
          fullyPaidPlayers++;

          final paymentDate = payment.updatedAt;
          final month = paymentDate.month;
          monthlyData[month] = (monthlyData[month] ?? 0) + payment.amount!;
        } else if (!payment.isPaid && payment.amount != null) {
          totalOutstanding += payment.amount!;
        }
      }

      return PaymentStats(
        totalCollected: totalCollected,
        totalOutstanding: totalOutstanding,
        fullyPaidPlayers: fullyPaidPlayers,
        totalPlayers: totalPlayers,
        inactivePlayers: 0,
        thisMonthCollected: monthlyData[DateTime.now().month] ?? 0,
        monthlyData: monthlyData,
        collectionRate: totalPlayers > 0 ? fullyPaidPlayers / totalPlayers : 0,
        thisMonthProgress: 0,
      );
    });
  }

  Future<void> markPayment({
    required String playerId,
    required double amount,
    required DateTime date,
  }) async {
    await _paymentsCollection.add({
      'playerId': playerId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _playersCollection.doc(playerId).update({
      'lastPaymentDate': Timestamp.fromDate(date),
      'amountPaid': FieldValue.increment(amount),
    });
  }
}
