import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamSelectionExtracted extends StatelessWidget {
  final String? coachUid;
  final Team? selectedTeam;
  final bool isTrainingActive;
  final bool isSmallScreen;
  final Function(Team?) onTeamChanged;
  final TeamService teamService;

  const TeamSelectionExtracted({
    super.key,
    this.coachUid,
    this.selectedTeam,
    required this.isTrainingActive,
    required this.isSmallScreen,
    required this.onTeamChanged,
    required this.teamService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.selectTeam, Icons.group, isSmallScreen),
          const SizedBox(height: 12),
          StreamBuilder<List<Team>>(
            stream: coachUid != null
                ? teamService.getTeamsForCoach(coachUid!)
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${l10n.errorLoadingTeams}: ${snapshot.error}',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final teams = snapshot.data ?? [];

              if (teams.isEmpty) {
                return _buildEmptyState(
                    "No teams assigned", Icons.sports_soccer);
              }

              return DropdownButtonFormField<Team>(
                decoration: InputDecoration(
                  labelText: l10n.team,
                  labelStyle: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 1.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.sports_soccer,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                dropdownColor: AppTheme.surface,
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                iconEnabledColor: AppTheme.primary,
                initialValue: selectedTeam,
                items: teams.map((team) {
                  return DropdownMenuItem<Team>(
                    value: team,
                    child: Text(team.teamName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: isTrainingActive ? null : onTeamChanged,
                isExpanded: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, Gradient? gradient}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.background, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 32, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
