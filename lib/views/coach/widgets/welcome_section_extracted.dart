import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeSectionExtracted extends StatelessWidget {
  final String? userDisplayName;
  final bool isSmallScreen;
  final bool isTrainingActive;

  const WelcomeSectionExtracted({
    super.key,
    this.userDisplayName,
    required this.isSmallScreen,
    required this.isTrainingActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Hello, ",
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                userDisplayName ?? l10n.coach,
                style: GoogleFonts.syne(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTrainingActive ? AppTheme.success : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isTrainingActive ? "Training in progress" : "Ready for training",
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 13 : 14,
                color: isTrainingActive
                    ? AppTheme.success
                    : AppTheme.textSecondary,
                fontWeight:
                    isTrainingActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
