// lib/views/receptionist/components/player_payment_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';

class PlayerPaymentCard extends StatelessWidget {
  final PlayerPaymentStatus player;
  final Function(PlayerPaymentStatus) onViewDetails;
  final Function(PlayerPaymentStatus) onSendReminder;

  const PlayerPaymentCard({
    super.key,
    required this.player,
    required this.onViewDetails,
    required this.onSendReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _getStatusGradient(player.status),
                    ),
                  ),
                  child: Center(
                    child: player.status == PaymentStatus.notActive
                        ? Icon(
                            Icons.do_not_disturb_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : 'P',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        player.team,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(player.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(player.status, context),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(player.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.paymentProgress,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        _getProgressText(context),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _getProgressValue(),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(player.status),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  // Show additional info for inactive players
                  if (player.status == PaymentStatus.notActive) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.playerInactiveMonths(player.inactiveMonths.toString()),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          AppLocalizations.of(context)!.viewDetails,
                          Icons.visibility_rounded,
                          const Color(0xFF667eea),
                          () => onViewDetails(player),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          player.status == PaymentStatus.notActive
                              ? AppLocalizations.of(context)!.activate
                              : AppLocalizations.of(context)!.sendReminder,
                          player.status == PaymentStatus.notActive
                              ? Icons.play_arrow_rounded
                              : Icons.email_rounded,
                          player.status == PaymentStatus.notActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          () => onSendReminder(player),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProgressText(BuildContext context) {
    switch (player.status) {
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.inactiveMonthsProgress(player.inactiveMonths.toString());
      default:
        return AppLocalizations.of(context)!.activeMonthsProgress(
          player.paidMonths.toString(),
          player.effectiveTotalMonths.toString(),
        );
    }
  }

  double _getProgressValue() {
    switch (player.status) {
      case PaymentStatus.notActive:
        return player.inactiveMonths / 12.0;
      default:
        return player.paymentProgress; // This excludes inactive months
    }
  }

  List<Color> _getStatusGradient(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case PaymentStatus.partial:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case PaymentStatus.unpaid:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case PaymentStatus.notActive:
        return [
          const Color(0xFF6B7280),
          const Color(0xFF4B5563)
        ]; // Grey gradient
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
      case PaymentStatus.notActive:
        return const Color(0xFF6B7280); // Grey color for not active
    }
  }

  String _getStatusText(PaymentStatus status, BuildContext context) {
    switch (status) {
      case PaymentStatus.paid:
        return AppLocalizations.of(context)!.fullyPaid;
      case PaymentStatus.partial:
        return AppLocalizations.of(context)!.partial;
      case PaymentStatus.unpaid:
        return AppLocalizations.of(context)!.unpaid;
      case PaymentStatus.notActive:
        return AppLocalizations.of(context)!.notActive;
    }
  }
}
