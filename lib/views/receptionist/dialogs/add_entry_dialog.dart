import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class AddEntryDialog extends StatefulWidget {
  final String role; // "coach", "player", or "team"

  const AddEntryDialog({Key? key, required this.role}) : super(key: key);

  @override
  _AddEntryDialogState createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> selectedCoaches = [];
  final _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _submitController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Focus nodes for better UX
  final List<FocusNode> _focusNodes = [];
  
  // PRODUCTION-FIX: Stream subscriptions to prevent memory leaks
  StreamSubscription<QuerySnapshot>? _teamsSubscription;
  StreamSubscription<QuerySnapshot>? _coachesSubscription;
  List<QueryDocumentSnapshot> _teams = [];
  List<QueryDocumentSnapshot> _coaches = [];
  bool _teamsLoading = true;
  bool _coachesLoading = true;

  // Common fields
  String name = "";

  // Coach fields
  String email = "";
  String password = "";
  String roleDescription = "";
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  String? selectedTeamForCoach;

  // Player fields
  DateTime? birthDate;
  String position = "";
  String? selectedTeamForPlayer;

  // Team fields
  String teamName = "";
  String teamDescription = "";
  String? selectedCoachForTeam;

  // UI state
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  // Color schemes based on role
  Map<String, Map<String, dynamic>> get roleConfig => {
        'coach': {
          'gradient': [Color(0xFF667eea), Color(0xFF764ba2)],
          'icon': Icons.sports_rounded,
          'lightColor': Color(0xFF667eea).withOpacity(0.1),
        },
        'player': {
          'gradient': [Color(0xFF10B981), Color(0xFF059669)],
          'icon': Icons.person_rounded,
          'lightColor': Color(0xFF10B981).withOpacity(0.1),
        },
        'team': {
          'gradient': [Color(0xFFF59E0B), Color(0xFFD97706)],
          'icon': Icons.groups_rounded,
          'lightColor': Color(0xFFF59E0B).withOpacity(0.1),
        },
      };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupFocusNodes();
    _initializeStreams();
  }
  
  // PRODUCTION-FIX: Initialize streams once to prevent memory leaks
  void _initializeStreams() {
    // Teams stream
    _teamsSubscription = FirebaseFirestore.instance
        .collection('teams')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _teams = snapshot.docs;
          _teamsLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _teamsLoading = false);
      }
    });

    // Coaches stream
    _coachesSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _coaches = snapshot.docs;
          _coachesLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() => _coachesLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _submitController.dispose();
    _scrollController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    // PRODUCTION-FIX: Cancel stream subscriptions to prevent memory leaks
    _teamsSubscription?.cancel();
    _coachesSubscription?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _submitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  void _setupFocusNodes() {
    // Create focus nodes based on role
    int nodeCount = widget.role == 'coach'
        ? 4
        : widget.role == 'player'
            ? 3
            : 2;
    for (int i = 0; i < nodeCount; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  Color get primaryColor => roleConfig[widget.role]!['gradient'][0];
  Color get lightColor => roleConfig[widget.role]!['lightColor'];
  IconData get roleIcon => roleConfig[widget.role]!['icon'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? size.width * 0.9 : 500,
                maxHeight: size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(l10n),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: _buildBody(l10n, isSmallScreen),
                    ),
                  ),
                  _buildActions(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: roleConfig[widget.role]!['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              roleIcon,
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
                  l10n.addEntity(_getRoleDisplayName(widget.role, l10n)),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSubtitle(l10n),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: l10n.close,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            children: _buildFormFieldsForRole(l10n, isSmallScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AnimatedBuilder(
              animation: _submitController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: roleConfig[widget.role]!['gradient'],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _onAddPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            _getActionIcon(),
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isSubmitting ? l10n.adding : l10n.add,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

  List<Widget> _buildFormFieldsForRole(
      AppLocalizations l10n, bool isSmallScreen) {
    switch (widget.role) {
      case 'coach':
        return _buildCoachFields(l10n, isSmallScreen);
      case 'player':
        return _buildPlayerFields(l10n, isSmallScreen);
      case 'team':
        return _buildTeamFields(l10n, isSmallScreen);
      default:
        return [];
    }
  }

  List<Widget> _buildCoachFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Profile Image Section
      _buildImageSection(l10n),
      const SizedBox(height: 24),

      // Personal Information
      _buildSectionHeader(l10n.personalInformation, Icons.person_rounded),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.name,
        icon: Icons.person_outline_rounded,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.coachNameRequired;
          }
          if (value.trim().length < 2) {
            return l10n.nameMinLength;
          }
          return null;
        },
        onSaved: (value) => name = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.email,
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.emailRequired;
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return l10n.validEmailRequired;
          }
          return null;
        },
        onSaved: (value) => email = value!.trim(),
        focusNode: _focusNodes[1],
        nextFocusNode: _focusNodes[2],
      ),
      const SizedBox(height: 16),

      _buildPasswordField(l10n),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.roleDescription,
        icon: Icons.description_outlined,
        maxLines: 2,
        validator: (value) {
          if (value != null && value.length > 100) {
            return l10n.roleDescriptionMaxLength;
          }
          return null;
        },
        onSaved: (value) => roleDescription = value ?? "",
        focusNode: _focusNodes[3],
      ),
      const SizedBox(height: 24),

      // Multi-Team Assignment
      _buildSectionHeader(l10n.teamAssignment, Icons.groups_rounded),
      const SizedBox(height: 8),
      Text(
        l10n.selectTeamsToTrain,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 12 : 13,
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
      ),
      const SizedBox(height: 12),
      _buildMultiTeamSelector(l10n, isSmallScreen),
    ];
  }

  List<Map<String, dynamic>> selectedTeamsForCoach = [];

  Widget _buildMultiTeamSelector(AppLocalizations l10n, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Teams Header
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                size: isSmallScreen ? 16 : 18,
                color: Colors.blue.shade700,
              ),
              SizedBox(width: 8),
              Text(
                l10n.assignedTeams('${selectedTeamsForCoach.length}'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.blue.shade800,
                ),
              ),
              if (selectedTeamsForCoach.length >= 5) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.many,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Selected Teams List
          if (selectedTeamsForCoach.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isSmallScreen ? 120 : 140,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: selectedTeamsForCoach.length > 2
                    ? BouncingScrollPhysics()
                    : NeverScrollableScrollPhysics(),
                itemCount: selectedTeamsForCoach.length,
                separatorBuilder: (_, __) => SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final team = selectedTeamsForCoach[index];
                  return _buildSelectedTeamCard(team, isSmallScreen);
                },
              ),
            ),
          ],

          SizedBox(height: isSmallScreen ? 8 : 12),

          // PRODUCTION-FIX: Use cached data instead of StreamBuilder
          _teamsLoading
              ? _buildLoadingTeamButton(isSmallScreen, l10n)
              : Builder(
                  builder: (context) {
                    final availableTeams = _teams
                        .where((doc) => !selectedTeamsForCoach
                            .any((selected) => selected['id'] == doc.id))
                        .toList();

                    final bool canAddMore =
                        selectedTeamsForCoach.length < 10; // Max 10 teams
                    final bool hasAvailable = availableTeams.isNotEmpty;

                    return _buildAddTeamButton(
                      isEnabled: canAddMore && hasAvailable,
                      availableTeams: availableTeams,
                      isSmallScreen: isSmallScreen,
                      l10n: l10n,
                    );
                  },
                ),

          // Optional message
          if (selectedTeamsForCoach.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.blue.shade600,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.coachOptionalAssignment,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddTeamButton({
    required bool isEnabled,
    required List<QueryDocumentSnapshot> availableTeams,
    required bool isSmallScreen,
    required AppLocalizations l10n,
  }) {
    String buttonText;
    if (!isEnabled && selectedTeamsForCoach.length >= 10) {
      buttonText = l10n.maximumTeamsAssigned;
    } else if (!isEnabled && availableTeams.isEmpty) {
      buttonText = selectedTeamsForCoach.isEmpty
          ? l10n.noTeamsAvailable
          : l10n.allTeamsAssigned;
    } else {
      buttonText = l10n.addTeam;
    }

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: OutlinedButton.icon(
        onPressed: isEnabled
            ? () => _showTeamSelectionDialog(availableTeams, isSmallScreen, l10n)
            : null,
        icon: Icon(
          isEnabled ? Icons.add_circle_outline : Icons.info_outline,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          buttonText,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isEnabled ? Colors.blue.shade600 : Colors.grey.shade500,
          side: BorderSide(
              color: isEnabled ? Colors.blue.shade300 : Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
        ),
      ),
    );
  }

// PRODUCTION-READY: Loading state for team button
  Widget _buildLoadingTeamButton(bool isSmallScreen, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 16 : 20,
            height: isSmallScreen ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            l10n.loadingTeams,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 13 : 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

// PRODUCTION-READY: Team selection dialog
  void _showTeamSelectionDialog(
      List<QueryDocumentSnapshot> availableTeams, bool isSmallScreen, AppLocalizations l10n) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.6).clamp(300.0, 500.0);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        child: Container(
          width:
              MediaQuery.of(context).size.width * (isSmallScreen ? 0.9 : 0.8),
          height: dialogHeight,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                    topRight: Radius.circular(isSmallScreen ? 16 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: Colors.blue.shade600,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        l10n.selectTeamToAdd,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: isSmallScreen ? 20 : 24,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Teams List
              Expanded(
                child: availableTeams.isEmpty
                    ? _buildEmptyTeamsState(isSmallScreen, l10n)
                    : ListView.separated(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        physics: BouncingScrollPhysics(),
                        itemCount: availableTeams.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final team = availableTeams[index];
                          final teamData = team.data() as Map<String, dynamic>;
                          return _buildTeamSelectionItem(
                              team.id, teamData, isSmallScreen);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Empty teams state
  Widget _buildEmptyTeamsState(bool isSmallScreen, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_rounded,
            size: isSmallScreen ? 48 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            l10n.noTeamsAvailable,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            l10n.allTeamsAssigned,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

// Team selection item
  Widget _buildTeamSelectionItem(
      String teamId, Map<String, dynamic> teamData, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        onTap: () {
          Navigator.pop(context);
          _showTeamRoleSelectionDialog(
              teamId, teamData['team_name'], isSmallScreen, AppLocalizations.of(context)!);
        },
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: Colors.blue.shade700,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamData['team_name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (teamData['team_description'] != null &&
                        teamData['team_description'].isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        teamData['team_description'],
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blue.shade400,
                size: isSmallScreen ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Team role selection dialog
  void _showTeamRoleSelectionDialog(
      String teamId, String teamName, bool isSmallScreen, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        child: Container(
          width:
              MediaQuery.of(context).size.width * (isSmallScreen ? 0.9 : 0.8),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.blue.shade600,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectRole,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        Text(
                          l10n.forTeam(teamName),
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Role options
              ...TeamService.allCoachRoles.map((role) {
                final isLast = role == TeamService.allCoachRoles.last;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10),
                        onTap: () {
                          setState(() {
                            selectedTeamsForCoach.add({
                              'id': teamId,
                              'team_name': teamName,
                              'role': role,
                            });
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue.shade200),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 8 : 10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 6 : 8),
                                ),
                                child: Icon(
                                  Icons.sports_rounded,
                                  color: Colors.blue.shade700,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Text(
                                  TeamService.getCoachRoleDisplayName(role, AppLocalizations.of(context)!),
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade400,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) SizedBox(height: isSmallScreen ? 8 : 12),
                  ],
                );
              }).toList(),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Cancel button
              Container(
                width: double.infinity,
                height: isSmallScreen ? 44 : 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// PRODUCTION-READY: Updated coach creation method
  Future<void> _addCoach() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_uploadedImageUrl == null) {
      _showErrorSnackBar("Please upload an image for the coach.");
      return;
    }

    try {
      // Create coach in Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String coachUID = userCredential.user!.uid;

      // Prepare teams data for coach
      final List<Map<String, dynamic>> teamsData = selectedTeamsForCoach
          .map((team) => {
                'team_id': team['id'],
                'team_name': team['team_name'],
                'role': team['role'],
                'assigned_at': Timestamp.now(),
              })
          .toList();

      // Save coach details in users collection with multiple teams
      await FirebaseFirestore.instance.collection('users').doc(coachUID).set({
        "name": name,
        "email": email,
        "role": "coach",
        "role_description": roleDescription,
        "teams": teamsData, // Multiple teams
        "primary_team": selectedTeamsForCoach.isNotEmpty
            ? selectedTeamsForCoach.first['team_name']
            : null,
        "team_count": selectedTeamsForCoach.length,
        "picture": _uploadedImageUrl,
        "created_at": Timestamp.now(),
      });

      // Update each team to include this coach
      if (selectedTeamsForCoach.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (var teamAssignment in selectedTeamsForCoach) {
          final teamRef = FirebaseFirestore.instance
              .collection('teams')
              .doc(teamAssignment['id']);

          // Add coach to team's coaches array
          batch.update(teamRef, {
            'coaches': FieldValue.arrayUnion([
              {
                'coach_id': coachUID,
                'coach_name': name,
                'role': teamAssignment['role'],
                'assigned_at': Timestamp.now(),
              }
            ]),
            'coach_count': FieldValue.increment(1),
          });
        }

        await batch.commit();
      }

      final teamCount = selectedTeamsForCoach.length;
      final message = teamCount > 0
          ? 'Coach added successfully to $teamCount team(s)!'
          : 'Coach added successfully!';

      _showSuccessSnackBar(message);
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error adding coach: $e');
    }
  }

  Widget _buildSelectedTeamCard(Map<String, dynamic> team, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          // Team Icon
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: Colors.green.shade700,
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Team Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team['team_name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (team['role'] != null) ...[
                  SizedBox(height: 2),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      TeamService.getCoachRoleDisplayName(team['role'], AppLocalizations.of(context)),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Remove Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  selectedTeamsForCoach
                      .removeWhere((t) => t['id'] == team['id']);
                });
              },
              child: Container(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade400,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Personal Information
      _buildSectionHeader(l10n.playerInformation, Icons.sports_rounded),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.name,
        icon: Icons.person_outline_rounded,
        validator: (value) => value!.isEmpty ? l10n.enterPlayerName : null,
        onSaved: (value) => name = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      const SizedBox(height: 16),

      _buildDateField(l10n),
      const SizedBox(height: 16),

      _buildTextField(
        label: l10n.position,
        icon: Icons.sports_soccer_rounded,
        validator: (value) => value!.isEmpty ? l10n.enterPosition : null,
        onSaved: (value) => position = value!.trim(),
        focusNode: _focusNodes[1],
        nextFocusNode: _focusNodes[2],
      ),
      const SizedBox(height: 24),

      // Team Assignment
      _buildSectionHeader(l10n.teamAssignment, Icons.groups_rounded),
      const SizedBox(height: 16),
      _buildTeamDropdown(l10n, isCoach: false),
    ];
  }

  // PRODUCTION-READY: Enhanced team fields with better validation
  List<Widget> _buildTeamFields(AppLocalizations l10n, bool isSmallScreen) {
    return [
      // Team Information Section
      _buildSectionHeader(l10n.teamInformation, Icons.groups_rounded),
      SizedBox(height: isSmallScreen ? 12 : 16),

      // Team Name Field - REQUIRED with validation
      _buildTextField(
        label: l10n.teamName,
        icon: Icons.group_outlined,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.teamNameRequired;
          }
          if (value.trim().length < 2) {
            return l10n.teamNameMinLength;
          }
          if (value.trim().length > 30) {
            return l10n.teamNameMaxLength;
          }
          return null;
        },
        onSaved: (value) => teamName = value!.trim(),
        focusNode: _focusNodes[0],
        nextFocusNode: _focusNodes[1],
      ),
      SizedBox(height: isSmallScreen ? 12 : 16),

      // Team Description Field - REQUIRED with validation
      _buildTextField(
        label: l10n.teamDescription,
        icon: Icons.description_outlined,
        maxLines: isSmallScreen ? 2 : 3,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.teamDescriptionRequired;
          }
          if (value.trim().length < 10) {
            return l10n.descriptionMinLength;
          }
          if (value.trim().length > 200) {
            return l10n.descriptionMaxLength;
          }
          return null;
        },
        onSaved: (value) => teamDescription = value!.trim(),
        focusNode: _focusNodes[1],
      ),
      SizedBox(height: isSmallScreen ? 16 : 24),

      // Multi-Coach Assignment Section
      _buildSectionHeader(l10n.coachAssignment, Icons.sports_rounded),
      SizedBox(height: isSmallScreen ? 12 : 16),
      _buildOptimizedMultiCoachSelector(l10n, isSmallScreen),
    ];
  }

  // PRODUCTION-READY: Optimized multi-coach selector with better performance
  Widget _buildOptimizedMultiCoachSelector(
      AppLocalizations l10n, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Coaches Header with count and max indicator
          Row(
            children: [
              Icon(
                Icons.people_rounded,
                size: isSmallScreen ? 16 : 18,
                color: Colors.orange.shade700,
              ),
              SizedBox(width: 8),
              Text(
                l10n.assignedCoaches('${selectedCoaches.length}'),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.orange.shade800,
                ),
              ),
              if (selectedCoaches.length >= 3) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.max,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Selected Coaches List
          if (selectedCoaches.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 8 : 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isSmallScreen ? 140 : 160, // Fixed reasonable height
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: selectedCoaches.length > 2
                    ? BouncingScrollPhysics()
                    : NeverScrollableScrollPhysics(),
                itemCount: selectedCoaches.length,
                separatorBuilder: (_, __) => SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final coach = selectedCoaches[index];
                  return _buildSelectedCoachCard(coach, isSmallScreen);
                },
              ),
            ),
          ],

          SizedBox(height: isSmallScreen ? 8 : 12),

          // PRODUCTION-FIX: Use cached data instead of StreamBuilder
          _coachesLoading
              ? _buildLoadingButton(isSmallScreen, l10n)
              : Builder(
                  builder: (context) {
                    final availableCoaches = _coaches
                        .where((doc) => !selectedCoaches
                            .any((selected) => selected['id'] == doc.id))
                        .toList();

                    final bool canAddMore =
                        selectedCoaches.length < 3; // Max 3 coaches per team
                    final bool hasAvailable = availableCoaches.isNotEmpty;

                    return _buildAddCoachButton(
                      isEnabled: canAddMore && hasAvailable,
                      availableCoaches: availableCoaches,
                      isSmallScreen: isSmallScreen,
                      l10n: l10n,
                    );
                  },
                ),

          // Validation Warning
          if (selectedCoaches.isEmpty) _buildValidationWarning(isSmallScreen, l10n),
        ],
      ),
    );
  }

  // PRODUCTION-READY: Optimized selected coach card
  Widget _buildSelectedCoachCard(
      Map<String, dynamic> coach, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isSmallScreen ? 6 : 8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          // Coach Avatar
          CircleAvatar(
            radius: isSmallScreen ? 14 : 16,
            backgroundColor: Colors.green.shade100,
            child: Text(
              coach['name'].substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),

          // Coach Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    TeamService.getCoachRoleDisplayName(coach['role'], AppLocalizations.of(context)),
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Remove Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  selectedCoaches.removeWhere((c) => c['id'] == coach['id']);
                });
              },
              child: Container(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade400,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PRODUCTION-READY: Add coach button with proper state management
  Widget _buildAddCoachButton({
    required bool isEnabled,
    required List<QueryDocumentSnapshot> availableCoaches,
    required bool isSmallScreen,
    required AppLocalizations l10n,
  }) {
    String buttonText;
    if (!isEnabled && selectedCoaches.length >= 3) {
      buttonText = l10n.maximumCoachesAssigned;
    } else if (!isEnabled && availableCoaches.isEmpty) {
      buttonText = selectedCoaches.isEmpty
          ? l10n.noCoachesAvailable
          : l10n.allCoachesAssigned;
    } else {
      buttonText = l10n.addCoach;
    }

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      child: OutlinedButton.icon(
        onPressed: isEnabled
            ? () => _showCoachSelectionDialog(availableCoaches, isSmallScreen, l10n)
            : null,
        icon: Icon(
          isEnabled ? Icons.person_add : Icons.info_outline,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          buttonText,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 13 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              isEnabled ? Colors.blue.shade600 : Colors.grey.shade500,
          side: BorderSide(
              color: isEnabled ? Colors.blue.shade300 : Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
        ),
      ),
    );
  }

  // PRODUCTION-READY: Loading state for add button
  Widget _buildLoadingButton(bool isSmallScreen, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 44 : 48,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isSmallScreen ? 16 : 20,
            height: isSmallScreen ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            l10n.loadingCoaches,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 13 : 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // PRODUCTION-READY: Validation warning widget
  Widget _buildValidationWarning(bool isSmallScreen, AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            size: isSmallScreen ? 14 : 16,
            color: Colors.red.shade600,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              l10n.atLeastOneCoachRequired,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PRODUCTION-READY: Optimized coach selection dialog
  void _showCoachSelectionDialog(
      List<QueryDocumentSnapshot> availableCoaches, bool isSmallScreen, AppLocalizations l10n) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogHeight = (screenHeight * 0.6).clamp(300.0, 500.0);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        child: Container(
          width:
              MediaQuery.of(context).size.width * (isSmallScreen ? 0.9 : 0.8),
          height: dialogHeight,
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isSmallScreen ? 16 : 20),
                    topRight: Radius.circular(isSmallScreen ? 16 : 20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: Colors.blue.shade600,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      child: Text(
                        l10n.selectCoachToAdd,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.close_rounded,
                            size: isSmallScreen ? 20 : 24,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Coaches List
              Expanded(
                child: availableCoaches.isEmpty
                    ? _buildEmptyCoachesState(isSmallScreen, l10n)
                    : ListView.separated(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        physics: BouncingScrollPhysics(),
                        itemCount: availableCoaches.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final coach = availableCoaches[index];
                          final coachData =
                              coach.data() as Map<String, dynamic>;
                          return _buildCoachSelectionItem(
                              coach.id, coachData, isSmallScreen);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty coaches state
  Widget _buildEmptyCoachesState(bool isSmallScreen, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: isSmallScreen ? 48 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            l10n.noCoachesAvailable,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            l10n.allCoachesAssigned,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Responsive coach selection item
  Widget _buildCoachSelectionItem(
      String coachId, Map<String, dynamic> coachData, bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
        onTap: () {
          Navigator.pop(context);
          _showRoleSelectionDialog(coachId, coachData['name'], isSmallScreen, AppLocalizations.of(context)!);
        },
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade200),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: isSmallScreen ? 18 : 22,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  coachData['name'].substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coachData['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (coachData['email'] != null &&
                        coachData['email'].isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        coachData['email'],
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 11 : 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.blue.shade400,
                size: isSmallScreen ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive role selection dialog
  void _showRoleSelectionDialog(
      String coachId, String coachName, bool isSmallScreen, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        ),
        child: Container(
          width:
              MediaQuery.of(context).size.width * (isSmallScreen ? 0.9 : 0.8),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.orange.shade600,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectRole,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        Text(
                          l10n.forTeam(coachName),
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Role options
              ...TeamService.allCoachRoles.map((role) {
                final isLast = role == TeamService.allCoachRoles.last;
                return Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 8 : 10),
                        onTap: () {
                          setState(() {
                            selectedCoaches.add({
                              'id': coachId,
                              'name': coachName,
                              'role': role,
                            });
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 8 : 10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 6 : 8),
                                ),
                                child: Icon(
                                  Icons.sports_rounded,
                                  color: Colors.orange.shade700,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: Text(
                                  TeamService.getCoachRoleDisplayName(role, AppLocalizations.of(context)!),
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey.shade400,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!isLast) SizedBox(height: isSmallScreen ? 8 : 12),
                  ],
                );
              }).toList(),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Cancel button
              Container(
                width: double.infinity,
                height: isSmallScreen ? 44 : 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(isSmallScreen ? 8 : 10),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (focusNode?.hasFocus == true)
              ? primaryColor
              : Colors.grey.shade300,
          width: (focusNode?.hasFocus == true) ? 2 : 1,
        ),
        boxShadow: (focusNode?.hasFocus == true)
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: focusNode,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textInputAction:
            nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
        validator: validator,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: Icon(
            icon,
            color: (focusNode?.hasFocus == true)
                ? primaryColor
                : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (_focusNodes[2].hasFocus) ? primaryColor : Colors.grey.shade300,
          width: (_focusNodes[2].hasFocus) ? 2 : 1,
        ),
        boxShadow: (_focusNodes[2].hasFocus)
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: TextFormField(
        focusNode: _focusNodes[2],
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) =>
            FocusScope.of(context).requestFocus(_focusNodes[3]),
        validator: (value) =>
            value!.length < 6 ? l10n.passwordMinLengthSix : null,
        onSaved: (value) => password = value!,
        decoration: InputDecoration(
          labelText: l10n.password,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            color:
                (_focusNodes[2].hasFocus) ? primaryColor : Colors.grey.shade500,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: Colors.grey.shade500,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate:
                DateTime.now().subtract(const Duration(days: 365 * 10)),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            setState(() => birthDate = pickedDate);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  birthDate == null
                      ? l10n.selectBirthDate
                      : DateFormat('MMMM dd, yyyy').format(birthDate!),
                  style: GoogleFonts.poppins(
                    color: birthDate == null
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (birthDate != null)
                IconButton(
                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade500),
                  onPressed: () => setState(() => birthDate = null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamDropdown(AppLocalizations l10n, {required bool isCoach}) {
    // PRODUCTION-FIX: Use cached data instead of StreamBuilder
    if (_teamsLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading teams...',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    List<DropdownMenuItem<String>> teamItems =
        _teams.map<DropdownMenuItem<String>>((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final tName = data['team_name'] as String;
      return DropdownMenuItem<String>(
        value: tName,
        child: Text(
          tName,
          style: GoogleFonts.poppins(),
        ),
      );
    }).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: isCoach ? l10n.assignToTeam : l10n.selectTeam,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon:
              Icon(Icons.groups_outlined, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: teamItems,
        onChanged: (value) {
          if (isCoach) {
            selectedTeamForCoach = value;
          } else {
            selectedTeamForPlayer = value;
          }
        },
        dropdownColor: Colors.white,
        style: GoogleFonts.poppins(color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildImageSection(AppLocalizations l10n) {
    return Column(
      children: [
        _buildSectionHeader(l10n.profilePicture, Icons.camera_alt_rounded),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: roleConfig[widget.role]!['gradient'],
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        if (_imageFile != null) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: roleConfig[widget.role]!['gradient'],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadToCloudinary,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 18),
              label: Text(
                _isUploading ? l10n.uploading : l10n.uploadImage,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ] else ...[
          Text(
            l10n.tapToSelectPicture,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Helper methods
  String _getRoleDisplayName(String role, AppLocalizations l10n) {
    switch (role) {
      case 'coach':
        return l10n.coaches.substring(0, l10n.coaches.length - 1);
      case 'player':
        return l10n.players.substring(0, l10n.players.length - 1);
      case 'team':
        return l10n.teams.substring(0, l10n.teams.length - 1);
      default:
        return role.capitalize();
    }
  }

  String _getSubtitle(AppLocalizations l10n) {
    switch (widget.role) {
      case 'coach':
        return l10n.addNewCoach;
      case 'player':
        return l10n.registerNewPlayer;
      case 'team':
        return l10n.createNewTeam;
      default:
        return l10n.addNewEntry;
    }
  }

  IconData _getActionIcon() {
    switch (widget.role) {
      case 'coach':
        return Icons.person_add_rounded;
      case 'player':
        return Icons.person_add_rounded;
      case 'team':
        return Icons.group_add_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  // Image handling methods
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
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
      // PRODUCTION-FIX: Add timeout and compression settings
      request.fields['quality'] = 'auto:eco';
      request.fields['fetch_format'] = 'auto';
      
      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      // PRODUCTION-FIX: Add timeout for better UX
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
          setState(() {
            _uploadedImageUrl = jsonData['secure_url'];
            _isUploading = false;
          });
          _showSuccessSnackBar('Image uploaded successfully!');
        }
      } else {
        throw Exception(jsonData['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _showErrorSnackBar('Upload failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Data submission methods
  void _onAddPressed() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _submitController.forward();

    try {
      switch (widget.role) {
        case 'coach':
          await _addCoach();
          break;
        case 'player':
          await _addPlayer();
          break;
        case 'team':
          await _addTeam();
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _submitController.reverse();
      }
    }
  }

  Future<void> _addPlayer() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (selectedTeamForPlayer == null || selectedTeamForPlayer!.isEmpty) {
      _showErrorSnackBar("Please select a team for the player.");
      return;
    }

    try {
      // Find the team document by its name
      final teamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('team_name', isEqualTo: selectedTeamForPlayer)
          .limit(1)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        // Team doesn't exist: create it and set count = 1
        await FirebaseFirestore.instance.collection('teams').add({
          'team_name': selectedTeamForPlayer,
          'number_of_players': 1,
          'created_at': Timestamp.now(),
        });
      } else {
        // Team exists: increment player count
        final teamDoc = teamSnapshot.docs.first;
        final teamRef =
            FirebaseFirestore.instance.collection('teams').doc(teamDoc.id);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(teamRef);
          final oldCount = snapshot.get('number_of_players') ?? 0;
          transaction.update(teamRef, {'number_of_players': oldCount + 1});
        });
      }

      // Add the player to the players collection
      await FirebaseFirestore.instance.collection('players').add({
        "name": name,
        "birth_date": birthDate != null ? Timestamp.fromDate(birthDate!) : null,
        "position": position,
        "team": selectedTeamForPlayer,
        "created_at": Timestamp.now(),
      });

      _showSuccessSnackBar('Player added successfully!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error adding player: $e');
    }
  }

  // PRODUCTION-READY: Enhanced team creation with multi-coach support
  Future<void> _addTeam() async {
    // Form validation
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Critical validation: At least one coach required
    if (selectedCoaches.isEmpty) {
      _showErrorSnackBar("At least one coach must be assigned to the team.");
      return;
    }

    String? teamDocId;

    try {
      // Prepare coaches data for storage
      final List<Map<String, dynamic>> coachesData = selectedCoaches
          .map((coach) => {
                'coach_id': coach['id'],
                'coach_name': coach['name'],
                'role': coach['role'],
                'assigned_at': Timestamp.now(),
              })
          .toList();

      // Create team document with all coaches
      final teamRef = await FirebaseFirestore.instance.collection('teams').add({
        "team_name": teamName.trim(),
        "team_description": teamDescription.trim(),
        "number_of_players": 0,
        "coaches": coachesData,
        "primary_coach": selectedCoaches.first['id'], // First coach is primary
        "coach_count": selectedCoaches.length,
        "created_at": Timestamp.now(),
      });

      teamDocId = teamRef.id;

      // Update all coach documents in a single batch
      final batch = FirebaseFirestore.instance.batch();

      for (var coach in selectedCoaches) {
        final coachRef =
            FirebaseFirestore.instance.collection('users').doc(coach['id']);
        batch.update(coachRef, {
          'team': teamName.trim(),
          'team_id': teamDocId,
          'team_role': coach['role'],
        });
      }

      await batch.commit();

      _showSuccessSnackBar(
          'Team "${teamName.trim()}" created with ${selectedCoaches.length} coach(es)!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Critical: Rollback team creation if coach updates fail
      if (teamDocId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('teams')
              .doc(teamDocId)
              .delete();
        } catch (rollbackError) {
          // PRODUCTION-FIX: Use debugPrint instead of print
          debugPrint('Rollback failed: $rollbackError');
        }
      }

      _showErrorSnackBar('Failed to create team. Please try again.');
      debugPrint('Team creation error: $e'); // For debugging
    }
  }

  // Utility methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Stream<QuerySnapshot> getTeamsStream() {
    return FirebaseFirestore.instance.collection('teams').snapshots();
  }
}

// String extension for capitalizing
extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
