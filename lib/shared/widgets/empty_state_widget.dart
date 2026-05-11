import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateWidget extends StatelessWidget {
  final String searchQuery;
  final String entityName;

  const EmptyStateWidget({
    super.key,
    required this.searchQuery,
    required this.entityName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                _getIconForEntity(entityName),
                color: Colors.grey.shade400,
                size: 60,
              ),
            ),
            SizedBox(height: 24),
            Text(
              searchQuery.isEmpty
                  ? 'No $entityName found'
                  : 'No results for "$searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Try adjusting your search terms or filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
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
