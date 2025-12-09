import 'package:flutter/material.dart';
import 'package:footballtraining/services/mlsz_integration_service.dart';
import 'package:footballtraining/data/models/mlsz_models.dart';
import 'package:footballtraining/utils/hungarian_text_utils.dart'; // ← Updated import

class MLSZDashboardScreen extends StatefulWidget {
  const MLSZDashboardScreen({super.key});

  @override
  State<MLSZDashboardScreen> createState() => _MLSZDashboardScreenState();
}

class _MLSZDashboardScreenState extends State<MLSZDashboardScreen> {
  List<MLSZStanding>? _standings;
  MLSZLeagueConfig? _config;
  List<MLSZTeamConfiguration> _teamConfigurations = [];
  List<MLSZTeamConfiguration> _filteredTeamConfigurations = [];
  MLSZTeamConfiguration? _selectedTeam;
  bool _isLoading = true;
  String? _error;

  // Filter states
  String? _selectedRegion;
  String? _selectedAgeCategory;
  String? _selectedDivision;
  List<String> _availableRegions = [];
  List<String> _availableAgeCategories = [];
  List<String> _availableDivisions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load team configurations
      final teamConfigs = await MLSZIntegrationService.getAllTeamConfigurations();

      if (teamConfigs.isEmpty) {
        // Fallback to legacy single config
        final config = await MLSZIntegrationService.getConfiguration();
        final standings = await MLSZIntegrationService.fetchStandings();

        setState(() {
          _config = config;
          _standings = standings;
          _teamConfigurations = [];
          _filteredTeamConfigurations = [];
          _selectedTeam = null;
          _isLoading = false;
          _error = null;
        });
        return;
      }

      // Load filter options
      final regions = await MLSZIntegrationService.getAvailableRegions();
      final ageCategories = await MLSZIntegrationService.getAvailableAgeCategories();
      final divisions = await MLSZIntegrationService.getAvailableDivisions();

      // Apply filters
      final filteredTeams = MLSZIntegrationService.filterTeams(
        teamConfigs,
        region: _selectedRegion,
        ageCategory: _selectedAgeCategory,
        division: _selectedDivision,
      );

      // Use first filtered team as default selection, or first team if no filter match
      final selectedTeam = _selectedTeam ??
          (filteredTeams.isNotEmpty ? filteredTeams.first : teamConfigs.first);
      final standings = await MLSZIntegrationService.fetchStandingsForTeam(selectedTeam);

