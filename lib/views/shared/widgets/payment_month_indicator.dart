import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/utils/date_formatter.dart';

class PaymentMonthIndicator extends StatelessWidget {
  final String playerId;
  final bool isEditable;
  final String? currentUserEmail;

  const PaymentMonthIndicator({
    Key? key,
    required this.playerId,
    this.isEditable = false,
    this.currentUserEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final months = DateFormatter.getMonthNames();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .where('year', isEqualTo: currentYear)
          .snapshots(),
      builder: (context, snapshot) {
        // Map to store which months are paid
        final paidMonths = <String, bool>{};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final month = doc['month'];
            final isPaid = doc['isPaid'] ?? false;
            paidMonths[month] = isPaid;
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(12, (index) {
              final monthKey =
                  (index + 1).toString().padLeft(2, '0'); // "01", "02"...
              final isPaid = paidMonths[monthKey] ?? false;

              return GestureDetector(
                onTap: isEditable
                    ? () =>
                        _togglePayment(playerId, currentYear, monthKey, !isPaid)
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPaid ? Colors.green.shade600 : Colors.red.shade600,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      months[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  //*****************************************************************************************************************************************************************/

  Future<void> _togglePayment(
      String playerId, String year, String month, bool isPaid) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .doc('$year-$month');

      if (isPaid) {
        // Create/update document when paid
        await docRef.set({
          'playerId': playerId,
          'year': year,
          'month': month,
          'isPaid': true,
          'updatedAt': Timestamp.now(),
          'updatedBy': currentUserEmail ?? 'Unknown',
        }, SetOptions(merge: true));
      } else {
        // Delete document when unpaid
        await docRef.delete();
      }
    } catch (e) {
      print('Error updating payment: $e');
    }
  }
  //*****************************************************************************************************************************************************************/
}
