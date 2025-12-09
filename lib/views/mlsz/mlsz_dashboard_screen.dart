import 'package:flutter/material.dart';
import 'package:footballtraining/services/mlsz_integration_service.dart';
import 'package:footballtraining/data/models/mlsz_models.dart';

class MLSZDashboardScreen extends StatefulWidget {
  const MLSZDashboardScreen({super.key});

  @override
  State<MLSZDashboardScreen> createState() => _MLSZDashboardScreenState();
}

class _MLSZDashboardScreenState extends State<MLSZDashboardScreen> {
  List<MLSZStanding>? _standings;
  MLSZLeagueConfig? _config;
  bool _isLoading = true;
  String? _error;

  // Fix Hungarian character encoding
  String _fixEncoding(String text) {
    return text
        .replaceAll('Ã¡', 'á')
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã­', 'í')
        .replaceAll('Ã³', 'ó')
        .replaceAll('Ã¶', 'ö')
        .replaceAll('Å', 'ő')
        .replaceAll('Ã¼', 'ü')
        .replaceAll('Å±', 'ű')
        .replaceAll('ÃllÅi', 'Üllői')
        .replaceAll('NagykÅrÃ¶s', 'Nagykőrös')
        .replaceAll('SzigetszentmiklÃ³s', 'Szigetszentmiklós')
        .replaceAll('TÃ¡rnok', 'Tárnok');
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final config = await MLSZIntegrationService.getConfiguration();
      final standings = await MLSZIntegrationService.fetchStandings();

      setState(() {
        _config = config;
        _standings = standings;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'League Information',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFF7043),
                Color(0xFFE91E63)
              ], // Orange to pink like your admin
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF7C4DFF)), // Purple like your cards
            ),
            SizedBox(height: 16),
            Text(
              'Loading league data...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('$_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_standings == null || _config == null) {
      return const Center(
        child: Text('No data available', style: TextStyle(fontSize: 16)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildKeyStatistics(),
          const SizedBox(height: 24),
          _buildLeagueTable(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'League Overview',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Here\'s your team\'s league performance',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyStatistics() {
    final myTeam = _standings!.firstWhere(
      (team) => team.teamName.toLowerCase().contains('mozgo'),
      orElse: () => _standings!.first,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Key Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {}, // Could navigate to detailed stats
              child: const Text(
                'View Details',
                style: TextStyle(color: Color(0xFFFF7043)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              '${myTeam.position}',
              'Position',
              Icons.emoji_events,
              const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)]),
            ),
            _buildStatCard(
              '${myTeam.points}',
              'Points',
              Icons.star,
              const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)]),
            ),
            _buildStatCard(
              '${myTeam.wins}',
              'Wins',
              Icons.military_tech,
              const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)]),
            ),
            _buildStatCard(
              '${myTeam.goalDifference > 0 ? '+' : ''}${myTeam.goalDifference}',
              'Goal Diff',
              Icons.trending_up,
              const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'League Table',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _standings!.length,
            itemBuilder: (context, index) {
              final team = _standings![index];
              final isMyTeam = team.teamName.toLowerCase().contains('mozgo');

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMyTeam
                      ? const Color(0xFF7C4DFF).withOpacity(0.1)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isMyTeam
                      ? Border.all(
                          color: const Color(0xFF7C4DFF).withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    // Position circle (like your admin design)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isMyTeam
                            ? const Color(0xFF7C4DFF)
                            : team.position <= 3
                                ? Colors.amber
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${team.position}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (isMyTeam || team.position <= 3)
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Team info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fixEncoding(team.teamName),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: isMyTeam
                                  ? const Color(0xFF7C4DFF)
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MP: ${team.matchesPlayed} | GD: ${team.goalDifference > 0 ? '+' : ''}${team.goalDifference}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Points (like your attendance numbers)
                    Text(
                      '${team.points}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMyTeam
                            ? const Color(0xFF7C4DFF)
                            : const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
