import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/services/organization_context.dart';

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

  const PlayersSection({
    super.key,
    required this.selectedTeam,
    required this.initialAttendance,
    required this.initialNotes,
    required this.isTrainingActive,
    required this.isSmallScreen,
    required this.onSaveSession,
    this.currentSessionId,
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

    return _buildCard(
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
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              "Játékosok betöltése...", Icons.people, widget.isSmallScreen),
          const SizedBox(height: 24),

          // Skeleton loaders for player cards
          for (int i = 0; i < 5; i++)
            Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatsCard(Map<String, int> stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Jelenlét statisztika",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.isSmallScreen ? 14 : 16,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Jelen", stats['present'].toString(),
                  Icons.check_circle_outline, Colors.green),
              _buildStatItem("Hiányzó", stats['absent'].toString(),
                  Icons.cancel_outlined, Colors.red.shade400),
              _buildStatItem("Összes", stats['total'].toString(),
                  Icons.people_outline, Colors.blue.shade700),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  stats['total'] == 0 ? 0 : stats['present']! / stats['total']!,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Jelenlét: ${stats['total'] == 0 ? '0' : ((stats['present']! / stats['total']!) * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: widget.isSmallScreen ? 12 : 14,
              color: Colors.blue.shade800,
            ),
            textAlign: TextAlign.center,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Játékos keresése...",
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade500),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(fontSize: 14),
      ),
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
      color: isSelected ? Colors.blue.shade500 : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Nincs találat a \"${_searchController.text}\" keresésre",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Próbálj más keresési feltételt",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : Colors.grey.shade200,
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
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            highlightColor: isPresent
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPresent
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.grey.shade50, Colors.grey.shade100],
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
                              : Colors.grey.shade400,
                          child: Text(
                            playerName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
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
                                color: Colors.black87,
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
                                      color: Colors.white,
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
                          activeColor: Colors.white,
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
                        color: Colors.grey.shade400,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: isPresent
                                ? Colors.green.shade300
                                : Colors.grey.shade400),
                      ),
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.note_alt_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    controller: TextEditingController(text: playerNote),
                    onChanged: (value) {
                      _updateNotes(playerId, value);
                    },
                    enabled: widget.isTrainingActive,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.black87,
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
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.currentSessionId != null
                ? Colors.orange.withOpacity(0.3)
                : Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => widget.onSaveSession(players, _attendance, _notes),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: widget.currentSessionId != null
              ? Colors.orange.shade500
              : Colors.blue.shade600,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.currentSessionId != null
                ? Icons.edit_note_rounded
                : Icons.save_rounded,
            size: isSmallScreen ? 18 : 20,
            color: Colors.white,
          ),
        ),
        label: Text(
          widget.currentSessionId != null
              ? "Frissítés és edzés bezárása"
              : "Edzés mentése",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
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
