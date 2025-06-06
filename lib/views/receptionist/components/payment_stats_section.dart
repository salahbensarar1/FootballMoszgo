import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';

class PaymentStatsSection extends StatelessWidget {
  final PaymentStats stats;

  const PaymentStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          'Total Collected',
          '\$${stats.totalCollected.toStringAsFixed(0)}',
          Icons.account_balance_wallet_rounded,
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          stats.collectionRate,
        ),
        _buildStatCard(
          'Outstanding',
          '\$${stats.totalOutstanding.toStringAsFixed(0)}',
          Icons.pending_actions_rounded,
          const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
          100 - stats.collectionRate,
        ),
        _buildStatCard(
          'Paid Players',
          '${stats.fullyPaidPlayers}/${stats.totalPlayers}',
          Icons.people_rounded,
          const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
          (stats.fullyPaidPlayers / stats.totalPlayers * 100),
        ),
        _buildStatCard(
          'This Month',
          '\$${stats.thisMonthCollected.toStringAsFixed(0)}',
          Icons.calendar_month_rounded,
          const LinearGradient(colors: [Color(0xFFEC4899), Color(0xBE185D)]),
          stats.thisMonthProgress,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      LinearGradient gradient, double progress) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                gradient.colors.first,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
