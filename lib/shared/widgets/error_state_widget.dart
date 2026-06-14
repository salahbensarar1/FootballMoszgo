import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/gradient_widgets.dart';

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final String? title;
  final String? subtitle;

  const ErrorStateWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon container with dark theme
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Error title
            Text(
              title ?? 'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Error subtitle
            Text(
              subtitle ?? 'Please try again or contact support if the problem persists',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Error details (if provided)
            if (error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Retry button with gradient
            SizedBox(
              width: 160,
              child: GradientButton(
                label: 'Retry',
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
                height: 48,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
