import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:footballtraining/core/painters/pitch_painter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/coach_app_bar_extracted.dart';
import 'widgets/coach_drawer_extracted.dart';
import 'widgets/welcome_section_extracted.dart';
import 'widgets/team_selection_extracted.dart';
// Extracted dialogs
import 'dialogs/profile_settings_dialog.dart';
import 'dialogs/language_selection_dialog.dart';
import 'dialogs/coming_soon_dialog.dart';
// Extracted components
import 'components/players_section_widget.dart';
import 'components/training_type_selector_widget.dart';

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
  Timer? _countdownTimer;
  DateTime _now = DateTime.now();
  bool _autoSaveTriggered = false;
  List<QueryDocumentSnapshot> _cachedPlayers = [];

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

  // In the initState method:
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
    return _now.isAfter(trainingStart!) && _now.isBefore(trainingEnd!);
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
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _autoSaveTriggered = false;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      if (trainingEnd != null &&
          _now.isAfter(trainingEnd!) &&
          !_autoSaveTriggered) {
        _autoSaveTriggered = true;
        _saveTrainingSession(
          _cachedPlayers,
          isEdit: currentSessionId != null,
          isAutoSave: true,
        );
      }
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
      {bool isEdit = false, bool isAutoSave = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!isTrainingActive && !isEdit && !isAutoSave) return;

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

      // Validate organization context before saving
      if (!OrganizationContext.isInitialized) {
        _showErrorMessage(
            "Organization context not initialized. Please restart the app.");
        return;
      }

      final organizationId = OrganizationContext.currentOrgId;

      if (isEdit && currentSessionId != null) {
        await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('training_sessions')
            .doc(currentSessionId)
            .update(sessionData);
        _resetSession();
        _showSuccessMessage(l10n.successfullyUpdated);
      } else {
        final docRef = await _firestore
            .collection('organizations')
            .doc(organizationId)
            .collection('training_sessions')
            .add(sessionData);
        setState(() => currentSessionId = docRef.id);
        _showSuccessMessage("Edzés elmentve! Még egyszer szerkesztheti.");
      }
    } catch (e) {
      _showErrorMessage(l10n.failedToUpdate(e.toString()));
    }
  }

  void _resetSession() {
    _countdownTimer?.cancel();
    _autoSaveTriggered = false;
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
            const Icon(Icons.check_circle_outline,
                color: AppTheme.background, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.background,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.background,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppTheme.background, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.background,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: CoachAppBarExtracted(
        isSmallScreen: isSmallScreen,
        isTrainingActive: isTrainingActive,
        userProfileImageUrl: userProfileImageUrl,
        onProfilePressed: _showProfileSettings,
        onLogoutPressed: _logout,
        buildProfileAvatar: _buildProfileAvatar,
      ),
      drawer: CoachDrawerExtracted(
        userDisplayName: userDisplayName,
        userProfileImageUrl: userProfileImageUrl,
        showProfileSettings: _showProfileSettings,
        showLanguageDialog: _showLanguageDialog,
        showThemeSettings: _showThemeSettings,
        makePhoneCall: _makePhoneCall,
        sendEmail: _sendEmail,
        showHelpDialog: _showMatchPage,
        logoutUser: _logout,
        getCurrentLanguageName: _getCurrentLanguageName,
        getCurrentLanguageFlag: _getCurrentLanguageFlag,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // Background with pitch pattern
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
              ),
            ),

            // Pitch pattern overlay
            CustomPaint(
              painter: PitchLinePainter(
                lineColor: AppTheme.primary.withValues(alpha: 0.02),
              ),
              size: Size.infinite,
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
                  WelcomeSectionExtracted(
                    userDisplayName: userDisplayName,
                    isSmallScreen: isSmallScreen,
                    isTrainingActive: isTrainingActive,
                  ),
                  SizedBox(height: ScreenConfig.spaceL),

                  // Team selection
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: TeamSelectionExtracted(
                      coachUid: coachUid,
                      selectedTeam: selectedTeam,
                      isTrainingActive: isTrainingActive,
                      isSmallScreen: isSmallScreen,
                      onTeamChanged: (team) {
                        setState(() {
                          selectedTeam = team;
                          attendance.clear();
                          notes.clear();
                        });
                      },
                      teamService: _teamService,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Training type selection
                  if (selectedTeam != null)
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: TrainingTypeSelectorWidget(
                        selectedTrainingType: trainingType,
                        onTrainingTypeSelected: (type) {
                          setState(() => trainingType = type);
                        },
                        isTrainingActive: isTrainingActive,
                        isSmallScreen: isSmallScreen,
                      ),
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
                        onPlayersChanged: (players) {
                          setState(() => _cachedPlayers = players);
                        },
                        onSaveSession:
                            (players, updatedAttendance, updatedNotes) {
                          // Update parent state with latest attendance data
                          attendance.addAll(updatedAttendance);
                          notes.addAll(updatedNotes);
                          _cachedPlayers = players;
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

  Widget _buildPitchLocationCard(AppLocalizations l10n, bool isSmallScreen) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
              l10n.pitchLocation, Icons.location_on, isSmallScreen),
          const SizedBox(height: 12),
          PremiumTextField(
            controller: pitchController,
            enabled: !isTrainingActive || currentSessionId != null,
            labelText: l10n.pitchLocation,
            hintText: 'Enter pitch location',
            leadingIcon: Icons.stadium,
          ),
        ],
      ),
    );
  }

  Widget _buildStartTrainingButton(AppLocalizations l10n, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 60 : 70,
      child: GradientButton(
        label: l10n.startTraining,
        onPressed: canStartTraining ? _startTraining : null,
        icon: Icons.play_arrow_rounded,
        expanded: true,
        subtitle: !isSmallScreen ? selectedTeam?.teamName : null,
      ),
    );
  }

  Widget _buildTrainingActiveCard(AppLocalizations l10n, bool isSmallScreen) {
    final remaining = trainingEnd!.difference(_now);
    final elapsed = _now.difference(trainingStart!);
    final progress = (elapsed.inSeconds / (120 * 60)).clamp(0.0, 1.0);
    final remainingMin = remaining.inMinutes.clamp(0, 120);
    final remainingSec = remaining.inSeconds.remainder(60).clamp(0, 59);
    final Color progressColor = remainingMin < 5
        ? AppTheme.error
        : remainingMin < 15
            ? AppTheme.warning
            : AppTheme.background;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.3),
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
                  color: AppTheme.background.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer,
                  color: AppTheme.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Training in Progress",
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.background,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Start: ${DateFormat('HH:mm').format(trainingStart!)}",
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.background.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "End: ${DateFormat('HH:mm').format(trainingEnd!)}",
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.background.withValues(alpha: 0.9),
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
                "$remainingMin:${remainingSec.toString().padLeft(2, '0')} remaining",
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w700,
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
              backgroundColor: AppTheme.background.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: (isSmallScreen ? AppTheme.bodyLarge : AppTheme.heading3)
                .copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  // Enhanced Profile Avatar with CachedNetworkImage
  Widget _buildProfileAvatar(double radius) {
    if (userProfileImageUrl != null && userProfileImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: userProfileImageUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
          ),
        ),
        placeholder: (context, url) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background.withValues(alpha: 0.2),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.background),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background.withValues(alpha: 0.2),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.person,
            size: radius * 0.8,
            color: AppTheme.background,
          ),
        ),
      );
    } else {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.background.withValues(alpha: 0.2),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.person,
          size: radius * 0.8,
          color: AppTheme.background,
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
    ComingSoonDialog.show(context, title, message);
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
    LanguageSelectionDialog.show(context, _showSuccessMessage);
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

  void _showMatchPage() {
    Navigator.of(context).pop();
    _showSuccessMessage('Mérkőzés oldal hamarosan');
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
