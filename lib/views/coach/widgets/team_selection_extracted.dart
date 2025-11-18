import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/repositories/team_service.dart';

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
            stream: coachUid != null ? teamService.getTeamsForCoach(coachUid!) : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${l10n.errorLoadingTeams}: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final teams = snapshot.data ?? [];

              if (teams.isEmpty) {
                return _buildEmptyState("No teams assigned", Icons.sports_soccer);
              }

              return DropdownButtonFormField<Team>(
                decoration: InputDecoration(
                  labelText: l10n.team,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.sports_soccer),
                ),
                value: selectedTeam,
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
        gradient: gradient,
        color: gradient == null ? Colors.white : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFF27121), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}