import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:intl/intl.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen>
    with TickerProviderStateMixin {
  // Services
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeamService _teamService = TeamService();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Current User
  String? get coachUid => _auth.currentUser?.uid;

  // Session State
  Team? selectedTeam;
  String? trainingType;
  DateTime? trainingStart;
  DateTime? trainingEnd;
  String? currentSessionId;
  bool hasEditedSession = false;

  // Controllers
  final TextEditingController notesController = TextEditingController();
  final TextEditingController pitchController = TextEditingController();

  // Player Data
  Map<String, bool> attendance = {};
  Map<String, String> notes = {};

  // Training Types Configuration
  final List<TrainingTypeConfig> trainingTypes = [
    TrainingTypeConfig('game', Icons.sports_soccer,
        [Colors.red.shade400, Colors.red.shade600]),
    TrainingTypeConfig(
        'training', Icons.sports, [Colors.blue.shade400, Colors.blue.shade600]),
    TrainingTypeConfig('tactical', Icons.analytics,
        [Colors.purple.shade400, Colors.purple.shade600]),
    TrainingTypeConfig('fitness', Icons.fitness_center,
        [Colors.orange.shade400, Colors.orange.shade600]),
    TrainingTypeConfig('technical', Icons.precision_manufacturing,
        [Colors.green.shade400, Colors.green.shade600]),
    TrainingTypeConfig('theoretical', Icons.school,
        [Colors.indigo.shade400, Colors.indigo.shade600]),
    TrainingTypeConfig(
        'survey', Icons.quiz, [Colors.teal.shade400, Colors.teal.shade600]),
    TrainingTypeConfig(
        'mixed', Icons.shuffle, [Colors.amber.shade400, Colors.amber.shade600]),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    notesController.dispose();
    pitchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  // Computed Properties
  bool get isTrainingActive {
    if (trainingStart == null || trainingEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(trainingStart!) && now.isBefore(trainingEnd!);
  }

  bool get canStartTraining => selectedTeam != null && trainingType != null;

  // UI Actions
  void _startTraining() {
    if (!canStartTraining) return;

    HapticFeedback.mediumImpact();
    setState(() {
      trainingStart = DateTime.now();
      trainingEnd = trainingStart!.add(const Duration(hours: 2));
      hasEditedSession = false;
      currentSessionId = null;
    });
  }

  void _logout() async {
    HapticFeedback.lightImpact();
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _saveTrainingSession(List<QueryDocumentSnapshot> players,
      {bool isEdit = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!isTrainingActive && !isEdit) return;

    try {
      // Get coach name
      String coachName = "Unknown Coach";
      if (coachUid != null) {
        final coachDoc =
            await _firestore.collection('users').doc(coachUid).get();
        if (coachDoc.exists) {
          coachName = coachDoc.data()?['name'] ?? "Unknown Coach";
        }
      }

      final sessionData = {
        "coach_uid": coachUid,
        "coach_name": coachName,
        "team": selectedTeam!.teamName,
        "training_type": trainingType,
        "pitch_location": pitchController.text.isNotEmpty
            ? pitchController.text
            : "Not specified",
        "start_time": Timestamp.fromDate(trainingStart!),
        "end_time": Timestamp.fromDate(trainingEnd!),
        "note": notesController.text,
        "created_at": Timestamp.now(),
        "players": players.map((player) {
          final playerId = player.id;
          final wasPresent = attendance[playerId] ?? false;
          return {
            "player_id": playerId,
            "name": player['name'],
            "present": wasPresent,
            "minutes": wasPresent ? 120 : 0,
            "notes": notes[playerId] ?? '',
          };
        }).toList(),
      };

      if (isEdit && currentSessionId != null) {
        await _firestore
            .collection("training_sessions")
            .doc(currentSessionId)
            .update(sessionData);
        _resetSession();
        _showSuccessMessage(l10n.successfullyUpdated);
      } else {
        final docRef =
            await _firestore.collection("training_sessions").add(sessionData);
        setState(() => currentSessionId = docRef.id);
        _showSuccessMessage(
            "Training session saved! You can edit it once more.");
      }
    } catch (e) {
      _showErrorMessage(l10n.failedToUpdate(e.toString()));
    }
  }

  void _resetSession() {
    setState(() {
      hasEditedSession = true;
      trainingStart = null;
      trainingEnd = null;
      currentSessionId = null;
      attendance.clear();
      notes.clear();
      selectedTeam = null;
      trainingType = null;
      pitchController.clear();
      notesController.clear();
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n, isSmallScreen),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                children: [
                  _buildTeamSelection(l10n, isSmallScreen),
                  const SizedBox(height: 16),
                  _buildTrainingTypeSelection(l10n, size),
                  const SizedBox(height: 16),
                  _buildPitchLocationCard(l10n, isSmallScreen),
                  const SizedBox(height: 16),
                  if (!isTrainingActive)
                    _buildStartTrainingButton(l10n, isSmallScreen),
                  if (isTrainingActive)
                    _buildTrainingActiveCard(l10n, isSmallScreen),
                  const SizedBox(height: 16),
                  if (selectedTeam != null)
                    _buildPlayersSection(l10n, isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, bool isSmallScreen) {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF27121), Color(0xFFE94057)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Text(
        l10n.coachScreen,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isSmallScreen ? 18 : 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildTeamSelection(AppLocalizations l10n, bool isSmallScreen) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(l10n.selectTeam, Icons.group, isSmallScreen),
          const SizedBox(height: 12),
          // 🔍 DEBUG: Temporary debug button to investigate team assignment
          if (coachUid != null) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final teams =
                    await _teamService.getTeamsForCoachDebug(coachUid!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Debug: Found ${teams.length} teams. Check console for details.'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Teams'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],
          StreamBuilder<List<Team>>(
            stream: coachUid != null
                ? _teamService.getTeamsForCoach(coachUid!)
                : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _buildErrorWidget(
                    'Error loading teams: ${snapshot.error}');
              }

              final teams = snapshot.data ?? [];

              if (teams.isEmpty) {
                return _buildEmptyState(
                    'No teams assigned', Icons.sports_soccer);
              }

              return DropdownButtonFormField<Team>(
                decoration: InputDecoration(
                  labelText: l10n.team,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.sports_soccer),
                ),
                value: selectedTeam,
                items: teams.map((team) {
                  return DropdownMenuItem<Team>(
                    value: team,
                    child: Text(team.teamName, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: isTrainingActive
                    ? null
                    : (team) {
                        setState(() {
                          selectedTeam = team;
                          attendance.clear();
                          notes.clear();
                        });
                      },
                isExpanded: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingTypeSelection(AppLocalizations l10n, Size size) {
    final isSmallScreen = size.width < 400;
    final crossAxisCount = size.width > 600 ? 4 : 4;
    final itemHeight = isSmallScreen ? 80.0 : 90.0;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              l10n.trainingType, Icons.fitness_center, isSmallScreen),
          const SizedBox(height: 12),
          SizedBox(
            height: (itemHeight * 2) + 8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    (size.width / crossAxisCount - 16) / itemHeight,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: trainingTypes.length,
              itemBuilder: (context, index) {
                final type = trainingTypes[index];
                final isSelected = trainingType == type.value;

                return GestureDetector(
                  onTap: isTrainingActive
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          setState(() => trainingType = type.value);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: type.gradient)
                          : LinearGradient(colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade300
                            ]),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: type.gradient[0], width: 2)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: type.gradient[0].withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          size: isSmallScreen ? 18 : 20,
                          color:
                              isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type.value,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchLocationCard(AppLocalizations l10n, bool isSmallScreen) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              l10n.pitchLocation, Icons.location_on, isSmallScreen),
          const SizedBox(height: 12),
          TextFormField(
            controller: pitchController,
            enabled: !isTrainingActive || currentSessionId != null,
            decoration: InputDecoration(
              labelText: l10n.pitchLocation,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.stadium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartTrainingButton(AppLocalizations l10n, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : 56,
      child: ElevatedButton.icon(
        onPressed: canStartTraining ? _startTraining : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF27121),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
        label: Text(
          l10n.startTraining,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingActiveCard(AppLocalizations l10n, bool isSmallScreen) {
    return _buildCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Training Active",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "Ends at ${DateFormat('HH:mm').format(trainingEnd!)}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${DateTime.now().difference(trainingStart!).inMinutes} min",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersSection(AppLocalizations l10n, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('players')
          .where('team', isEqualTo: selectedTeam!.teamName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading players');
        }

        final players = snapshot.data?.docs ?? [];

        if (players.isEmpty) {
          return _buildEmptyState(
              'No players found in this team', Icons.people_outline);
        }

        // Initialize attendance for all players
        for (var player in players) {
          attendance[player.id] ??= false;
          notes[player.id] ??= '';
        }

        return _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("${l10n.players}: ${players.length}",
                  Icons.people, isSmallScreen),
              const SizedBox(height: 16),
              ...players
                  .map((player) => _buildPlayerCard(player, isSmallScreen))
                  .toList(),
              if (isTrainingActive) ...[
                const SizedBox(height: 20),
                _buildSaveSessionButton(players, isSmallScreen),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerCard(QueryDocumentSnapshot player, bool isSmallScreen) {
    final playerId = player.id;
    final playerName = player['name'];
    final isPresent = attendance[playerId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: ListTile(
        dense: isSmallScreen,
        leading: CircleAvatar(
          radius: isSmallScreen ? 16 : 20,
          backgroundColor: isPresent ? Colors.green : Colors.red.shade300,
          child: Text(
            playerName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        title: Text(
          playerName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 14 : 16,
          ),
        ),
        subtitle: TextField(
          decoration: const InputDecoration(
            labelText: "Notes (optional)",
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (value) => notes[playerId] = value,
          enabled: isTrainingActive,
          style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
        ),
        trailing: isTrainingActive
            ? Switch(
                value: isPresent,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  setState(() => attendance[playerId] = val);
                },
                activeColor: Colors.green,
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Closed",
                  style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                ),
              ),
      ),
    );
  }

  Widget _buildSaveSessionButton(
      List<QueryDocumentSnapshot> players, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: ElevatedButton.icon(
        onPressed: () =>
            _saveTrainingSession(players, isEdit: currentSessionId != null),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              currentSessionId != null ? Colors.orange : Colors.blue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(
          currentSessionId != null ? Icons.edit : Icons.save,
          size: isSmallScreen ? 18 : 20,
          color: Colors.white,
        ),
        label: Text(
          currentSessionId != null ? "Update & Close Session" : "Save Session",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper Widgets
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

  Widget _buildErrorWidget(String message) {
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
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper Classes
class TrainingTypeConfig {
  final String value;
  final IconData icon;
  final List<Color> gradient;

  TrainingTypeConfig(this.value, this.icon, this.gradient);
}
