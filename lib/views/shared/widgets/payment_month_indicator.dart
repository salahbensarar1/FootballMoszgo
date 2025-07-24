// lib/views/shared/widgets/payment_month_indicator.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/utils/date_formatter.dart';
import 'package:footballtraining/data/models/payment_model.dart';

class PaymentMonthIndicator extends StatefulWidget {
  final String playerId;
  final bool isEditable;
  final String? currentUserEmail;
  final int? selectedYear;
  final Function(PaymentStatus, String)? onStatusChanged;
  final bool showTooltips;
  final double circleSize;
  final bool enableAnimations;

  const PaymentMonthIndicator({
    Key? key,
    required this.playerId,
    this.isEditable = false,
    this.currentUserEmail,
    this.selectedYear,
    this.onStatusChanged,
    this.showTooltips = true,
    this.circleSize = 26.0,
    this.enableAnimations = true,
  }) : super(key: key);

  @override
  State<PaymentMonthIndicator> createState() => _PaymentMonthIndicatorState();
}

class _PaymentMonthIndicatorState extends State<PaymentMonthIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentYear = (widget.selectedYear ?? now.year).toString();
    final months = DateFormatter.getMonthNames(); // Fixed: Remove parameter

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('players')
          .doc(widget.playerId)
          .collection('payments')
          .where('year', isEqualTo: currentYear)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingIndicator();
        }

        final paymentData = _processPaymentData(snapshot.data!.docs);

        return _buildPaymentIndicators(months, paymentData, currentYear);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: widget.circleSize + 20,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _processPaymentData(
      List<DocumentSnapshot> docs) {
    final Map<String, Map<String, dynamic>> paymentData = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final monthKey = data['month'] as String;

      paymentData[monthKey] = {
        'isPaid': data['isPaid'] ?? false,
        'isActive': data['isActive'] ??
            true, // Default to true for backward compatibility
        'updatedAt': data['updatedAt'],
        'updatedBy': data['updatedBy'],
      };
    }

    return paymentData;
  }

  Widget _buildPaymentIndicators(
    List<String> months,
    Map<String, Map<String, dynamic>> paymentData,
    String currentYear,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 350;
        final circleSize =
            isSmallScreen ? widget.circleSize * 0.85 : widget.circleSize;
        final spacing = isSmallScreen ? 2.0 : 3.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(12, (index) {
              final monthKey = (index + 1).toString().padLeft(2, '0');
              final payment = paymentData[monthKey];
              final status = _determinePaymentStatus(payment);

              return Container(
                margin: EdgeInsets.symmetric(horizontal: spacing),
                child: _buildMonthCircle(
                  index,
                  monthKey,
                  months[index],
                  status,
                  circleSize,
                  currentYear,
                  payment,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  PaymentStatus _determinePaymentStatus(Map<String, dynamic>? payment) {
    if (payment == null) {
      return PaymentStatus.unpaid;
    }

    final isActive = payment['isActive'] ?? true;
    final isPaid = payment['isPaid'] ?? false;

    if (!isActive) {
      return PaymentStatus.notActive;
    }

    if (isPaid) {
      return PaymentStatus.paid;
    }

    return PaymentStatus.unpaid;
  }

  Widget _buildMonthCircle(
    int index,
    String monthKey,
    String monthName,
    PaymentStatus status,
    double size,
    String currentYear,
    Map<String, dynamic>? payment,
  ) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    Widget circle = GestureDetector(
      onTap: widget.isEditable
          ? () => _handleCircleTap(monthKey, status, currentYear)
          : null,
      onLongPress: widget.isEditable
          ? () => _showStatusMenu(monthKey, status, currentYear)
          : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enableAnimations ? _scaleAnimation.value : 1.0,
            child: Transform.rotate(
              angle: widget.enableAnimations ? _rotationAnimation.value : 0.0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _getStatusGradient(status),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: status == PaymentStatus.notActive
                      ? Icon(
                          icon,
                          color: Colors.white,
                          size: size * 0.5,
                        )
                      : Text(
                          monthName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Add tooltip if enabled
    if (widget.showTooltips) {
      return Tooltip(
        message: _getTooltipMessage(monthName, status, payment),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(milliseconds: 2000),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        child: circle,
      );
    }

    return circle;
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Colors.green.shade600;
      case PaymentStatus.unpaid:
        return Colors.red.shade600;
      case PaymentStatus.partial:
        return Colors.orange.shade600;
      case PaymentStatus.notActive:
        return Colors.grey.shade500; // Grey color for not active
    }
  }

  List<Color> _getStatusGradient(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return [Colors.green.shade400, Colors.green.shade600];
      case PaymentStatus.unpaid:
        return [Colors.red.shade400, Colors.red.shade600];
      case PaymentStatus.partial:
        return [Colors.orange.shade400, Colors.orange.shade600];
      case PaymentStatus.notActive:
        return [Colors.grey.shade400, Colors.grey.shade600]; // Grey gradient
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return Icons.check_circle;
      case PaymentStatus.unpaid:
        return Icons.cancel;
      case PaymentStatus.partial:
        return Icons.schedule;
      case PaymentStatus.notActive:
        return Icons.do_not_disturb; // Icon for not active
    }
  }

  String _getTooltipMessage(
      String monthName, PaymentStatus status, Map<String, dynamic>? payment) {
    final statusText = status.displayName;

    if (payment != null && payment['updatedAt'] != null) {
      final timestamp = payment['updatedAt'] as Timestamp;
      final date = timestamp.toDate();
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      return '$monthName: $statusText\nUpdated: $formattedDate';
    }

    return '$monthName: $statusText';
  }

  void _handleCircleTap(
      String monthKey, PaymentStatus currentStatus, String currentYear) {
    if (widget.enableAnimations) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    // Cycle through statuses: unpaid -> paid -> notActive -> unpaid
    PaymentStatus nextStatus;
    switch (currentStatus) {
      case PaymentStatus.unpaid:
        nextStatus = PaymentStatus.paid;
        break;
      case PaymentStatus.paid:
        nextStatus = PaymentStatus.notActive;
        break;
      case PaymentStatus.notActive:
        nextStatus = PaymentStatus.unpaid;
        break;
      case PaymentStatus.partial:
        nextStatus = PaymentStatus.paid;
        break;
    }

    _updatePaymentStatus(monthKey, nextStatus, currentYear);
  }

  void _showStatusMenu(
      String monthKey, PaymentStatus currentStatus, String currentYear) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Update Payment Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Month: ${DateFormatter.getMonthName(int.parse(monthKey))}', // Fixed: Use proper method
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Status options
            ...PaymentStatus.values.map((status) {
              final isSelected = status == currentStatus;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(context);
                      if (status != currentStatus) {
                        _updatePaymentStatus(monthKey, status, currentYear);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _getStatusColor(status).withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? _getStatusColor(status)
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getStatusGradient(status),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getStatusIcon(status),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status.displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  _getStatusDescription(status),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: _getStatusColor(status),
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDescription(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Payment completed for this month';
      case PaymentStatus.unpaid:
        return 'Payment not yet received';
      case PaymentStatus.partial:
        return 'Partial payment received';
      case PaymentStatus.notActive:
        return 'Player not active for this month';
    }
  }

  Future<void> _updatePaymentStatus(
      String monthKey, PaymentStatus newStatus, String currentYear) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('players')
          .doc(widget.playerId)
          .collection('payments')
          .doc('$currentYear-$monthKey');

      switch (newStatus) {
        case PaymentStatus.paid:
          await docRef.set({
            'playerId': widget.playerId,
            'year': currentYear,
            'month': monthKey,
            'isPaid': true,
            'isActive': true,
            'updatedAt': Timestamp.now(),
            'updatedBy': widget.currentUserEmail ?? 'Unknown',
          }, SetOptions(merge: true));
          break;

        case PaymentStatus.unpaid:
          await docRef.set({
            'playerId': widget.playerId,
            'year': currentYear,
            'month': monthKey,
            'isPaid': false,
            'isActive': true,
            'updatedAt': Timestamp.now(),
            'updatedBy': widget.currentUserEmail ?? 'Unknown',
          }, SetOptions(merge: true));
          break;

        case PaymentStatus.notActive:
          await docRef.set({
            'playerId': widget.playerId,
            'year': currentYear,
            'month': monthKey,
            'isPaid': false,
            'isActive': false,
            'updatedAt': Timestamp.now(),
            'updatedBy': widget.currentUserEmail ?? 'Unknown',
          }, SetOptions(merge: true));
          break;

        case PaymentStatus.partial:
          await docRef.set({
            'playerId': widget.playerId,
            'year': currentYear,
            'month': monthKey,
            'isPaid': false, // Partial is handled differently in your system
            'isActive': true,
            'updatedAt': Timestamp.now(),
            'updatedBy': widget.currentUserEmail ?? 'Unknown',
          }, SetOptions(merge: true));
          break;
      }

      // Call the callback if provided
      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!(newStatus, monthKey);
      }

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _getStatusIcon(newStatus),
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                    '${DateFormatter.getMonthName(int.parse(monthKey))} marked as ${newStatus.displayName}'),
              ],
            ),
            backgroundColor: _getStatusColor(newStatus),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error updating payment: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      print('Error updating payment status: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<void> _togglePayment(
      String playerId, String year, String month, bool isPaid) async {
    final status = isPaid ? PaymentStatus.paid : PaymentStatus.unpaid;
    await _updatePaymentStatus(month, status, year);
  }
}
