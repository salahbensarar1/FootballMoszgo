import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayersSection extends StatefulWidget {
  final Team selectedTeam;
  final Map<String, bool> initialAttendance;
  final Map<String, String> initialNotes;
  final bool isTrainingActive;
  final bool isSmallScreen;
  final Function(
          List<QueryDocumentSnapshot>, Map<String, bool>, Map<String, String>)
      onSaveSession;
  final String? currentSessionId;
  final void Function(List<QueryDocumentSnapshot>)? onPlayersChanged;

  const PlayersSection({
    super.key,
    required this.selectedTeam,
    required this.initialAttendance,
    required this.initialNotes,
    required this.isTrainingActive,
    required this.isSmallScreen,
    required this.onSaveSession,
    this.currentSessionId,
    this.onPlayersChanged,
  });

  @override
  State<PlayersSection> createState() => _PlayersSectionState();
}

class _PlayersSectionState extends State<PlayersSection>
    with AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, bool> _attendance;
  late Map<String, String> _notes;
  List<QueryDocumentSnapshot>? _cachedPlayers;
  List<QueryDocumentSnapshot> _filteredPlayers = [];
  StreamSubscription<QuerySnapshot>? _playersSubscription;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Create local copies of attendance and notes data
    _attendance = Map<String, bool>.from(widget.initialAttendance);
    _notes = Map<String, String>.from(widget.initialNotes);
    _initializePlayersStream();

    _searchController.addListener(_filterPlayers);
  }

  @override
  void didUpdateWidget(PlayersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if initial data changes (e.g., team switch)
    if (oldWidget.selectedTeam.teamName != widget.selectedTeam.teamName) {
      setState(() {
        _isLoading = true;
        _attendance = Map<String, bool>.from(widget.initialAttendance);
        _notes = Map<String, String>.from(widget.initialNotes);
      });
      _initializePlayersStream();
    }
  }

  @override
  void dispose() {
    _playersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initializePlayersStream() {
    _playersSubscription?.cancel();
    _playersSubscription = _firestore
        .collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection('players')
        .where('team', isEqualTo: widget.selectedTeam.teamName)
        .orderBy('name')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _cachedPlayers = snapshot.docs;
          _filteredPlayers = snapshot.docs;
          // Initialize attendance for new players
          for (var player in _cachedPlayers!) {
            _attendance[player.id] ??= false;
            _notes[player.id] ??= '';
          }
          _isLoading = false;
        });
        widget.onPlayersChanged?.call(_cachedPlayers!);
      }
    });
  }

  void _filterPlayers() {
    if (_cachedPlayers == null) return;

    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredPlayers = _cachedPlayers!;
      } else {
        _filteredPlayers = _cachedPlayers!.where((player) {
          final name = player['name'].toString().toLowerCase();
          return name.contains(query);
        }).toList();
      }
    });
  }

  void _updateAttendance(String playerId, bool isPresent) {
    setState(() {
      _attendance[playerId] = isPresent;
    });

    // Add haptic feedback for better user experience
    if (isPresent) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _updateNotes(String playerId, String notes) {
    _notes[playerId] = notes;
  }

  // Function to get attendance stats
  Map<String, int> _getAttendanceStats() {
    if (_cachedPlayers == null) return {'present': 0, 'absent': 0, 'total': 0};

    int presentCount = 0;

    for (final player in _cachedPlayers!) {
      if (_attendance[player.id] == true) {
        presentCount++;
      }
    }

    return {
      'present': presentCount,
      'absent': _cachedPlayers!.length - presentCount,
      'total': _cachedPlayers!.length
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_cachedPlayers == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final players = _filteredPlayers;
    final stats = _getAttendanceStats();

    if (_cachedPlayers!.isEmpty) {
      return _buildEmptyState(
          'Nem található játékos ebben a csapatban', Icons.people_outline);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("${l10n.players}: ${_cachedPlayers!.length}",
              Icons.people, widget.isSmallScreen),
          const SizedBox(height: 16),

          // Attendance Stats Card
          _buildAttendanceStatsCard(stats),
          const SizedBox(height: 16),

          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 16),

          // Players list
          if (players.isEmpty && _searchController.text.isNotEmpty)
            _buildNoSearchResults(),

          // Use Column with RepaintBoundary for each player card
          ...players.asMap().entries.map((entry) {
            final player = entry.value;
            return RepaintBoundary(
              key: ValueKey('repaint_${player.id}'),
              child: _buildPlayerCard(player, widget.isSmallScreen),
            );
          }).toList(),

          if (widget.isTrainingActive && players.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSaveSessionButton(players, widget.isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              "Loading players...", Icons.people, widget.isSmallScreen),
          const SizedBox(height: 24),

          // Skeleton loaders for player cards
          for (int i = 0; i < 5; i++)
            ShimmerCard(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatsCard(Map<String, int> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Attendance Statistics",
            style: AppTheme.heading3.copyWith(
              color: AppTheme.background,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Present", stats['present'].toString(),
                  Icons.check_circle_outline, AppTheme.background),
              _buildStatItem("Absent", stats['absent'].toString(),
                  Icons.cancel_outlined, AppTheme.background),
              _buildStatItem("Total", stats['total'].toString(),
                  Icons.people_outline, AppTheme.background),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  stats['total'] == 0 ? 0 : stats['present']! / stats['total']!,
              minHeight: 8,
              backgroundColor: AppTheme.background.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Attendance: ${stats['total'] == 0 ? '0' : ((stats['present']! / stats['total']!) * 100).toStringAsFixed(0)}%",
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.background.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.heading2.copyWith(
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return PremiumTextField(
      controller: _searchController,
      hintText: "Search players...",
      labelText: "Search",
      leadingIcon: Icons.search,
      trailingWidget: _searchController.text.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear, color: AppTheme.textSecondary),
              onPressed: () {
                _searchController.clear();
              },
            )
          : null,
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("Összes játékos", true, () {}),
          const SizedBox(width: 8),
          _buildFilterChip("Jelenlévők", false, () {
            setState(() {
              _filteredPlayers = _cachedPlayers!
                  .where((player) => _attendance[player.id] == true)
                  .toList();
            });
          }),
          const SizedBox(width: 8),
          _buildFilterChip("Hiányzók", false, () {
            setState(() {
              _filteredPlayers = _cachedPlayers!
                  .where((player) => _attendance[player.id] != true)
                  .toList();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: isSelected ? AppTheme.primary : AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: isSelected ? null : Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: isSelected ? AppTheme.background : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            "No results for \"${_searchController.text}\"",
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Try a different search term",
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(QueryDocumentSnapshot player, bool isSmallScreen) {
    final playerId = player.id;
    final playerName = player['name'];
    final isPresent = _attendance[playerId] ?? false;
    final String playerNote = _notes[playerId] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      key: ValueKey('player_$playerId'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isTrainingActive
                ? () {
                    HapticFeedback.lightImpact();
                    _updateAttendance(playerId, !isPresent);
                  }
                : null,
            splashColor: isPresent
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            highlightColor: isPresent
                ? Colors.green.withValues(alpha: 0.05)
                : Colors.red.withValues(alpha: 0.05),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPresent
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [AppTheme.surface2, AppTheme.surface2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'player_avatar_$playerId',
                        child: CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundColor: isPresent
                              ? Colors.green.shade400
                              : AppTheme.textMuted,
                          child: Text(
                            playerName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: AppTheme.surface,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 15 : 17,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? Colors.green.shade500
                                        : Colors.red.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isPresent ? "Jelen" : "Hiányzó",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      color: AppTheme.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.isTrainingActive)
                        Switch.adaptive(
                          value: isPresent,
                          onChanged: (val) {
                            HapticFeedback.lightImpact();
                            _updateAttendance(playerId, val);
                          },
                          activeColor: AppTheme.surface,
                          activeTrackColor: Colors.green.shade400,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: TextField(
                    key: ValueKey('notes_$playerId'),
                    decoration: InputDecoration(
                      hintText: "Megjegyzések (opcionális)",
                      hintStyle: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: isPresent
                                ? Colors.green.shade300
                                : AppTheme.textMuted),
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.note_alt_outlined,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    controller: TextEditingController(text: playerNote),
                    onChanged: (value) {
                      _updateNotes(playerId, value);
                    },
                    enabled: widget.isTrainingActive,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveSessionButton(
      List<QueryDocumentSnapshot> players, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      child: GradientButton(
        label: widget.currentSessionId != null
            ? "Update & Close Training"
            : "Save Training",
        onPressed: () => widget.onSaveSession(players, _attendance, _notes),
      ),
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
          Icon(icon, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
