import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/main.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

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
  final ScrollController _scrollController = ScrollController();

  // Player Data
  Map<String, bool> attendance = {};
  Map<String, String> notes = {};

  // Profile Data
  String? userProfileImageUrl;
  String? userDisplayName;

  // Training Types Configuration
  List<TrainingTypeConfig> _getTrainingTypes(AppLocalizations l10n) => [
    TrainingTypeConfig(l10n.trainingTypeGame, Icons.sports_soccer,
        [Colors.red.shade400, Colors.red.shade600]),
    TrainingTypeConfig(
        l10n.trainingTypeTraining, Icons.sports, [Colors.blue.shade400, Colors.blue.shade600]),
    TrainingTypeConfig(l10n.trainingTypeTactical, Icons.analytics,
        [Colors.purple.shade400, Colors.purple.shade600]),
    TrainingTypeConfig(l10n.trainingTypeFitness, Icons.fitness_center,
        [Colors.orange.shade400, Colors.orange.shade600]),
    TrainingTypeConfig(l10n.trainingTypeTechnical, Icons.precision_manufacturing,
        [Colors.green.shade400, Colors.green.shade600]),
    TrainingTypeConfig(l10n.trainingTypeTheoretical, Icons.school,
        [Colors.indigo.shade400, Colors.indigo.shade600]),
    TrainingTypeConfig(
        l10n.trainingTypeSurvey, Icons.quiz, [Colors.teal.shade400, Colors.teal.shade600]),
    TrainingTypeConfig(
        l10n.trainingTypeMixed, Icons.shuffle, [Colors.amber.shade400, Colors.amber.shade600]),
  ];
  
  // Getter for training types
  List<TrainingTypeConfig> get trainingTypes => _getTrainingTypes(AppLocalizations.of(context)!);

  // In the initState method:
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    notesController.dispose();
    pitchController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
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

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null && OrganizationContext.isInitialized) {
        // Load from Firestore user profile
        final organizationId = OrganizationContext.currentOrgId;

        final userDoc = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final userData = userDoc.data()!;

          // Debug: Print all available fields
          // print('🔍 DEBUG: User document fields: ${userData.keys.toList()}');
          // print('🔍 DEBUG: Picture field: ${userData['picture']}');
          // print(
          //     '🔍 DEBUG: ProfileImageUrl field: ${userData['profileImageUrl']}');

          // Check for various possible field names for the profile image
          String? imageUrl;

          // Try different field names that might contain the Cloudinary URL
          final possibleFields = [
            'picture',
            'profileImageUrl',
            'profile_image_url',
            'avatar',
            'photo',
            'image',
            'photoURL',
            'imageUrl'
          ];

          for (String field in possibleFields) {
            final value = userData[field];
            if (value != null && value.toString().isNotEmpty) {
              // Check if it's a valid URL (not a local file path)
              if (value.toString().startsWith('http')) {
                imageUrl = value.toString();
                //print('✅ Found valid image URL in field "$field": $imageUrl');
                break;
              } else {
                print('⚠️ Found non-URL value in field "$field": $value');
              }
            }
          }

          setState(() {
            userProfileImageUrl = imageUrl;
            userDisplayName = userData['name'] ?? user.displayName;
          });

          print('🎯 Final userProfileImageUrl: $userProfileImageUrl');
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
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
      String coachName = "Ismeretlen edző";
      if (coachUid != null) {
        final coachDoc = await _firestore
            .collection('organizations')
            .doc(OrganizationContext.currentOrgId)
            .collection('users')
            .doc(coachUid)
            .get();
        if (coachDoc.exists) {
          coachName = coachDoc.data()?['name'] ?? "Ismeretlen edző";
        }
      }

      final sessionData = {
        "coach_uid": coachUid,
        "coach_name": coachName,
        "team": selectedTeam!.teamName,
        "training_type": trainingType,
        "pitch_location": pitchController.text.isNotEmpty
            ? pitchController.text
            : "Nincs megadva",
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
        _showSuccessMessage("Edzés elmentve! Még egyszer szerkesztheti.");
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
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  String _getLocalizedTrainingType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'game':
        return 'Mérkőzés';
      case 'training':
        return 'Edzés';
      case 'tactical':
        return 'Taktikai';
      case 'fitness':
        return 'Erőnléti';
      case 'technical':
        return 'Technikai';
      case 'theoretical':
        return 'Elméleti';
      case 'survey':
        return 'Felmérés';
      case 'mixed':
        return 'Vegyes';
      default:
        return type.toUpperCase();
    }
  }

  String _getTrainingTypeDescription(AppLocalizations l10n, String type) {
    switch (type) {
      case 'game':
        return 'Official or practice matches against other teams';
      case 'training':
        return 'General training with skill development and conditioning';
      case 'tactical':
        return 'Tactical formations, strategies, and team play practice';
      case 'fitness':
        return 'Conditioning workouts, strength training, and endurance building';
      case 'technical':
        return 'Individual technical skills: dribbling, shooting, passing';
      case 'theoretical':
        return 'Tactical discussions, game rules, and strategic planning';
      case 'survey':
        return 'Player assessments, testing, and skill evaluations';
      case 'mixed':
        return 'Combined training with elements from multiple types';
      default:
        return 'Training type: $type';
    }
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
      drawer: _buildDrawer(l10n, isSmallScreen),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade100,
                      Colors.grey.shade50,
                    ],
                    stops: const [0.0, 0.7], // Better gradient distribution
                  ),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              key: const PageStorageKey('coach_screen_scroll'),
              controller: _scrollController,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header welcome section
                  _buildWelcomeSection(l10n, isSmallScreen),
                  const SizedBox(height: 24),

                  // Team selection
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: _buildTeamSelection(l10n, isSmallScreen),
                  ),
                  const SizedBox(height: 16),

                  // Training type selection
                  if (selectedTeam != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: _buildTrainingTypeSelection(l10n, size),
                    ),

                  if (selectedTeam != null) const SizedBox(height: 16),

                  // Pitch location
                  if (selectedTeam != null && trainingType != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: _buildPitchLocationCard(l10n, isSmallScreen),
                    ),

                  if (selectedTeam != null && trainingType != null)
                    const SizedBox(height: 16),

                  // Start training button or active training card
                  if (!isTrainingActive &&
                      selectedTeam != null &&
                      trainingType != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: _buildStartTrainingButton(l10n, isSmallScreen),
                    ),

                  if (isTrainingActive)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: _buildTrainingActiveCard(l10n, isSmallScreen),
                    ),

                  if (selectedTeam != null) const SizedBox(height: 16),

                  // Players section
                  if (selectedTeam != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: PlayersSection(
                        key: ValueKey('players_${selectedTeam!.teamName}'),
                        selectedTeam: selectedTeam!,
                        initialAttendance: attendance,
                        initialNotes: notes,
                        isTrainingActive: isTrainingActive,
                        isSmallScreen: isSmallScreen,
                        onSaveSession:
                            (players, updatedAttendance, updatedNotes) {
                          // Update parent state with latest attendance data
                          attendance.addAll(updatedAttendance);
                          notes.addAll(updatedNotes);
                          _saveTrainingSession(players,
                              isEdit: currentSessionId != null);
                        },
                        currentSessionId: currentSessionId,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Hello, ",
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 26,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade700,
              ),
            ),
            Expanded(
              child: Text(
                userDisplayName ?? l10n.coach,
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isTrainingActive
              ? "Aktív edzés folyamatban"
              : "Üdvözöljük az edző felületen!",
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color:
                isTrainingActive ? Colors.green.shade600 : Colors.grey.shade600,
            fontWeight: isTrainingActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n, bool isSmallScreen) {
    // Use even smaller sizes for very small screens
    final verySmallScreen = MediaQuery.of(context).size.width < 350;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF27121).withOpacity(0.9),
              const Color(0xFFE94057).withOpacity(0.9),
              Colors.purple.shade400.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      titleSpacing: 0, // Remove title spacing
      title: Padding(
        padding: EdgeInsets.only(right: verySmallScreen ? 4.0 : 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            Container(
              padding: EdgeInsets.all(verySmallScreen ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(verySmallScreen ? 8 : 10),
              ),
              child: Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: verySmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: verySmallScreen ? 4 : 8),
            Flexible(
              child: Text(
                l10n.coachScreen,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: verySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Status indicator for active training
        if (isTrainingActive)
          Container(
            margin: EdgeInsets.symmetric(
                vertical: verySmallScreen ? 10 : 12,
                horizontal: verySmallScreen ? 2 : 4),
            padding: EdgeInsets.symmetric(
                horizontal: verySmallScreen ? 6 : 8,
                vertical: verySmallScreen ? 2 : 4),
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: BorderRadius.circular(verySmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: verySmallScreen ? 4 : 6,
                  height: verySmallScreen ? 4 : 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: verySmallScreen ? 2 : 4),
                Text(
                  "Live",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: verySmallScreen ? 8 : 10,
                  ),
                ),
              ],
            ),
          ),

        // User profile picture - only show on larger screens
        if (!isSmallScreen && !verySmallScreen)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: () {
                _showProfileSettings();
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Hero(
                  tag: 'profile_image',
                  child: _buildProfileAvatar(14),
                ),
              ),
            ),
          ),

        // Logout button - make it more compact
        IconButton(
          constraints: BoxConstraints(
            minWidth: verySmallScreen ? 32 : 36,
            minHeight: verySmallScreen ? 32 : 36,
          ),
          padding: EdgeInsets.zero,
          icon: Container(
            padding: EdgeInsets.all(verySmallScreen ? 3 : 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(verySmallScreen ? 4 : 6),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: verySmallScreen ? 14 : 16,
            ),
          ),
          onPressed: _logout,
          tooltip: l10n.logout,
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
          StreamBuilder<List<Team>>(
            stream: coachUid != null
                ? _teamService.getTeamsForCoach(coachUid!)
                : null,
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
                          'Hiba a csapatok betöltésekor: ${snapshot.error}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final teams = snapshot.data ?? [];

              if (teams.isEmpty) {
                return _buildEmptyState(
                    'Nincs hozzárendelt csapat', Icons.sports_soccer);
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
            height: (itemHeight * 2) + 16,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio:
                    (size.width / crossAxisCount - 20) / (itemHeight + 4),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: trainingTypes.length,
              itemBuilder: (context, index) {
                final type = trainingTypes[index];
                final isSelected = trainingType == type.value;

                return Tooltip(
                  message: _getTrainingTypeDescription(l10n, type.value),
                  preferBelow: true,
                  padding: const EdgeInsets.all(12),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: isTrainingActive
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            setState(() => trainingType = type.value);
                          },
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${_getLocalizedTrainingType(l10n, type.value)}: ${_getTrainingTypeDescription(l10n, type.value)}',
                          ),
                          duration: const Duration(seconds: 4),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
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
                            size: isSmallScreen ? 28 : 32,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getLocalizedTrainingType(l10n, type.value),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
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
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 60 : 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF27121).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: canStartTraining ? _startTraining : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFF27121),
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 22,
            vertical: isSmallScreen ? 10 : 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.startTraining,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!isSmallScreen)
                  Text(
                    selectedTeam?.teamName ?? "",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingActiveCard(AppLocalizations l10n, bool isSmallScreen) {
    final elapsedMinutes = DateTime.now().difference(trainingStart!).inMinutes;
    final totalMinutes = trainingEnd!.difference(trainingStart!).inMinutes;
    final progress = elapsedMinutes / totalMinutes;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edzés folyamatban",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Kezdés: ${DateFormat('HH:mm').format(trainingStart!)}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Vége: ${DateFormat('HH:mm').format(trainingEnd!)}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$elapsedMinutes perc eltelt",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 13 : 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
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

  // Use the OverflowUtils class for responsive sizing
  double responsiveSize(
    BuildContext context, {
    required double small,
    required double medium,
    required double large,
    double? extraSmall,
  }) {
    final width = MediaQuery.of(context).size.width;

    if (extraSmall != null && width < 320) {
      return extraSmall;
    } else if (width < 350) {
      return small;
    } else if (width < 400) {
      return medium;
    } else {
      return large;
    }
  }

  // Drawer Methods - Professional Design with Overflow Protection
  Widget _buildDrawer(AppLocalizations l10n, bool isSmallScreen) {
    // Additional check for extremely small screens can be done with the responsiveSize helper

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Header with flexible height
              Flexible(
                flex: 0,
                child: _buildDrawerHeader(l10n, isSmallScreen),
              ),
              // Content with scrollable body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          200, // Ensure content fills remaining space
                    ),
                    child: Column(
                      children: [
                        _buildDrawerSection(
                          title: l10n.account,
                          items: [
                            DrawerItemData(
                              icon: Icons.person_outline,
                              activeIcon: Icons.person,
                              title: l10n.profile,
                              subtitle: 'Profil kezelése',
                              onTap: () => _showProfileSettings(),
                              color: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: l10n.settings,
                          items: [
                            DrawerItemData(
                              icon: Icons.language_outlined,
                              activeIcon: Icons.language,
                              title: l10n.language,
                              subtitle: _getCurrentLanguageName(),
                              onTap: () => _showLanguageDialog(),
                              color: const Color(0xFF2196F3),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF2196F3).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getCurrentLanguageFlag(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            DrawerItemData(
                              icon: Icons.dark_mode_outlined,
                              activeIcon: Icons.dark_mode,
                              title: l10n.theme,
                              subtitle: l10n.lightMode,
                              onTap: () => _showThemeSettings(),
                              color: const Color(0xFF9C27B0),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: 'Contact',
                          items: [
                            DrawerItemData(
                              icon: Icons.phone_outlined,
                              activeIcon: Icons.phone,
                              title: 'Phone Support',
                              subtitle: '+36 30 5754 174',
                              onTap: () => _makePhoneCall('+36305754174'),
                              color: const Color(0xFF4CAF50),
                            ),
                            DrawerItemData(
                              icon: Icons.email_outlined,
                              activeIcon: Icons.email,
                              title: l10n.emailSupport,
                              subtitle: 'sa.bensarar@gmail.com',
                              onTap: () => _sendEmail('sa.bensarar@gmail.com'),
                              color: const Color(0xFF2196F3),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: 'Support',
                          items: [
                            DrawerItemData(
                              icon: Icons.help_outline,
                              activeIcon: Icons.help,
                              title: l10n.help,
                              subtitle: 'Segítség és támogatás',
                              onTap: () => _showHelp(),
                              color: const Color(0xFF607D8B),
                            ),
                            DrawerItemData(
                              icon: Icons.info_outline,
                              activeIcon: Icons.info,
                              title: l10n.about,
                              subtitle: 'Alkalmazás információ',
                              onTap: () => _showAbout(),
                              color: const Color(0xFF795548),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildLogoutButton(l10n),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Professional Drawer Header with Responsive Design and Overflow Protection
  Widget _buildDrawerHeader(AppLocalizations l10n, bool isSmallScreen) {
    final user = _auth.currentUser;
    // Make avatar even smaller on very small screens
    final avatarRadius = isSmallScreen ? 28.0 : 34.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF27121),
            Color(0xFFE94057),
            Color(0xFFFF6B6B),
            Color(0xFFFF8A65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          // Reduce padding on small screens
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prevent row overflow
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced Avatar with CachedNetworkImage
                Hero(
                  tag: 'coach_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildProfileAvatar(avatarRadius),
                  ),
                ),
                const SizedBox(width: 12), // Reduce spacing
                // User Info with Flexible Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Prevent column overflow
                    children: [
                      // Name with overflow protection
                      Flexible(
                        child: Text(
                          userDisplayName ??
                              user?.displayName ??
                              user?.email?.split('@').first ??
                              'Edző',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                isSmallScreen ? 13 : 15, // Smaller text size
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 3), // Reduce spacing
                        // Email with overflow protection
                        Flexible(
                          child: Text(
                            user!.email!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize:
                                  isSmallScreen ? 10 : 11, // Smaller text size
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6), // Reduce spacing
                      // Role Badge - make it smaller
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 3 : 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius:
                              BorderRadius.circular(12), // Smaller radius
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Edző',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                isSmallScreen ? 9 : 10, // Smaller text size
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Profile Avatar with CachedNetworkImage
  Widget _buildProfileAvatar(double radius) {
    if (userProfileImageUrl != null && userProfileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: userProfileImageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: SizedBox(
            width: radius * 0.6,
            height: radius * 0.6,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(
            Icons.person,
            size: radius * 0.8,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: Icon(
          Icons.person,
          size: radius * 0.8,
          color: Colors.white,
        ),
      );
    }
  }

  // Contact Methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    Navigator.of(context).pop();
    final message = 'Call: $phoneNumber\nTap phone number to copy and dial';
    _showSuccessMessage(message);
  }

  Future<void> _sendEmail(String email) async {
    Navigator.of(context).pop();
    final message = 'Email: $email\nTap email to copy and send';
    _showSuccessMessage(message);
  }

  // Professional Drawer Section Builder
  Widget _buildDrawerSection({
    required String title,
    required List<DrawerItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildProfessionalDrawerItem(item)),
        const SizedBox(height: 8),
      ],
    );
  }

  // Enhanced Drawer Item with Modern Design
  Widget _buildProfessionalDrawerItem(DrawerItemData item) {
    // Get screen size here
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 8, vertical: isSmallScreen ? 1 : 2),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            item.onTap();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prevent row overflow
              children: [
                // Icon with background circle - make it more compact
                Container(
                  width: isSmallScreen ? 36 : 40,
                  height: isSmallScreen ? 36 : 40,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8), // Smaller radius
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: isSmallScreen ? 18 : 20, // Smaller on small screens
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16), // Adaptive spacing
                // Title and subtitle with overflow protection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Prevent column overflow
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: isSmallScreen
                              ? 12
                              : 14, // Smaller on small screens
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: isSmallScreen
                              ? 10
                              : 12, // Smaller on small screens
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Trailing widget or arrow - make it smaller
                if (item.trailing != null)
                  item.trailing!
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Professional Logout Button
  Widget _buildLogoutButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.shade50,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.mediumImpact();
            _showLogoutDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.logout,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Kijelentkezés a fiókból',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods for Enhanced Drawer
  String _getCurrentLanguageFlag() {
    final locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'en':
        return '🇺🇸';
      case 'hu':
        return '🇭🇺';
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      default:
        return '🇺🇸';
    }
  }

  void _showThemeSettings() {
    Navigator.of(context).pop();
    _showComingSoonDialog('Téma beállítások',
        'Sötét mód és téma testreszabási lehetőségek hamarosan elérhetők lesznek.');
  }

  void _showComingSoonDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: const Color(0xFFF27121)),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.close,
                style: const TextStyle(color: Color(0xFFF27121)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.logout),
            ],
          ),
          content: const Text('Biztosan ki szeretne jelentkezni a fiókjából?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close drawer
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.logout),
            ),
          ],
        );
      },
    );
  }

  // Settings Methods
  String _getCurrentLanguageName() {
    final locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hu':
        return 'Magyar';
      default:
        return 'English';
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.selectLanguage),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('en', 'English', '🇺🇸'),
              _buildLanguageOption('hu', 'Magyar', '🇭🇺'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF27121),
              ),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(
      String languageCode, String languageName, String flag) {
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == languageCode;

    return Material(
      color: isSelected ? const Color(0xFFF27121).withOpacity(0.1) : null,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(languageName,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFFF27121))
            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () {
          Navigator.of(context).pop();
          _changeLanguage(languageCode);
        },
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    final newLocale = Locale(languageCode);
    MyApp.setLocale(context, newLocale);

    // Use a delay to allow the locale to update before accessing the new translations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessMessage(
            '${l10n.languageChanged} ${_getLanguageName(languageCode)}');
      }
    });
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'hu':
        return 'Magyar';
      default:
        return 'English';
    }
  }

  void _showProfileSettings() async {
    Navigator.of(context).pop();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProfileSettingsDialog();
      },
    );

    // If profile was updated, refresh the display
    if (result == true) {
      _loadUserProfile();
    }
  }

  void _showHelp() {
    Navigator.of(context).pop();
    _showSuccessMessage('Súgó és támogatás hamarosan');
  }

  void _showAbout() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.about),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Futballedzés alkalmazás'),
              SizedBox(height: 8),
              Text('Verzió: 1.0.0'),
              SizedBox(height: 8),
              Text('Átfogó futballedzés kezelő rendszer.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}

// Profile Settings Dialog
class ProfileSettingsDialog extends StatefulWidget {
  const ProfileSettingsDialog({super.key});

  @override
  ProfileSettingsDialogState createState() => ProfileSettingsDialogState();
}

class ProfileSettingsDialogState extends State<ProfileSettingsDialog> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _isUpdatingAuth = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null && OrganizationContext.isInitialized) {
        final organizationId = OrganizationContext.currentOrgId;

