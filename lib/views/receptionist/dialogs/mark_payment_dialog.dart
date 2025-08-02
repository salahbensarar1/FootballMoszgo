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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.95 : 500,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // RESPONSIVE HEADER
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payment_rounded, color: Color(0xFF667eea), size: 20),
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
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          l10n.recordPaymentFor('${widget.selectedYear}'),
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // SCROLLABLE CONTENT
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Player Selection
                    _buildResponsivePlayerDropdown(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Month Selection
                    _buildResponsiveMonthDropdown(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Payment Status Selection - ENTERPRISE RESPONSIVE
                    _buildResponsivePaymentStatusSelection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 12 : 16),

                    // Notes Field
                    _buildResponsiveNotesField(isSmallScreen),

                    // Payment Summary
                    if (selectedPlayer != null && selectedMonth != null) ...[
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildResponsivePaymentSummary(isSmallScreen),
                    ],
                  ],
                ),
              ),
            ),
            
            // RESPONSIVE ACTIONS
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
                    child: TextButton(
                      onPressed: isProcessing ? null : () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canProcessPayment() ? _processPaymentMark : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 14,
                          horizontal: isSmallScreen ? 16 : 20,
                        ),
                      ),
                      child: isProcessing
                          ? SizedBox(
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
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ENTERPRISE-GRADE: Responsive Player Dropdown
  Widget _buildResponsivePlayerDropdown(bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: isSmallScreen ? 48 : 56,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Row(
                  children: [
                    Icon(Icons.person_rounded,
                        color: Colors.grey.shade600, size: isSmallScreen ? 18 : 20),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.selectPlayer,
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: DropdownButtonFormField<String>(
                  value: selectedPlayer,
                  isExpanded: true,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.selectPlayer,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey.shade500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 8,
                    ),
                  ),
                  items: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final playerName = data['name'] ?? AppLocalizations.of(context)!.unnamedPlayer;
                    final teamName = data['team'] ?? AppLocalizations.of(context)!.unknownTeam;

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playerName,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            teamName,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPlayer = value;
                      _updatePlayerTeam(value, snapshot.data!.docs);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ENTERPRISE-GRADE: Responsive Month Dropdown
  Widget _buildResponsiveMonthDropdown(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    color: Colors.grey.shade600, size: isSmallScreen ? 18 : 20),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.selectMonth,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: DropdownButtonFormField<String>(
              value: selectedMonth,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.selectMonth,
                hintStyle: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey.shade500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
              ),
              items: List.generate(12, (index) {
                final monthNumber = (index + 1).toString().padLeft(2, '0');
                final monthName = _getLocalizedMonthName(monthNumber);
                return DropdownMenuItem(
                  value: monthNumber,
                  child: Text(
                    monthName,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                });
              },
            ),
          ),
        ],
      ),
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
        color: const Color(0xFF667eea).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2)),
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
        return AppLocalizations.of(context)!.markAsPaid;
      case PaymentStatus.partial:
        return AppLocalizations.of(context)!.markAsPartial;
      case PaymentStatus.unpaid:
        return AppLocalizations.of(context)!.markAsUnpaid;
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.markAsInactive;
    }
  }

  /// ENTERPRISE-GRADE: Responsive Payment Status Selection Widget
  Widget _buildResponsivePaymentStatusSelection(bool isSmallScreen) {
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
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.grey.shade600, size: isSmallScreen ? 18 : 20),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.paymentStatus,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              child: Column(
                children: [
                  // RECEPTIONIST SCREEN: Only 3 Payment Status Options (Green, Red, Grey)
                  _buildResponsivePaymentStatusOption(PaymentStatus.paid, isSmallScreen),       // GREEN - PAID
                  _buildResponsivePaymentStatusOption(PaymentStatus.unpaid, isSmallScreen),     // RED - UNPAID
                  _buildResponsivePaymentStatusOption(PaymentStatus.notActive, isSmallScreen),  // GREY - NOT ACTIVE
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ENTERPRISE-GRADE: Responsive Individual payment status option
  Widget _buildResponsivePaymentStatusOption(PaymentStatus status, bool isSmallScreen) {
    final isSelected = selectedPaymentStatus == status;
    final statusColor = _getPaymentStatusColor(status);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 1 : 2),
      decoration: BoxDecoration(
        color: isSelected ? statusColor.withValues(alpha: 0.1) : Colors.transparent,
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
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 6 : 8,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSmallScreen ? 16 : 18,
                  height: isSmallScreen ? 16 : 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? statusColor : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? statusColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: isSmallScreen ? 10 : 12,
                        )
                      : null,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLocalizedStatusName(status),
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? statusColor : Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _getLocalizedStatusDescription(status),
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 10 : 11,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: isSmallScreen ? 6 : 8,
                  height: isSmallScreen ? 6 : 8,
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

  /// ENTERPRISE-GRADE: Responsive Notes Field
  Widget _buildResponsiveNotesField(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Icon(Icons.note_rounded,
                    color: Colors.grey.shade600, size: isSmallScreen ? 18 : 20),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.notes,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: TextField(
              controller: notesController,
              maxLines: isSmallScreen ? 2 : 3,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.optionalNotes,
                hintStyle: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ENTERPRISE-GRADE: Responsive Payment Summary
  Widget _buildResponsivePaymentSummary(bool isSmallScreen) {
    final paymentAmount = _getPaymentAmount;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFF667eea).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF667eea).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF667eea),
                size: isSmallScreen ? 14 : 16,
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.paymentSummary,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF667eea),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.year,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${widget.selectedYear}',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 3 : 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.month,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                selectedMonth != null ? _getLocalizedMonthName(selectedMonth!) : '-',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (paymentAmount > 0) ...[
            SizedBox(height: isSmallScreen ? 3 : 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.amount,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '\$${paymentAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// ENTERPRISE-GRADE: Localized Month Names
  String _getLocalizedMonthName(String monthNumber) {
    final month = int.parse(monthNumber);
    final l10n = AppLocalizations.of(context)!;
    
    switch (month) {
      case 1: return l10n.monthJanuary;
      case 2: return l10n.monthFebruary;
      case 3: return l10n.monthMarch;
      case 4: return l10n.monthApril;
      case 5: return l10n.monthMayFull;
      case 6: return l10n.monthJune;
      case 7: return l10n.monthJuly;
      case 8: return l10n.monthAugust;
      case 9: return l10n.monthSeptember;
      case 10: return l10n.monthOctober;
      case 11: return l10n.monthNovember;
      case 12: return l10n.monthDecember;
      default: return DateFormat('MMMM').format(DateTime(2024, month));
    }
  }

  /// ENTERPRISE-GRADE: Helper to update player team
  void _updatePlayerTeam(String? playerId, List<QueryDocumentSnapshot> players) {
    if (playerId != null) {
      final playerDoc = players.firstWhere((doc) => doc.id == playerId);
      final data = playerDoc.data() as Map<String, dynamic>;
      selectedPlayerTeam = data['team'] ?? AppLocalizations.of(context)!.unknownTeam;
    }
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
        return const Color(0xFF6B7280); // Grey - NOT ACTIVE STATUS
    }
  }

  /// PRODUCTION-READY: Descriptive text for each payment status
  String _getLocalizedStatusDescription(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppLocalizations.of(context)!.paymentFullyCompleted;
      case PaymentStatus.partial:
        return AppLocalizations.of(context)!.partialPaymentReceived;
      case PaymentStatus.unpaid:
        return AppLocalizations.of(context)!.noPaymentReceived;
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.playerInactiveSuspended;
    }
  }
  
  /// PRODUCTION-READY: Localized status name
  String _getLocalizedStatusName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppLocalizations.of(context)!.fullyPaid;
      case PaymentStatus.partial:
        return AppLocalizations.of(context)!.partiallyPaid;
      case PaymentStatus.unpaid:
        return AppLocalizations.of(context)!.unpaid;
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.notActive;
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
        return AppLocalizations.of(context)!.paymentMarkedPaidSuccess;
      case PaymentStatus.partial:
        return AppLocalizations.of(context)!.paymentMarkedPartialSuccess;
      case PaymentStatus.unpaid:
        return AppLocalizations.of(context)!.paymentMarkedUnpaidSuccess;
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.playerMarkedInactiveSuccess;
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
