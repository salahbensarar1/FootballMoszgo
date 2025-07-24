import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Deprecated: Use getDetailedPaymentStats instead.
  Stream<PaymentStats> getBasicPaymentStats() {
    return _firestore.collection('payments').snapshots().map((snapshot) {
      double totalCollected = 0;
      double totalOutstanding = 0;
      int fullyPaidPlayers = 0;
      int totalPlayers = 0;
      Map<int, double> monthlyData = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
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
        thisMonthProgress: 0, // Calculate based on your business logic
      );
    });
  }

  Stream<List<PaymentRecord>> getPlayerPayments() {
    return _firestore.collection('payments').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    });
  }

  Stream<PaymentStats> getPaymentStats() {
    return _firestore.collection('payments').snapshots().map((snapshot) {
      double totalCollected = 0;
      double totalOutstanding = 0;
      int fullyPaidPlayers = 0;
      int totalPlayers = 0;
      Map<int, double> monthlyData = {};
      Set<String> playerIds = {};

      for (var doc in snapshot.docs) {
        final payment = PaymentRecord.fromFirestore(doc);
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
        inactivePlayers: 0, // This would need to be calculated separately
        thisMonthCollected: monthlyData[DateTime.now().month] ?? 0,
        monthlyData: monthlyData,
        collectionRate: totalPlayers > 0 ? fullyPaidPlayers / totalPlayers : 0,
        thisMonthProgress:
            0, // This needs to be calculated based on your business logic
      );
    });
  }

  Future<void> markPayment({
    required String playerId,
    required double amount,
    required DateTime date,
  }) async {
    await _firestore.collection('payments').add({
      'playerId': playerId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('players').doc(playerId).update({
      'lastPaymentDate': Timestamp.fromDate(date),
      'amountPaid': FieldValue.increment(amount),
    });
  }
}
