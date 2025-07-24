import 'package:flutter/material.dart';
import 'package:footballtraining/data/models/enhanced_models.dart';
import 'package:footballtraining/services/coach_dashboard_service.dart';

/// Production-Ready Coach Dashboard Widget
class CoachDashboardWidget extends StatefulWidget {
  final String coachId;
  
  const CoachDashboardWidget({
    Key? key,
    required this.coachId,
  }) : super(key: key);

  @override
  State<CoachDashboardWidget> createState() => _CoachDashboardWidgetState();
}

class _CoachDashboardWidgetState extends State<CoachDashboardWidget> {
  final CoachDashboardService _dashboardService = CoachDashboardService();
  TeamAssignment? selectedTeam;
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CoachDashboardData>(
      stream: _dashboardService.getCoachDashboard(widget.coachId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        final dashboardData = snapshot.data;
        if (dashboardData == null || !dashboardData.hasTeams) {
          return _buildNoTeamsWidget();
        }

        return _buildDashboard(dashboardData);
      },
    );
  }

  Widget _buildDashboard(CoachDashboardData dashboardData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Selection Section
        _buildTeamSelector(dashboardData.assignedTeams),
        
        const SizedBox(height: 16),
        
        // Selected Team Content
        if (selectedTeam != null) ...[
          _buildTeamContent(selectedTeam!),
        ] else ...[
          _buildSelectTeamPrompt(),
        ],
      ],
    );
  }

  Widget _buildTeamSelector(List<TeamAssignment> teams) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Select Team',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TeamAssignment>(
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
              ),
              value: selectedTeam,
              items: teams.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(team.teamName),
                      Text(
                        'Role: ${team.role}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (team) {
                setState(() {
                  selectedTeam = team;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamContent(TeamAssignment team) {
    return Expanded(
      child: Column(
        children: [
          // Team Players Section
          Expanded(
            flex: 2,
            child: _buildPlayersSection(team),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          _buildQuickActions(team),
          
          const SizedBox(height: 16),
          
          // Recent Sessions
          Expanded(
            flex: 1,
            child: _buildRecentSessions(team),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection(TeamAssignment team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Team Players',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<PlayerAttendance>>(
                stream: _dashboardService.getTeamPlayers(team.teamName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final players = snapshot.data ?? [];
                  if (players.isEmpty) {
                    return const Center(
                      child: Text('No players in this team'),
                    );
                  }

                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(player.playerName[0].toUpperCase()),
                        ),
                        title: Text(player.playerName),
                        subtitle: Text('Player ID: ${player.playerId}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPlayerDetails(player),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(TeamAssignment team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createTrainingSession(team),
                    icon: const Icon(Icons.add),
                    label: const Text('New Training'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewTeamStats(team),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Team Stats'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessions(TeamAssignment team) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<TrainingSession>>(
                stream: _dashboardService.getTeamSessions(team.teamName, limit: 5),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) {
                    return const Center(
                      child: Text('No recent sessions'),
                    );
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(
                          '${session.startTime.day}/${session.startTime.month} - ${session.pitchLocation}',
                        ),
                        subtitle: Text(session.notes),
                        trailing: Text(
                          '${session.players.where((p) => p.present).length}/${session.players.length}',
                        ),
                        onTap: () => _viewSessionDetails(session),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectTeamPrompt() {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Select a team to get started',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoTeamsWidget() {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No teams assigned',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Contact your administrator to be assigned to teams',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error loading dashboard',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlayerDetails(PlayerAttendance player) {
    // Navigate to player details
  }

  void _createTrainingSession(TeamAssignment team) {
    // Navigate to training session creation
  }

  void _viewTeamStats(TeamAssignment team) {
    // Navigate to team statistics
  }

  void _viewSessionDetails(TrainingSession session) {
    // Navigate to session details
  }
}