      setState(() {
        _teamConfigurations = teamConfigs;
        _filteredTeamConfigurations = filteredTeams;
        _availableRegions = regions;
        _availableAgeCategories = ageCategories;
        _availableDivisions = divisions;
        _selectedTeam = selectedTeam;
        _standings = standings;
        _config = selectedTeam.toLegacyConfig(''); // For compatibility
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

  Future<void> _applyFilters() async {
    final filteredTeams = MLSZIntegrationService.filterTeams(
      _teamConfigurations,
      region: _selectedRegion,
      ageCategory: _selectedAgeCategory,
      division: _selectedDivision,
    );

    setState(() {
      _filteredTeamConfigurations = filteredTeams;
      // Reset selected team if it's not in filtered results
      if (_selectedTeam != null && !filteredTeams.contains(_selectedTeam)) {
        _selectedTeam = filteredTeams.isNotEmpty ? filteredTeams.first : null;
      }
    });

    // Load data for the new selection
    if (_selectedTeam != null) {
      await _switchTeam(_selectedTeam!);
    }
  }

  Future<void> _switchTeam(MLSZTeamConfiguration team) async {
    if (team == _selectedTeam) return;

    setState(() {
      _selectedTeam = team;
      _isLoading = true;
    });

    try {
      final standings = await MLSZIntegrationService.fetchStandingsForTeam(team);

      setState(() {
        _standings = standings;
        _config = team.toLegacyConfig('');
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

  Future<void> _createSampleConfigs() async {
    try {
      await MLSZIntegrationService.createSampleTeamConfigurations();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample team configurations created!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadData(); // Reload data to show new teams
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create sample configs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              'League Information',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
            ),
            if (_teamConfigurations.isNotEmpty && _selectedTeam != null)
              Text(
                _selectedTeam!.displayName,
                style: const TextStyle(
                    fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF7043), Color(0xFFE91E63)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          if (_teamConfigurations.isNotEmpty)
            PopupMenuButton<MLSZTeamConfiguration>(
              icon: const Icon(Icons.sports_soccer, color: Colors.white),
              tooltip: 'Select Team',
              onSelected: _switchTeam,
              itemBuilder: (BuildContext context) {
                return _filteredTeamConfigurations.map((team) {
                  return PopupMenuItem<MLSZTeamConfiguration>(
                    value: team,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 18,
                          color: team == _selectedTeam
                              ? const Color(0xFFFF7043)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                team.displayName,
                                style: TextStyle(
                                  fontWeight: team == _selectedTeam
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: team == _selectedTeam
                                      ? const Color(0xFFFF7043)
                                      : Colors.black87,
                                ),
                              ),
                              Text(
                                team.leagueName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          if (_teamConfigurations.isEmpty)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: _createSampleConfigs,
              tooltip: 'Create Sample Teams',
            ),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C4DFF))),
            SizedBox(height: 16),
            Text('Loading league data...', style: TextStyle(fontSize: 16)),
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
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              const Text('Error Loading Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          child: Text('No data available', style: TextStyle(fontSize: 16)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          if (_teamConfigurations.isNotEmpty) _buildFilterSection(),
          if (_teamConfigurations.isNotEmpty) const SizedBox(height: 20),
          _buildKeyStatistics(),
          const SizedBox(height: 24),
          _buildDetailedLeagueTable(),
          const SizedBox(height: 20),
          _buildPerformanceAnalysis(), // ← NEW: Added performance section
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_alt, color: Color(0xFFFF7043), size: 24),
                SizedBox(width: 8),
                Text(
                  'Team Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_availableRegions.isNotEmpty)
                  _buildFilterDropdown(
                    'Region',
                    _selectedRegion,
                    _availableRegions,
                    (value) {
                      setState(() {
                        _selectedRegion = value;
                      });
                      _applyFilters();
                    },
                    Icons.location_on,
                  ),
                if (_availableAgeCategories.isNotEmpty)
                  _buildFilterDropdown(
                    'Age Category',
                    _selectedAgeCategory,
                    _availableAgeCategories,
                    (value) {
                      setState(() {
                        _selectedAgeCategory = value;
                      });
                      _applyFilters();
                    },
                    Icons.groups,
                  ),
                if (_availableDivisions.isNotEmpty)
                  _buildFilterDropdown(
                    'Division',
                    _selectedDivision,
                    _availableDivisions,
                    (value) {
                      setState(() {
                        _selectedDivision = value;
                      });
                      _applyFilters();
                    },
                    Icons.emoji_events,
                  ),
              ],
            ),
            if (_selectedRegion != null || _selectedAgeCategory != null || _selectedDivision != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Showing ${_filteredTeamConfigurations.length} of ${_teamConfigurations.length} teams',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedRegion = null;
                        _selectedAgeCategory = null;
                        _selectedDivision = null;
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear Filters'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7043),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFFFF7043)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF7043), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
        ),
        value: selectedValue,
        hint: Text('All ${label}s', style: TextStyle(color: Colors.grey.shade600)),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('League Overview',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 8),
        Text(
          cleanHungarianText(
              _config?.leagueName ?? 'Hungarian League'), // ← FIXED: Clean text
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildKeyStatistics() {
    final myTeam = _standings!.firstWhere(
      (team) => _selectedTeam != null
          ? isTeamMatch(team.teamName, _selectedTeam!.teamName)
          : isTeamMatch(team.teamName, 'mozgo'),
      orElse: () => _standings!.first,
    );

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Key Statistics',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            TextButton(
              onPressed: () {},
              child: const Text('View Details',
                  style: TextStyle(color: Color(0xFFFF7043))),
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
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
                '${myTeam.position}',
                'Position',
                Icons.emoji_events,
                const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)])),
            _buildStatCard(
                '${myTeam.points}',
                'Points',
                Icons.star,
                const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF6B9D)])),
            _buildStatCard(
                '${myTeam.wins}/${myTeam.matchesPlayed}',
                'Wins/Games',
                Icons.military_tech,
                const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF4DD0E1)])),
            _buildStatCard(
                '${myTeam.goalDifference > 0 ? '+' : ''}${myTeam.goalDifference}',
                'Goal Diff',
                Icons.trending_up,
                const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Gradient gradient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDetailedLeagueTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Complete League Table',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: DataTable(
                columnSpacing: 12,
                headingRowColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                headingTextStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                dataTextStyle: const TextStyle(fontSize: 11),
                columns: const [
                  DataColumn(label: Text('Pos'), numeric: true),
                  DataColumn(label: Text('Team')),
                  DataColumn(label: Text('M'), numeric: true),
                  DataColumn(label: Text('Gy'), numeric: true),
                  DataColumn(label: Text('D'), numeric: true),
                  DataColumn(label: Text('V'), numeric: true),
                  DataColumn(label: Text('LG'), numeric: true),
                  DataColumn(label: Text('KG'), numeric: true),
                  DataColumn(label: Text('GK'), numeric: true),
                  DataColumn(label: Text('P'), numeric: true),
                ],
                rows: _standings!.map((team) {
                  final isMyTeam = _selectedTeam != null
                      ? isTeamMatch(team.teamName, _selectedTeam!.teamName)
                      : isTeamMatch(team.teamName, 'mozgo');
                  final isTopPosition = team.position <= 3;
                  final isRelegation = team.position >= _standings!.length - 2;

                  return DataRow(
                    color: MaterialStateProperty.all(
                      isMyTeam
                          ? const Color(0xFF7C4DFF).withOpacity(0.1)
                          : isTopPosition
                              ? Colors.green.shade50
                              : isRelegation
                                  ? Colors.red.shade50
                                  : null,
                    ),
                    cells: [
                      DataCell(
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isMyTeam
                                ? const Color(0xFF7C4DFF)
                                : isTopPosition
                                    ? Colors.green
                                    : isRelegation
                                        ? Colors.red
                                        : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${team.position}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    (isMyTeam || isTopPosition || isRelegation)
                                        ? Colors.white
                                        : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            // ← FIXED: Using regular Text with cleaner
                            cleanHungarianText(
                                team.teamName), // ← FIXED: Clean the text
                            style: TextStyle(
                              fontWeight: isMyTeam
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isMyTeam ? const Color(0xFF7C4DFF) : null,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${team.matchesPlayed}')),
                      DataCell(Text('${team.wins}',
                          style: const TextStyle(color: Colors.green))),
                      DataCell(Text('${team.draws}',
                          style: TextStyle(color: Colors.grey.shade600))),
                      DataCell(Text('${team.losses}',
                          style: const TextStyle(color: Colors.red))),
                      DataCell(Text('${team.goalsFor}',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(Text('${team.goalsAgainst}',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(
                        Text(
                          '${team.goalDifference > 0 ? '+' : ''}${team.goalDifference}',
                          style: TextStyle(
                            color: team.goalDifference > 0
                                ? Colors.green
                                : team.goalDifference < 0
                                    ? Colors.red
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(Text('${team.points}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ← NEW: Added performance analysis section
  Widget _buildPerformanceAnalysis() {
    final myTeam = _standings!.firstWhere(
      (team) => _selectedTeam != null
          ? isTeamMatch(team.teamName, _selectedTeam!.teamName)
          : isTeamMatch(team.teamName, 'mozgo'),
      orElse: () => _standings!.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Team Performance Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Attack Rating',
                    '${(myTeam.goalsFor / myTeam.matchesPlayed).toStringAsFixed(1)}',
                    'Goals per game',
                    Colors.orange,
                    Icons.sports_soccer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Defense Rating',
                    '${(myTeam.goalsAgainst / myTeam.matchesPlayed).toStringAsFixed(1)}',
                    'Goals conceded per game',
                    Colors.blue,
                    Icons.security,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    'Win Rate',
                    '${((myTeam.wins / myTeam.matchesPlayed) * 100).toStringAsFixed(0)}%',
                    'Percentage of wins',
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    'Points Per Game',
                    '${(myTeam.points / myTeam.matchesPlayed).toStringAsFixed(1)}',
                    'Average points',
                    Colors.purple,
                    Icons.grade,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          Text(subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
