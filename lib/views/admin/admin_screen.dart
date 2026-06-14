import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/views/admin/reports/session_report_screen.dart';
import 'package:footballtraining/views/admin/reports/team_report_screen.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/views/admin/user_management_screen.dart';
import 'package:footballtraining/views/admin/settings_screen.dart';
import 'package:footballtraining/views/mlsz/mlsz_dashboard_screen.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  // Core services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controllers
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // User data
  String? userName;
  String? email;
  String? profileImageUrl;
  String? organizationName;

  // Loading states
  bool isLoading = false;
  String? errorMessage;

  // Stats data
  int totalPlayers = 0;
  int totalTeams = 0;
  int activeSessions = 0;
  double attendanceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _getUserDetails();
    _loadStats();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    _entryController.forward();
  }

  Future<void> _getUserDetails() async {
    final user = _auth.currentUser;
    if (user?.uid == null) return;

    setState(() => isLoading = true);

    try {
      // Get user details
      final userDoc = await _firestore
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('users')
          .doc(user!.uid)
          .get();

      // Get organization details
      final orgDoc = await _firestore
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .get();

      if (mounted) {
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userName = userData['name'] ?? 'Admin';
            email = userData['email'] ?? user.email;
            profileImageUrl = userData['picture'];
          });
        }

        if (orgDoc.exists) {
          final orgData = orgDoc.data() as Map<String, dynamic>;
          setState(() {
            organizationName = orgData['organization_name'] ?? 'Organization';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          userName = "Admin";
          email = user?.email ?? "admin@example.com";
          organizationName = "Organization";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final orgId = OrganizationContext.currentOrgId;

      // Get players count
      final playersSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('players')
          .get();

      // Get teams count
      final teamsSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('teams')
          .get();

      // Get recent sessions count (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final sessionsSnapshot = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('training_sessions')
          .where('start_time',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      // Calculate attendance rate
      double totalAttendance = 0;
      int totalPossibleAttendances = 0;

      for (var session in sessionsSnapshot.docs) {
        final data = session.data();
        final players = data['players'] as List<dynamic>? ?? [];
        totalPossibleAttendances += players.length;
        totalAttendance += players
            .where((p) => (p as Map<String, dynamic>)['present'] == true)
            .length;
      }

      if (mounted) {
        setState(() {
          totalPlayers = playersSnapshot.docs.length;
          totalTeams = teamsSnapshot.docs.length;
          activeSessions = sessionsSnapshot.docs.length;
          attendanceRate = totalPossibleAttendances > 0
              ? (totalAttendance / totalPossibleAttendances) * 100
              : 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    }
  }

  Stream<QuerySnapshot> _getRecentSessions() {
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _firestore
        .collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection('training_sessions')
        .where('start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
        .orderBy('start_time', descending: true)
        .limit(5)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    ScreenConfig.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PremiumAppBar(
        title: 'Dashboard',
        subtitle: organizationName,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
      ),
      drawer: _buildDrawer(l10n),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: ScreenConfig.cardPadding,
            child: Column(
              children: [
                // Hero Stats Card
                _buildHeroStatsCard(l10n),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActionsSection(l10n),
                const SizedBox(height: 20),

                // Recent Training Sessions
                _buildRecentSessionsSection(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStatsCard(AppLocalizations l10n) {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Padding(
        padding: ScreenConfig.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'OVERVIEW',
                  style: AppTheme.overline.copyWith(
                    color: AppTheme.background.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.now()),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.background.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenConfig.spaceM),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    totalPlayers.toString(),
                    'TOTAL PLAYERS',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.background.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildHeroStat(
                    totalTeams.toString(),
                    'TOTAL TEAMS',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.background.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _buildHeroStat(
                    activeSessions.toString(),
                    'ACTIVE SESSIONS',
                  ),
                ),
              ],
            ),
            SizedBox(height: ScreenConfig.spaceM),

            // Attendance Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Rate',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.background.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: ScreenConfig.spaceS),
                LinearProgressIndicator(
                  value: attendanceRate / 100,
                  backgroundColor: AppTheme.background.withValues(alpha: 0.2),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.background),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${attendanceRate.toStringAsFixed(1)}%',
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.background.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String number, String label) {
    return Column(
      children: [
        AnimatedCounter(
          target: int.tryParse(number) ?? 0,
          style: AppTheme.heading1.copyWith(
            color: AppTheme.background,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.overline.copyWith(
            color: AppTheme.background.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Quick Actions'),
        SizedBox(height: ScreenConfig.spaceM),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.groups,
                title: 'Teams',
                subtitle: 'Manage teams',
                onTap: () => _showTeamsBottomSheet(context, l10n),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: 'Reports',
                subtitle: 'View analytics',
                onTap: () => _showReportsBottomSheet(context, l10n),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.people,
                title: 'Users',
                subtitle: 'Manage users',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UserManagementScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GradientIcon(
            icon: icon,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Training Sessions',
          actionText: 'See All',
          onActionTap: () {
            // Navigate to full sessions view
          },
        ),
        SizedBox(height: ScreenConfig.spaceM),
        StreamBuilder<QuerySnapshot>(
          stream: _getRecentSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSessionsLoading();
            }

            if (snapshot.hasError) {
              return _buildSessionsError(l10n);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildSessionsEmpty(l10n);
            }

            return StaggeredList(
              children: snapshot.data!.docs
                  .map((doc) => _buildSessionCard(doc, l10n))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(DocumentSnapshot sessionDoc, AppLocalizations l10n) {
    final data = sessionDoc.data() as Map<String, dynamic>? ?? {};
    final teamName = data['team'] ?? 'Unknown Team';
    final coachName = data['coach_name'] ?? 'Unknown Coach';
    final startTime = data['start_time'] as Timestamp?;

    String timeText = 'No Date';
    if (startTime != null) {
      final date = startTime.toDate();
      timeText = DateFormat('MMM dd, HH:mm').format(date);
    }

    // Calculate attendance
    final playersList = data['players'] as List<dynamic>? ?? [];
    final totalPlayers = playersList.length;
    final presentCount = playersList
        .where((p) => (p as Map<String, dynamic>?)?['present'] == true)
        .length;

    // Determine attendance status
    final attendanceRate =
        totalPlayers > 0 ? (presentCount / totalPlayers) : 0.0;
    Color statusColor;
    String statusText;

    if (attendanceRate > 0.7) {
      statusColor = AppTheme.success;
      statusText = 'Good';
    } else if (attendanceRate > 0.4) {
      statusColor = AppTheme.warning;
      statusText = 'Fair';
    } else {
      statusColor = AppTheme.error;
      statusText = 'Low';
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionReportScreen(sessionDoc: sessionDoc),
        ),
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 3,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  style: AppTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      coachName,
                      style: AppTheme.caption,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeText,
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right side - Attendance info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(
                label: statusText,
                color: statusColor,
              ),
              const SizedBox(height: 4),
              Text(
                '$presentCount/$totalPlayers players',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => ShimmerCard(
          height: 80,
        ),
      ),
    );
  }

  Widget _buildSessionsError(AppLocalizations l10n) {
    return AppCard(
      child: Center(
        child: Column(
          children: [
            GradientIcon(
              icon: Icons.error_outline,
              gradient: LinearGradient(
                colors: [AppTheme.error, AppTheme.error.withValues(alpha: 0.7)],
              ),
            ),
            const SizedBox(height: 12),
            Text('Error loading sessions', style: AppTheme.heading3),
            const SizedBox(height: 4),
            Text('Please try again', style: AppTheme.caption),
            SizedBox(height: ScreenConfig.spaceM),
            GradientButton(
              label: 'Retry',
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsEmpty(AppLocalizations l10n) {
    return AppCard(
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.event_available,
                size: 40,
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: ScreenConfig.spaceM),
            Text(
              'No Recent Sessions',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: 4),
            Text(
              'Training sessions will appear here',
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          PremiumDrawerHeader(
            name: userName ?? 'Admin',
            role: 'Administrator',
            imageUrl: profileImageUrl,
          ),
          SizedBox(height: ScreenConfig.spaceS),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: l10n.dashboardOverview,
                  onTap: () {
                    Navigator.pop(context);
                    _showTeamsBottomSheet(context, l10n);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_rounded,
                  title: l10n.manageUsers,
                  onTap: () =>
                      _navigateToScreen(context, const UserManagementScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_rounded,
                  title: l10n.reports,
                  onTap: () {
                    Navigator.pop(context);
                    _showReportsBottomSheet(context, l10n);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: l10n.notifications,
                  onTap: () => _showComingSoon(context, l10n),
                ),
                _buildDrawerItem(
                  icon: Icons.sports_soccer,
                  title: "League Information",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MLSZDashboardScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildDrawerItem(
            icon: Icons.settings_rounded,
            title: l10n.settings,
            onTap: () => _navigateToScreen(context, const SettingsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.logout_rounded,
            title: l10n.logout,
            textColor: AppTheme.error,
            iconColor: AppTheme.error,
            onTap: () => _showLogoutDialog(context, l10n),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: GradientIcon(
        icon: icon,
        size: 36,
        iconSize: 18,
        gradient: iconColor != null
            ? LinearGradient(colors: [iconColor, iconColor])
            : null,
      ),
      title: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          color: textColor ?? AppTheme.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textMuted,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  // Helper methods
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.comingSoon,
          style: AppTheme.bodyMedium,
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.error),
              const SizedBox(width: 12),
              Text(
                l10n.logout,
                style: AppTheme.heading3,
              ),
            ],
          ),
          content: Text(
            l10n.confirmLogout,
            style: AppTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style:
                    AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            GradientButton(
              label: l10n.logout,
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              height: 40,
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Loginpage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
            style: AppTheme.bodyMedium,
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTeamsBottomSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GradientIcon(icon: Icons.groups, size: 40, iconSize: 20),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teams', style: AppTheme.heading3),
                      Text(
                        'Select a team to view report',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ScreenConfig.spaceM),

            // Divider
            const Divider(color: AppTheme.border, height: 1),

            // Teams list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('organizations')
                    .doc(OrganizationContext.currentOrgId)
                    .collection('teams')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.error, size: 48),
                          const SizedBox(height: 12),
                          Text('Error loading teams',
                              style: AppTheme.bodyMedium),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.surface2,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(
                              Icons.groups_outlined,
                              size: 40,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          SizedBox(height: ScreenConfig.spaceM),
                          Text('No teams found', style: AppTheme.heading3),
                          SizedBox(height: ScreenConfig.spaceS),
                          Text(
                            'Create teams in the receptionist screen',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: ScreenConfig.cardPadding,
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final teamDoc = snapshot.data!.docs[index];
                      final data = teamDoc.data() as Map<String, dynamic>;
                      final teamName = data['team_name'] ?? 'Unknown Team';
                      final playerCount = data['number_of_players'] ?? 0;
                      final description = data['team_description'] ?? '';

                      return AppCard(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TeamReportScreen(teamDoc: teamDoc),
                            ),
                          );
                        },
                        padding: ScreenConfig.cardPadding,
                        child: Row(
                          children: [
                            // Team avatar
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups,
                                color: AppTheme.background,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Team info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(teamName, style: AppTheme.bodyLarge),
                                  const SizedBox(height: 4),
                                  if (description.isNotEmpty)
                                    Text(
                                      description,
                                      style: AppTheme.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people,
                                        size: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$playerCount players',
                                        style: AppTheme.caption.copyWith(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Arrow
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ],
                        ),
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

  void _showReportsBottomSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: Padding(
          padding: ScreenConfig.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: ScreenConfig.spaceL),

              // Header
              Row(
                children: [
                  GradientIcon(
                    icon: Icons.analytics_rounded,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reports', style: AppTheme.heading3),
                      Text(
                        'Generate and export reports',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: ScreenConfig.spaceL),

              // Report options
              _buildReportOption(
                context: context,
                icon: Icons.groups_rounded,
                title: 'Team Report',
                subtitle: 'Player list, positions, stats per team',
                onTap: () {
                  Navigator.pop(context);
                  _showTeamsBottomSheet(context, l10n);
                },
              ),
              const SizedBox(height: 12),
              _buildReportOption(
                context: context,
                icon: Icons.event_note_rounded,
                title: 'Session Report',
                subtitle: 'Attendance and stats per training session',
                onTap: () {
                  Navigator.pop(context);
                  _showSessionsBottomSheet(context, l10n);
                },
              ),
              SizedBox(height: ScreenConfig.spaceL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: ScreenConfig.cardPadding,
      child: Row(
        children: [
          GradientIcon(icon: icon, size: 44, iconSize: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
        ],
      ),
    );
  }

  void _showSessionsBottomSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  GradientIcon(
                    icon: Icons.event_note_rounded,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session Reports', style: AppTheme.heading3),
                      Text('Select a session', style: AppTheme.caption),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: ScreenConfig.spaceM),
            const Divider(color: AppTheme.border, height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('organizations')
                    .doc(OrganizationContext.currentOrgId)
                    .collection('training_sessions')
                    .orderBy('start_time', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_busy,
                              size: 48, color: AppTheme.textMuted),
                          SizedBox(height: ScreenConfig.spaceM),
                          Text('No sessions found', style: AppTheme.heading3),
                          SizedBox(height: ScreenConfig.spaceS),
                          Text(
                            'Training sessions will appear here',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: ScreenConfig.cardPadding,
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sessionDoc = snapshot.data!.docs[index];
                      final data = sessionDoc.data() as Map<String, dynamic>;
                      final teamName = data['team'] ?? 'Unknown Team';
                      final trainingType =
                          data['training_type'] ?? data['type'] ?? '';
                      final startTime = data['start_time'] as Timestamp?;
                      String timeText = 'No date';
                      if (startTime != null) {
                        timeText = DateFormat('MMM dd, yyyy • HH:mm')
                            .format(startTime.toDate());
                      }

                      final players = data['players'] as List<dynamic>? ?? [];
                      final presentCount = players
                          .where((p) =>
                              (p as Map<String, dynamic>?)?['present'] == true)
                          .length;

                      return AppCard(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionReportScreen(
                                sessionDoc: sessionDoc,
                              ),
                            ),
                          );
                        },
                        padding: ScreenConfig.cardPadding,
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(teamName, style: AppTheme.bodyLarge),
                                  const SizedBox(height: 4),
                                  Text(timeText, style: AppTheme.caption),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                StatusBadge(
                                  label: trainingType,
                                  color: AppTheme.primary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$presentCount/${players.length}',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
}
