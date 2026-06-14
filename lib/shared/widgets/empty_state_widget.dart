import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/gradient_widgets.dart';

class EmptyStateWidget extends StatelessWidget {
  final String searchQuery;
  final String entityName;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.searchQuery,
    required this.entityName,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dark themed icon container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(color: AppTheme.border, width: 2),
              ),
              child: Icon(
                _getIconForEntity(entityName),
                color: AppTheme.textSecondary,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),

            // Title text
            Text(
              searchQuery.isEmpty
                  ? 'No $entityName found'
                  : 'No results for "$searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Subtitle text
            if (searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms or filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Optional action button
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: GradientButton(
                  label: actionLabel!,
                  onPressed: onAction!,
                  height: 44,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForEntity(String entityName) {
    switch (entityName.toLowerCase()) {
      case 'users':
        return Icons.people_rounded;
      case 'players':
        return Icons.sports_soccer_rounded;
      case 'teams':
        return Icons.groups_rounded;
      case 'sessions':
      case 'attendances':
        return Icons.event_note_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }
}
