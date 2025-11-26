import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';
import '../../../services/organization_context.dart';
import '../../../utils/batch_size_constants.dart';

class BulkReminderDialog extends StatefulWidget {
  final int selectedYear;
  final Map<String, double> teamPaymentFees;

  const BulkReminderDialog({
    super.key,
    required this.selectedYear,
    required this.teamPaymentFees,
  });

  @override
  State<BulkReminderDialog> createState() => _BulkReminderDialogState();
}

class _BulkReminderDialogState extends State<BulkReminderDialog> {
  bool isProcessing = false;
  List<PaymentReminder> reminderQueue = [];
  bool includePartiallyPaid = true;
  bool includeUnpaid = true;
  bool includeTeamsWithoutFees = false;
  String selectedTeam = 'all';

  @override
  void initState() {
    super.initState();
    _loadReminderQueue();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.email_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Bulk Reminders',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Payment reminders for ${widget.selectedYear}',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Options
            _buildFilterSection(),
            const SizedBox(height: 16),

            // Team Filter
            _buildTeamFilter(),
            const SizedBox(height: 16),

            // Reminder Preview
            _buildReminderPreview(),
            const SizedBox(height: 16),

            // Info Section
            _buildInfoSection(),
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
          onPressed: _canSendReminders() ? _processBulkReminders : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
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
                  'Send ${reminderQueue.length} Reminders',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Include Players',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text(
            'Unpaid Players',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Players with no payments',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includeUnpaid,
          onChanged: (value) {
            setState(() {
              includeUnpaid = value ?? true;
              _loadReminderQueue();
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(
            'Partially Paid Players',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Players with some outstanding months',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includePartiallyPaid,
          onChanged: (value) {
            setState(() {
              includePartiallyPaid = value ?? true;
              _loadReminderQueue();
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(
            'Teams Without Payment Fees',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Include teams with no configured fees',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includeTeamsWithoutFees,
          onChanged: (value) {
            setState(() {
              includeTeamsWithoutFees = value ?? false;
              _loadReminderQueue();
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTeamFilter() {
    // MEMORY-SAFE: Added limit to prevent crashes with thousands of teams
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .limit(BatchSizeConstants.dropdownMaxItems)
          .orderBy('team_name')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final teams = [
          'all',
          ...snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['team_name'] as String;
          })
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Filter',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedTeam,
                decoration: InputDecoration(
                  prefixIcon:
                      Icon(Icons.groups_rounded, color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: teams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(
                      team == 'all' ? 'All Teams' : team,
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTeam = value ?? 'all';
                    _loadReminderQueue();
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderPreview() {
    final totalAmount =
        reminderQueue.fold<double>(0, (sum, r) => sum + r.outstandingAmount);
    final teamsWithFees =
        reminderQueue.where((r) => r.outstandingAmount > 0).length;
    final teamsWithoutFees =
        reminderQueue.where((r) => r.outstandingAmount == 0).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: const Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Reminder Summary',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Recipients:', '${reminderQueue.length}'),
          _buildSummaryRow('Valid Emails:',
              '${reminderQueue.where((r) => r.hasValidEmail).length}'),
          _buildSummaryRow('Teams with Fees:', '$teamsWithFees'),
          if (teamsWithoutFees > 0)
            _buildSummaryRow('Teams without Fees:', '$teamsWithoutFees'),
          _buildSummaryRow(
              'Outstanding Amount:', '\$${totalAmount.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Only players with valid email addresses will receive reminders. Reminders include details of unpaid months and team-specific fees.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (!includeTeamsWithoutFees) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_rounded,
                    color: Colors.orange.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Teams without payment fees are excluded from reminders.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
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

  bool _canSendReminders() {
    return reminderQueue.isNotEmpty &&
        reminderQueue.any((r) => r.hasValidEmail) &&
        !isProcessing;
  }

  Future<void> _loadReminderQueue() async {
    try {
      final playersSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('players')
          .get();

      List<PaymentReminder> reminders = [];

      for (var playerDoc in playersSnapshot.docs) {
        final playerData = playerDoc.data();
        final playerTeam = playerData['team'] ?? '';

        // Apply team filter
        if (selectedTeam != 'all' && playerTeam != selectedTeam) {
          continue;
        }

        // Get team payment fee
        final teamFee = widget.teamPaymentFees[playerTeam] ?? 0.0;

        // Skip teams without fees if not included
        if (!includeTeamsWithoutFees && teamFee == 0.0) {
          continue;
        }

        // Get payment data for this player
        final paymentsSnapshot = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(OrganizationContext.currentOrgId)
            .collection('players')
            .doc(playerDoc.id)
            .collection('payments')
            .where('year', isEqualTo: widget.selectedYear.toString())
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => PaymentRecord.fromFirestore(doc))
            .toList();

        // Create player payment status
        final playerStatus =
            PlayerPaymentStatus.fromFirestore(playerDoc, payments);

        // Apply status filters
        bool shouldInclude = false;
        if (includeUnpaid && playerStatus.status == PaymentStatus.unpaid) {
          shouldInclude = true;
        }
        if (includePartiallyPaid &&
            playerStatus.status == PaymentStatus.partial) {
          shouldInclude = true;
        }

        if (shouldInclude && playerStatus.hasOutstanding) {
          final reminder = PaymentReminder.fromPlayerStatus(
            playerStatus,
            payments,
            teamFee, // Use team-specific fee instead of fixed amount
          );

          if (reminder.hasOutstanding || includeTeamsWithoutFees) {
            reminders.add(reminder);
          }
        }
      }

      setState(() {
        reminderQueue = reminders;
      });
    } catch (e) {
      print('Error loading reminder queue: $e');
    }
  }

  Future<void> _processBulkReminders() async {
    if (!_canSendReminders()) return;

    setState(() => isProcessing = true);

    try {
      int remindersSent = 0;

      for (var reminder in reminderQueue) {
        if (reminder.hasValidEmail) {
          // In a real app, you would send an actual email here
          // For now, we'll just simulate the process
          await Future.delayed(const Duration(milliseconds: 100));
          remindersSent++;
        }
      }

      Navigator.pop(context);
      _showSuccessSnackBar(
          '$remindersSent payment reminders sent successfully!');
    } catch (e) {
      _showErrorSnackBar('Error sending reminders: $e');
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
