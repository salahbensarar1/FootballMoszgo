import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your payment models
import '../../../data/models/payment_model.dart';

class PaymentChartSection extends StatelessWidget {
  final PaymentStats stats;

  const PaymentChartSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
                Icon(Icons.bar_chart_rounded,
                    color: const Color(0xFF667eea), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Monthly Collection Trend',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSimpleChart(stats.monthlyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(Map<int, double> monthlyData) {
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(12, (index) {
        final value = monthlyData[index + 1] ?? 0;
        final maxValue = monthlyData.values.isNotEmpty
            ? monthlyData.values.reduce((a, b) => a > b ? a : b)
            : 1;
        final height = (value / maxValue * 100).clamp(10, 100);

        return Column(
          children: [
            Expanded(
              child: Container(
                width: 20,
                height: height.toDouble(),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              months[index],
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }
}
