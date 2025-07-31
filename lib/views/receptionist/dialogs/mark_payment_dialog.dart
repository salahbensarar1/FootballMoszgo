import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';

class MarkPaymentDialog extends StatefulWidget {
  final int selectedYear;
  final Map<String, double> teamPaymentFees;

  const MarkPaymentDialog({
    super.key,
    required this.selectedYear,
    required this.teamPaymentFees,
  });

  @override
  State<MarkPaymentDialog> createState() => _MarkPaymentDialogState();
}

class _MarkPaymentDialogState extends State<MarkPaymentDialog>
    with TickerProviderStateMixin {
  String? selectedPlayer;
  String? selectedMonth;
  String? selectedPlayerTeam;
  PaymentStatus selectedPaymentStatus = PaymentStatus.paid;
  bool isProcessing = false;
  final TextEditingController notesController = TextEditingController();
  
  // Animation controllers for smooth UX
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double get _getPaymentAmount {
    if (selectedPlayerTeam == null) return 0.0;
    return widget.teamPaymentFees[selectedPlayerTeam] ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.payment_rounded, color: Color(0xFF667eea)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.markPayment,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  l10n.recordPaymentFor('${widget.selectedYear}'),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player Selection
            _buildPlayerDropdown(),
            const SizedBox(height: 16),

            // Month Selection
            _buildMonthDropdown(),
            const SizedBox(height: 16),

            // Payment Status Selection - PRODUCTION READY
            _buildPaymentStatusSelection(),
            const SizedBox(height: 16),

            // Notes Field
            _buildNotesField(),

            // Payment Summary
            if (selectedPlayer != null && selectedMonth != null) ...[
              const SizedBox(height: 16),
              _buildPaymentSummary(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _canProcessPayment() ? _processPaymentMark : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            disabledBackgroundColor: Colors.grey.shade300,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _getActionButtonText(),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPlayerDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: selectedPlayer,
            decoration: InputDecoration(
              labelText: 'Select Player',
              labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
              prefixIcon:
                  Icon(Icons.person_rounded, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final playerName = data['name'] ?? 'Unknown Player';
              final teamName = data['team'] ?? 'No Team';

              return DropdownMenuItem<String>(
                value: doc.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playerName,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      teamName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPlayer = value;
                // Update selected player's team for payment calculation
                if (value != null) {
                  final playerDoc =
                      snapshot.data!.docs.firstWhere((doc) => doc.id == value);
                  final data = playerDoc.data() as Map<String, dynamic>;
                  selectedPlayerTeam = data['team'] ?? 'No Team';
                }
              });
            },
            validator: (value) =>
                value == null ? 'Please select a player' : null,
          ),
        );
      },
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedMonth,
        decoration: InputDecoration(
          labelText: 'Select Month',
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon:
              Icon(Icons.calendar_month_rounded, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: List.generate(12, (index) {
          final monthNumber = (index + 1).toString().padLeft(2, '0');
          final monthName =
              DateFormat('MMMM').format(DateTime(2024, index + 1));

          return DropdownMenuItem<String>(
            value: monthNumber,
            child: Text(
              monthName,
              style: GoogleFonts.poppins(),
            ),
          );
        }),
        onChanged: (value) => setState(() => selectedMonth = value),
        validator: (value) => value == null ? 'Please select a month' : null,
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: notesController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Notes (Optional)',
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.note_rounded, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: 'Add payment details or notes...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final paymentAmount = _getPaymentAmount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF667eea),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Payment Summary',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Year:', widget.selectedYear.toString()),
          _buildSummaryRow('Month:', _getMonthName(selectedMonth!)),
          _buildSummaryRow('Team:', selectedPlayerTeam ?? 'N/A'),
          _buildSummaryRow(
              'Amount:',
              paymentAmount > 0
                  ? '\$${paymentAmount.toStringAsFixed(2)}'
                  : 'No Fee'),
          _buildSummaryRow('Payment Method:', 'Manual Entry'),

          // Show warning if team has no payment fee
          if (paymentAmount == 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_rounded,
                      color: Colors.orange.shade600, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This team has no payment fee configured',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  bool _canProcessPayment() {
    return selectedPlayer != null && selectedMonth != null && !isProcessing;
  }

  String _getMonthName(String monthNumber) {
    final month = int.parse(monthNumber);
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  /// PRODUCTION-READY: Dynamic button text based on selected payment status
  String _getActionButtonText() {
    switch (selectedPaymentStatus) {
      case PaymentStatus.paid:
        return 'Mark as Paid';
      case PaymentStatus.partial:
        return 'Mark as Partial';
      case PaymentStatus.unpaid:
        return 'Mark as Unpaid';
      case PaymentStatus.notActive:
        return 'Mark as Inactive';
    }
  }

  /// PRODUCTION-READY: Payment Status Selection Widget with proper UX
  Widget _buildPaymentStatusSelection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Payment Status',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: PaymentStatus.values.map((status) {
                  return _buildPaymentStatusOption(status);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// PRODUCTION-READY: Individual payment status option with proper styling
  Widget _buildPaymentStatusOption(PaymentStatus status) {
    final isSelected = selectedPaymentStatus == status;
    final statusColor = _getPaymentStatusColor(status);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? statusColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? statusColor : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              selectedPaymentStatus = status;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? statusColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? statusColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 12,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? statusColor : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        _getPaymentStatusDescription(status),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// PRODUCTION-READY: Get appropriate color for each payment status
  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981); // Green
      case PaymentStatus.partial:
        return const Color(0xFFF59E0B); // Orange
      case PaymentStatus.unpaid:
        return const Color(0xFFEF4444); // Red
      case PaymentStatus.notActive:
        return const Color(0xFF6B7280); // Grey
    }
  }

  /// PRODUCTION-READY: Descriptive text for each payment status
  String _getPaymentStatusDescription(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payment fully completed';
      case PaymentStatus.partial:
        return 'Partial payment received';
      case PaymentStatus.unpaid:
        return 'No payment received';
      case PaymentStatus.notActive:
        return 'Player inactive/suspended';
    }
  }

  /// ENTERPRISE-GRADE: Convert PaymentStatus enum to legacy boolean fields for backward compatibility
  /// Returns (isPaid, isActive) tuple
  (bool, bool) _convertPaymentStatusToLegacyFields(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return (true, true);   // Paid and Active
      case PaymentStatus.partial:
        return (false, true);  // Not fully paid but Active (will be handled by amount logic)
      case PaymentStatus.unpaid:
        return (false, true);  // Not paid but Active
      case PaymentStatus.notActive:
        return (false, false); // Not paid and Not Active
    }
  }

  /// PRODUCTION-READY: Dynamic success message based on payment status
  String _getSuccessMessage() {
    switch (selectedPaymentStatus) {
      case PaymentStatus.paid:
        return 'Payment marked as PAID successfully!';
      case PaymentStatus.partial:
        return 'Payment marked as PARTIAL successfully!';
      case PaymentStatus.unpaid:
        return 'Payment marked as UNPAID successfully!';
      case PaymentStatus.notActive:
        return 'Player marked as INACTIVE successfully!';
    }
  }

  /// PRODUCTION-READY: Enhanced payment processing with full status support
  Future<void> _processPaymentMark() async {
    if (!_canProcessPayment()) return;

    setState(() => isProcessing = true);

    try {
      // ENTERPRISE-GRADE: Convert PaymentStatus to legacy boolean fields for backward compatibility
      final (isPaid, isActive) = _convertPaymentStatusToLegacyFields(selectedPaymentStatus);
      
      // Create payment record with proper status handling
      final paymentRecord = PaymentRecord(
        id: '', // Will be set by Firestore
        playerId: selectedPlayer!,
        year: widget.selectedYear.toString(),
        month: selectedMonth!,
        isPaid: isPaid,
        isActive: isActive,
        amount: selectedPaymentStatus == PaymentStatus.notActive ? 0.0 : _getPaymentAmount,
        updatedAt: DateTime.now(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        updatedBy: FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('players')
          .doc(selectedPlayer!)
          .collection('payments')
          .doc('${widget.selectedYear}-$selectedMonth')
          .set(paymentRecord.toMap(), SetOptions(merge: true));

      Navigator.pop(context);
      _showSuccessSnackBar(_getSuccessMessage());
    } catch (e) {
      _showErrorSnackBar('Error marking payment: $e');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