        final userDoc = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final data = userDoc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _uploadedImageUrl = data['picture'] ?? data['profileImageUrl'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _nameController.text = user.displayName ?? '';
            _emailController.text = user.email ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      String cloudName = "dycj9nypi";
      String uploadPreset = "unsigned_preset";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
      );

      request.fields['upload_preset'] = uploadPreset;
      request.fields['quality'] = 'auto:eco';
      request.fields['fetch_format'] = 'auto';

      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your connection.');
        },
      );

      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        if (mounted) {
          final cloudinaryUrl = jsonData['secure_url'];
          print('🌤️ Cloudinary upload successful: $cloudinaryUrl');
          setState(() {
            _uploadedImageUrl = cloudinaryUrl;
            _isUploading = false;
          });
          _showSuccessSnackBar('Image uploaded successfully!');
        }
      } else {
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        print('📄 Response data: $responseData');
        throw Exception(jsonData['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showErrorSnackBar('Failed to upload image: $e');
      }
    }
  }

  // Authentication Methods
  Future<bool> _reauthenticateUser(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user?.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      _showErrorSnackBar('Current password is incorrect');
      return false;
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateEmail(newEmail);
      _showSuccessSnackBar('Email updated successfully!');
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
      _showSuccessSnackBar('Password updated successfully!');
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _arePasswordFieldsValid() {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showErrorSnackBar('New password must be at least 6 characters');
      return false;
    }

    if (newPassword != confirmPassword) {
      _showErrorSnackBar('Passwords do not match');
      return false;
    }

    return true;
  }

  bool _validateInputs() {
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('Name cannot be empty');
      return false;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email cannot be empty');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    // Validate password fields if changing password
    if (_showPasswordFields) {
      if (_currentPasswordController.text.isEmpty) {
        _showErrorSnackBar('Current password is required');
        return false;
      }

      if (_newPasswordController.text.isEmpty) {
        _showErrorSnackBar('New password is required');
        return false;
      }

      if (!_arePasswordFieldsValid()) {
        return false;
      }
    }

    return true;
  }

  Future<void> _saveProfile() async {
    try {
      setState(() => _isUpdatingAuth = true);

      final user = _auth.currentUser;
      if (user == null || !OrganizationContext.isInitialized) {
        throw Exception(
            'User not authenticated or organization not initialized');
      }

      // Validate inputs before processing
      if (!_validateInputs()) {
        setState(() => _isUpdatingAuth = false);
        return;
      }

      final organizationId = OrganizationContext.currentOrgId;
      bool needsReauth = false;

      // Check if email or password changes require reauthentication
      final emailChanged = _emailController.text.trim() != user.email;
      final passwordChanged = _showPasswordFields &&
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty;

      needsReauth = emailChanged || passwordChanged;

      // Reauthenticate if needed
      if (needsReauth && _currentPasswordController.text.isNotEmpty) {
        final success =
            await _reauthenticateUser(_currentPasswordController.text.trim());
        if (!success) {
          setState(() => _isUpdatingAuth = false);
          return;
        }
      } else if (needsReauth) {
        _showErrorSnackBar(
            'Current password is required for email or password changes');
        setState(() => _isUpdatingAuth = false);
        return;
      }

      // Update email if changed
      if (emailChanged) {
        await _updateEmail(_emailController.text.trim());
      }

      // Update password if changed
      if (passwordChanged) {
        await _updatePassword(_newPasswordController.text.trim());
      }

      // Update Firestore document
      final updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_uploadedImageUrl != null) {
        // Save to both fields for compatibility
        updateData['profileImageUrl'] = _uploadedImageUrl!;
        updateData['picture'] = _uploadedImageUrl!;
      }

      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      // Update Firebase Auth display name
      if (_nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.of(context).pop(true); // Return true to indicate update
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAuth = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? size.width * 0.95 : 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.profile,
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF27121),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Profile Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border:
                        Border.all(color: const Color(0xFFF27121), width: 3),
                  ),
                  child: _imageFile != null
                      ? ClipOval(
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _uploadedImageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                _uploadedImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Koppintson a fénykép megváltoztatásához',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Upload Button (if image selected)
              if (_imageFile != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadToCloudinary,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                        _isUploading ? 'Feltöltés...' : 'Fénykép feltöltése'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27121),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Név',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Change Password Section
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jelszó megváltoztatása',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showPasswordFields,
                    onChanged: (value) {
                      setState(() {
                        _showPasswordFields = value;
                        if (!value) {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                    activeColor: const Color(0xFFF27121),
                  ),
                ],
              ),

              if (_showPasswordFields) ...[
                const SizedBox(height: 16),

                // Current Password Field
                TextField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Jelenlegi jelszó',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Password Field
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Új jelszó',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Új jelszó megerősítése',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUpdatingAuth ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF27121),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isUpdatingAuth
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Mentés'),
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
}

// Helper Classes
class DrawerItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;

  const DrawerItemData({
    required this.icon,
    this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.trailing,
  });
}

class TrainingTypeConfig {
  final String value;
  final IconData icon;
  final List<Color> gradient;

  TrainingTypeConfig(this.value, this.icon, this.gradient);
}

// Separate widget for players section to prevent unnecessary rebuilds
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
    // Save scroll position before setState
    final scrollController =
        context.findAncestorStateOfType<_CoachScreenState>()?._scrollController;
    final scrollOffset =
        scrollController?.hasClients == true ? scrollController!.offset : 0.0;

    setState(() {
      _attendance[playerId] = isPresent;
    });

    // Restore scroll position after setState
    if (scrollController?.hasClients == true && scrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController!.hasClients) {
          scrollController.jumpTo(scrollOffset);
        }
      });
    }

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
