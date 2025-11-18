import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 26,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade700,
              ),
            ),
            Expanded(
              child: Text(
                userDisplayName ?? l10n.coach,
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isTrainingActive
              ? "Aktív edzés folyamatban"
              : "Üdvözöljük az edző felületen!",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: isTrainingActive ? Colors.green.shade600 : Colors.grey.shade600,
            fontWeight: isTrainingActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}