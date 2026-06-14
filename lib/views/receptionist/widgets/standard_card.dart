import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/core/theme/app_theme.dart';

class StandardCard extends StatelessWidget {
  final DocumentSnapshot item;
  final int currentTab;
  final List<Color> gradient;
  final IconData activeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StandardCard({
    super.key,
    required this.item,
    required this.currentTab,
    required this.gradient,
    required this.activeIcon,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = item.data() as Map<String, dynamic>;

    String title;
    String subtitle;

    if (currentTab == 0) {
      // Coach
      title = data['name'] ?? 'Unnamed Coach';
      subtitle = data['role_description'] ?? data['email'] ?? 'Coach';
    } else {
      // Team
      title = data['team_name'] ?? 'Unnamed Team';
      final playerCount = data['number_of_players'] ?? 0;
      final coachIds = data['coach_ids'] as List<dynamic>? ?? [];
      subtitle = "$playerCount players • ${coachIds.length} coaches";
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: gradient[0].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(activeIcon, color: gradient[0], size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == "edit") {
              onEdit();
            } else if (value == "delete") {
              onDelete();
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [
                  Icon(Icons.edit_rounded,
                      size: 20, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(l10n.edit,
                      style: TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete_rounded,
                      size: 20, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(l10n.delete,
                      style: TextStyle(color: Colors.red.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
