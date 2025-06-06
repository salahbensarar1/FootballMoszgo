import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';

class PlayerDetailsDialog extends StatefulWidget {
  final PlayerPaymentStatus player;
  final int selectedYear;

  const PlayerDetailsDialog({
    super.key,
    required this.player,
    required this.selectedYear,
  });

  @override
  State<PlayerDetailsDialog> createState() => _PlayerDetailsDialogState();
}

class _PlayerDetailsDialogState extends State<PlayerDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isLoadingPayments = true;
  List<PaymentRecord> paymentRecords = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: _getStatusGradient(widget.player.status)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                widget.player.name.isNotEmpty
                    ? widget.player.name[0].toUpperCase()
                    : 'P',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(widget.player.status),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.player.team,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(widget.player.status),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: _getStatusColor(widget.player.status),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: _getStatusColor(widget.player.status),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_view_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Payment Grid',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  'History',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Summary',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (isLoadingPayments) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildPaymentGrid(),
        _buildPaymentHistory(),
        _buildPaymentSummary(),
      ],
    );
  }

  Widget _buildPaymentGrid() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    Map<String, PaymentRecord> paymentMap = {};
    for (var payment in paymentRecords) {
      paymentMap[payment.month] = payment;
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.selectedYear} Payment Status',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${widget.player.paidMonths}/12 Paid',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(widget.player.status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthNumber = (index + 1).toString().padLeft(2, '0');
                final payment = paymentMap[monthNumber];
                final isPaid = payment?.isPaid ?? false;
                final monthName = months[index];

                return GestureDetector(
                  onTap: () => _showMonthDetails(monthNumber, payment),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPaid
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaid ? Colors.green : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isPaid
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        if (payment != null && isPaid) ...[
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd/MM').format(payment.updatedAt),
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final paidPayments = paymentRecords.where((p) => p.isPaid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (paidPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Payment History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              'Payments will appear here once made',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: paidPayments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payment = paidPayments[index];
        final monthName =
            DateFormat('MMMM').format(DateTime(2024, int.parse(payment.month)));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthName ${payment.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Paid on ${DateFormat('MMM dd, yyyy').format(payment.updatedAt)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (payment.updatedBy != null) ...[
                      Text(
                        'Updated by: ${payment.updatedBy}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$100.00',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                  if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                    Text(
                      payment.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSummary() {
    final totalPaid = widget.player.paidMonths * 100.0;
    final totalOutstanding =
        (widget.player.totalMonths - widget.player.paidMonths) * 100.0;
    final totalExpected = widget.player.totalMonths * 100.0;
    final paymentRate = widget.player.paymentProgress * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Statistics
          Text(
            'Payment Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryCard(
            'Total Paid',
            '\$${totalPaid.toStringAsFixed(2)}',
            Icons.account_balance_wallet_rounded,
            Colors.green,
            '${widget.player.paidMonths} months',
          ),
          const SizedBox(height: 12),

          _buildSummaryCard(
            'Outstanding',
            '\$${totalOutstanding.toStringAsFixed(2)}',
            Icons.pending_actions_rounded,
            Colors.orange,
            '${widget.player.totalMonths - widget.player.paidMonths} months',
          ),
          const SizedBox(height: 12),

          _buildSummaryCard(
            'Payment Rate',
            '${paymentRate.toStringAsFixed(1)}%',
            Icons.trending_up_rounded,
            _getStatusColor(widget.player.status),
            'On-time payments',
          ),

          const SizedBox(height: 24),

          // Payment Progress
          Text(
            'Payment Progress',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Annual Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.player.paidMonths}/${widget.player.totalMonths}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(widget.player.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.player.paymentProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStatusColor(widget.player.status),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${paymentRate.toStringAsFixed(1)}% Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentPayments = paymentRecords.where((p) => p.isPaid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final recentActivity = recentPayments.take(3).toList();

    if (recentActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              'No recent payment activity',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentActivity.map((payment) {
        final monthName =
            DateFormat('MMMM').format(DateTime(2024, int.parse(payment.month)));
        final timeAgo = _getTimeAgo(payment.updatedAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paid $monthName ${payment.year}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _sendPaymentReminder(),
              icon: const Icon(Icons.email_rounded, size: 16),
              label: Text(
                'Send Reminder',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF59E0B),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markPayment(),
              icon: const Icon(Icons.payment_rounded, size: 16),
              label: Text(
                'Mark Payment',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getStatusColor(widget.player.status),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<Color> _getStatusGradient(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case PaymentStatus.partial:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case PaymentStatus.unpaid:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.partial:
        return const Color(0xFFF59E0B);
      case PaymentStatus.unpaid:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Fully Paid';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _loadPaymentData() async {
    try {
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(widget.player.playerId)
          .collection('payments')
          .where('year', isEqualTo: widget.selectedYear.toString())
          .get();

      final payments = paymentsSnapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();

      setState(() {
        paymentRecords = payments;
        isLoadingPayments = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPayments = false;
      });
      print('Error loading payment data: $e');
    }
  }

  void _showMonthDetails(String monthNumber, PaymentRecord? payment) {
    final monthName =
        DateFormat('MMMM').format(DateTime(2024, int.parse(monthNumber)));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$monthName ${widget.selectedYear}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Status:', payment?.isPaid == true ? 'Paid' : 'Unpaid'),
            if (payment?.isPaid == true) ...[
              _buildDetailRow('Payment Date:',
                  DateFormat('MMM dd, yyyy').format(payment!.updatedAt)),
              if (payment.updatedBy != null)
                _buildDetailRow('Updated By:', payment.updatedBy!),
              if (payment.notes != null && payment.notes!.isNotEmpty)
                _buildDetailRow('Notes:', payment.notes!),
            ],
            _buildDetailRow('Amount:', '\$100.00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPaymentReminder() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.email_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Payment reminder sent to ${widget.player.name}'),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _markPayment() {
    Navigator.pop(context);
    // You can integrate with MarkPaymentDialog here or implement inline payment marking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Use the Mark Payment feature from the main screen'),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
