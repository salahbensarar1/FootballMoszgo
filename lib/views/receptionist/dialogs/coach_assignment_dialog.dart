import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/services/organization_scoped_team_service.dart';
import 'package:footballtraining/data/models/team_model.dart';
import 'package:footballtraining/data/models/user_model.dart' as UserModel;

class CoachAssignmentDialog extends StatefulWidget {
  final String teamId;
  final String teamName;
  final VoidCallback? onChanged;

  const CoachAssignmentDialog({
    super.key,
    required this.teamId,
    required this.teamName,
    this.onChanged,
  });

  @override
  State<CoachAssignmentDialog> createState() => _CoachAssignmentDialogState();
}

class _CoachAssignmentDialogState extends State<CoachAssignmentDialog>
    with TickerProviderStateMixin {
  final OrganizationScopedTeamService _teamService =
      OrganizationScopedTeamService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  List<UserModel.User> availableCoaches = [];
  List<Map<String, dynamic>> currentCoachDetails = [];
  bool isLoading = true;
  bool isProcessing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print(
          '🔄 CoachAssignmentDialog: Starting data load for team ${widget.teamId}');

      // Load team coach details and available coaches in parallel with timeout
      final results = await Future.wait([
        _teamService.getTeamCoachDetails(widget.teamId),
        _teamService.getAvailableCoaches(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Request timeout - please check your connection and try again');
        },
      );

      if (mounted) {
        final coachDetails = results[0] as List<Map<String, dynamic>>;
        final coaches = results[1] as List<UserModel.User>;

        print(
            '✅ CoachAssignmentDialog: Loaded ${coachDetails.length} current coaches and ${coaches.length} available coaches');

        setState(() {
          currentCoachDetails = coachDetails;
          availableCoaches = coaches;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ CoachAssignmentDialog: Error loading data: $e');
      print('📍 Stack trace: $stackTrace');

      if (mounted) {
        String userFriendlyError;
        if (e.toString().contains('Organization context not initialized')) {
          userFriendlyError =
              'Organization not selected. Please refresh the app and try again.';
        } else if (e.toString().contains('not-found')) {
          userFriendlyError =
              'Team or coach data not found. This may be a permission issue.';
        } else if (e.toString().contains('timeout')) {
          userFriendlyError =
              'Connection timeout. Please check your internet and try again.';
        } else {
          userFriendlyError =
              'Failed to load coach data. Please try again.\n\nError: ${e.toString()}';
        }

        setState(() {
          errorMessage = userFriendlyError;
          isLoading = false;
        });
      }
    }
  }

  void _showSuccess(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            width: isSmallScreen ? size.width * 0.95 : 600,
            height: isSmallScreen ? size.height * 0.85 : 700,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(isSmallScreen),
                Expanded(
                  child: isLoading
                      ? _buildLoadingState()
                      : errorMessage != null
                          ? _buildErrorState()
                          : _buildContent(isSmallScreen),
                ),
                _buildActions(isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: isSmallScreen ? 24 : 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Coaches',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 16 : 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.teamName,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading coaches...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 48,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        children: [
          _buildCurrentCoaches(isSmallScreen),
          SizedBox(height: 24),
          _buildAvailableCoaches(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildCurrentCoaches(bool isSmallScreen) {
    return Expanded(
      flex: currentCoachDetails.isNotEmpty ? 2 : 1,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Current Coaches (${currentCoachDetails.length})',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: currentCoachDetails.isEmpty
                    ? _buildEmptyCoaches()
                    : ListView.separated(
                        itemCount: currentCoachDetails.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildCurrentCoachCard(
                              currentCoachDetails[index], isSmallScreen);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCoaches() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No coaches assigned',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add coaches from the list below',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentCoachCard(
      Map<String, dynamic> coachDetail, bool isSmallScreen) {
    // 🔥 DEFENSIVE NULL CHECKING - prevent cast exceptions
    final user = coachDetail['user'] as UserModel.User?;
    final teamCoach = coachDetail['teamCoach'] as TeamCoach?;

    // Fallback if proper objects aren't available (backwards compatibility)
    if (user == null || teamCoach == null) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coach Data Error',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    'Unable to load coach details. Please refresh.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 6 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 20 : 24,
            backgroundColor: Colors.green.shade100,
            backgroundImage: user.picture?.isNotEmpty == true
                ? NetworkImage(user.picture!)
                : null,
            child: user.picture?.isEmpty != false
                ? Text(
                    user.initials,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                      fontSize: isSmallScreen ? 12 : 16,
                    ),
                  )
                : null,
          ),
          SizedBox(
            width: isSmallScreen ? 8 : 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: isSmallScreen ? 6 : 9,
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 9,
                          vertical: isSmallScreen ? 6 : 9),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        TeamService.getCoachRoleDisplayName(teamCoach.role),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) =>
                _handleCoachAction(action, user.id, teamCoach.role),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_role',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz,
                        size: 18, color: Colors.blue.shade600),
                    SizedBox(width: isSmallScreen ? 6 : 9),
                    const Text('Change Role'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle,
                        size: 18, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Text('Remove',
                        style: TextStyle(color: Colors.red.shade600)),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: Colors.green.shade700,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCoaches(bool isSmallScreen) {
    // 🔥 DEFENSIVE EXTRACTION - prevent null cast exceptions
    final assignedCoachIds = currentCoachDetails
        .map((detail) {
          final user = detail['user'] as UserModel.User?;
          return user?.id ?? detail['userId'] ?? ''; // Fallback to userId field
        })
        .where((id) => id.isNotEmpty)
        .toList();

    // ✅ FIXED: Show ALL coaches, allowing multi-team assignments
    // Coaches can be assigned to multiple teams with different roles
    
    // Show ALL available coaches regardless of current assignment
    final displayCoaches = availableCoaches;
    
    print('🔍 Available coaches to display: ${displayCoaches.length}');
    print('📋 Already assigned coach IDs: $assignedCoachIds');

    return Expanded(
      flex: 2,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Available Coaches (${displayCoaches.length})',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 8 : 16),
              Expanded(
                child: displayCoaches.isEmpty
                    ? _buildNoAvailableCoaches()
                    : ListView.separated(
                        itemCount: displayCoaches.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: isSmallScreen ? 8 : 12),
                        itemBuilder: (context, index) {
                          final coach = displayCoaches[index];
                          final isAlreadyAssigned = assignedCoachIds.contains(coach.id);
                          return _buildAvailableCoachCard(
                              coach, isSmallScreen, isAlreadyAssigned: isAlreadyAssigned);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoAvailableCoaches() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 10),
            Text(
              'No coaches available',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create coach accounts from the Receptionist screen to assign them to teams',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableCoachCard(UserModel.User coach, bool isSmallScreen, {bool isAlreadyAssigned = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAlreadyAssigned 
              ? [Colors.orange.shade50, Colors.white]
              : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isAlreadyAssigned 
                ? Colors.orange.shade200 
                : Colors.blue.shade200
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 20 : 24,
            backgroundColor: isAlreadyAssigned 
                ? Colors.orange.shade100
                : Colors.blue.shade100,
            backgroundImage: coach.picture?.isNotEmpty == true
                ? NetworkImage(coach.picture!)
                : null,
            child: coach.picture?.isEmpty != false
                ? Text(
                    coach.initials,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isAlreadyAssigned 
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coach.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (coach.email.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    coach.email,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Add visual indicator if already assigned
                if (isAlreadyAssigned) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Already in this team',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (role) => _addCoach(coach.id, role),
            itemBuilder: (context) => TeamService.allCoachRoles.map((role) {
              return PopupMenuItem(
                value: role,
                child: Text(TeamService.getCoachRoleDisplayName(role)),
              );
            }).toList(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isAlreadyAssigned
                      ? [Colors.green.shade500, Colors.green.shade600]
                      : [Colors.blue.shade500, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: isAlreadyAssigned
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAlreadyAssigned ? Icons.add_rounded : Icons.add_rounded, 
                    color: Colors.white, 
                    size: 16
                  ),
                  SizedBox(width: 4),
                  Text(
                    isAlreadyAssigned ? 'Add Role' : 'Add',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${currentCoachDetails.length} coaches assigned',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ACTION METHODS

  Future<void> _addCoach(String coachId, String role) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      print(
          '🔄 CoachAssignmentDialog: Adding coach $coachId to team ${widget.teamId} with role $role');

      await _teamService.addCoachToTeam(
        teamId: widget.teamId,
        coachUserId: coachId,
        role: role,
      );

      print('✅ CoachAssignmentDialog: Coach addition completed successfully');
      _showSuccess('Coach added successfully!');

      // Add delay to allow Firestore to sync before refreshing
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadData(); // Refresh data
      widget.onChanged?.call(); // Notify parent
    } catch (e, stackTrace) {
      print('❌ CoachAssignmentDialog: Error adding coach: $e');
      print('📍 Stack trace: $stackTrace');

      // Check if this is a non-critical error (coach might still be added)
      String errorMessage;
      if (e.toString().contains('User teams array') ||
          e.toString().contains('non-critical')) {
        errorMessage =
            'Coach was added but there was a sync issue. Please refresh to verify.';
        _showSuccess(errorMessage);

        // Still try to refresh data after delay
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadData();
      } else {
        errorMessage = 'Failed to add coach: ${e.toString()}';
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _removeCoach(String coachId) async {
    if (isProcessing) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade600),
            SizedBox(width: 12),
            Text(
              'Remove Coach',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove this coach from the team?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      print(
          '🔄 CoachAssignmentDialog: Removing coach $coachId from team ${widget.teamId}');

      await _teamService.removeCoachFromTeam(widget.teamId, coachId);

      print('✅ CoachAssignmentDialog: Coach removal completed successfully');
      _showSuccess('Coach removed successfully!');

      // Add delay to allow Firestore to sync before refreshing
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadData(); // Refresh data
      widget.onChanged?.call(); // Notify parent
    } catch (e, stackTrace) {
      print('❌ CoachAssignmentDialog: Error removing coach: $e');
      print('📍 Stack trace: $stackTrace');

      // Check if this is a non-critical error (coach might still be removed)
      String errorMessage;
      if (e.toString().contains('User teams array') ||
          e.toString().contains('non-critical') ||
          e.toString().contains('was not found')) {
        errorMessage =
            'Coach was removed but there was a sync issue. Please refresh to verify.';
        _showSuccess(errorMessage);

        // Still try to refresh data after delay
        await Future.delayed(const Duration(milliseconds: 1000));
        await _loadData();
      } else {
        errorMessage = 'Failed to remove coach: ${e.toString()}';
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _changeCoachRole(String coachId, String currentRole) async {
    if (isProcessing) return;

    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Change Coach Role',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TeamService.allCoachRoles
              .where((role) => role != currentRole)
              .map((role) => ListTile(
                    title: Text(TeamService.getCoachRoleDisplayName(role)),
                    onTap: () => Navigator.pop(context, role),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );

    if (newRole == null) return;

    setState(() => isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      await _teamService.updateCoachRole(widget.teamId, coachId, newRole);
      _showSuccess('Coach role updated successfully!');
      await _loadData(); // Refresh data
      widget.onChanged?.call(); // Notify parent
    } catch (e) {
      _showError('Failed to update coach role: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _handleCoachAction(String action, String coachId, String currentRole) {
    switch (action) {
      case 'remove':
        _removeCoach(coachId);
        break;
      case 'change_role':
        _changeCoachRole(coachId, currentRole);
        break;
    }
  }
}
