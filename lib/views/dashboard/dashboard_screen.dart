import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/data/repositories/team_service.dart';
import 'package:footballtraining/views/admin/reports/session_report_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TeamService _teamService = TeamService();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  // Dashboard Stats
  DashboardStats stats = DashboardStats();
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _fadeController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoadingStats = true);
    _rotationController.repeat();

    try {
      // Load all stats in parallel for better performance
      final results = await Future.wait([
        _firestore.collection('players').count().get(),
        _firestore.collection('teams').count().get(),
        _firestore
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .count()
            .get(),
        _firestore.collection('training_sessions').count().get(),
        _calculateAttendanceRate(),
      ]);

      if (mounted) {
        setState(() {
          stats = DashboardStats(
            playerCount: (results[0] as AggregateQuerySnapshot).count ?? 0,
            teamCount: (results[1] as AggregateQuerySnapshot).count ?? 0,
            coachCount: (results[2] as AggregateQuerySnapshot).count ?? 0,
            sessionCount: (results[3] as AggregateQuerySnapshot).count ?? 0,
            attendanceRate: results[4] as double,
          );
          isLoadingStats = false;
        });
        _rotationController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingStats = false);
        _rotationController.stop();
        _showErrorMessage('Error loading dashboard data: $e');
      }
    }
  }

  Future<double> _calculateAttendanceRate() async {
    try {
      final sessionsSnapshot = await _firestore
          .collection('training_sessions')
          .orderBy('start_time', descending: true)
          .limit(10)
          .get();

      double totalAttendance = 0;
      int totalPossible = 0;

      for (var doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final players = data['players'] as List<dynamic>?;
        if (players != null) {
          totalPossible += players.length;
          totalAttendance += players.where((p) => p['present'] == true).length;
        }
      }

      return totalPossible > 0 ? (totalAttendance / totalPossible) * 100 : 0;
    } catch (e) {
      return 0;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(l10n, isSmallScreen),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildWelcomeSection(isSmallScreen),
                  _buildStatsSection(l10n, isTablet, size),
                  _buildQuickActions(l10n, size),
                  _buildRecentSessionsSection(l10n, isSmallScreen),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AppLocalizations l10n, bool isSmallScreen) {
    return SliverAppBar(
      expandedHeight: isSmallScreen ? 120 : 180,
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          l10n.dashboardOverview,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 16 : 20,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF27121), Color(0xFFE94057), Color(0xFF8A2387)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadDashboardData,
                tooltip: 'Refresh',
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting,
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your club overview for today',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n, bool isTablet, Size size) {
    final isSmallScreen = size.height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Key Metrics',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Navigate to detailed stats
                },
                icon: Icon(Icons.arrow_forward_rounded,
                    size: isSmallScreen ? 14 : 16),
                label: Text(
                  'View All',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF27121)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isLoadingStats
              ? _buildLoadingStats(isTablet, size)
              : _buildStatsGrid(l10n, isTablet, size),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(bool isTablet, Size size) {
    final cardHeight = _calculateCardHeight(size);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      childAspectRatio: isTablet ? 1.2 : (size.width / 2 - 24) / cardHeight,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: List.generate(5, (_) => _buildLoadingCard()),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child:
            CircularProgressIndicator(color: Color(0xFFF27121), strokeWidth: 2),
      ),
    );
  }

  double _calculateCardHeight(Size size) {
    if (size.height < 700) return 100;
    if (size.height < 800) return 120;
    return 140;
  }

  Widget _buildStatsGrid(AppLocalizations l10n, bool isTablet, Size size) {
    final cardHeight = _calculateCardHeight(size);
    final isSmallScreen = size.height < 700;

    final statItems = [
      StatItem(
        title: l10n.players,
        value: stats.playerCount.toString(),
        icon: Icons.people_rounded,
        gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
      ),
      StatItem(
        title: l10n.teams,
        value: stats.teamCount.toString(),
        icon: Icons.groups_rounded,
        gradient: [const Color(0xFFF093fb), const Color(0xFFF5576c)],
      ),
      StatItem(
        title: 'Coaches',
        value: stats.coachCount.toString(),
        icon: Icons.sports_rounded,
        gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      ),
      StatItem(
        title: 'Sessions',
        value: stats.sessionCount.toString(),
        icon: Icons.event_available_rounded,
        gradient: [const Color(0xFFfa709a), const Color(0xFFfee140)],
      ),
      StatItem(
        title: 'Attendance',
        value: '${stats.attendanceRate.round()}%',
        icon: Icons.trending_up_rounded,
        gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 5 : 2,
        childAspectRatio: isTablet ? 1.2 : (size.width / 2 - 24) / cardHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildStatCard(statItems[index], isSmallScreen),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(StatItem stat, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stat.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: stat.gradient[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            // Navigate to detailed view
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stat.icon,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    stat.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n, Size size) {
    final isSmallScreen = size.height < 700;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Teams',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to team management
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'View Reports',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to reports
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'User Management',
                  icon: Icons.people_outline,
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to user management
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Container(
      height: isSmallScreen ? 70 : 80,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isSmallScreen ? 32 : 40,
                  height: isSmallScreen ? 32 : 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsSection(
      AppLocalizations l10n, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sessions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // Navigate to all sessions
                },
                icon: Icon(Icons.arrow_forward_rounded,
                    size: isSmallScreen ? 14 : 16),
                label: Text(
                  'See All',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF27121)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSessionsList(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildSessionsList(bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('training_sessions')
          .orderBy('start_time', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSessions();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading sessions: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptySessionsWidget();
        }

        final sessions = snapshot.data!.docs;
        return Column(
          children: sessions.asMap().entries.map((entry) {
            final index = entry.key;
            final sessionDoc = entry.value;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildSessionCard(sessionDoc, isSmallScreen),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionCard(DocumentSnapshot sessionDoc, bool isSmallScreen) {
    final data = sessionDoc.data() as Map<String, dynamic>? ?? {};
    final teamName = data['team'] ?? 'N/A';
    final trainingType = data['training_type'] ?? 'N/A';
    final startTime = data['start_time'] as Timestamp?;
    final coachName = data['coach_name'] ?? 'Unknown';

    // Calculate attendance
    final players = data['players'] as List<dynamic>? ?? [];
    final presentCount = players.where((p) => p['present'] == true).length;
    final totalCount = players.length;
    final attendancePercentage =
        totalCount > 0 ? (presentCount / totalCount * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SessionReportScreen(sessionDoc: sessionDoc),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 48 : 56,
                  height: isSmallScreen ? 48 : 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sports_soccer_rounded,
                    color: Colors.white,
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$teamName - $trainingType',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: isSmallScreen ? 14 : 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    coachName,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(startTime),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Container(
                      width: isSmallScreen ? 40 : 50,
                      height: isSmallScreen ? 40 : 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getAttendanceColor(attendancePercentage)
                            .withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          '$attendancePercentage%',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w700,
                            color: _getAttendanceColor(attendancePercentage),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$presentCount/$totalCount',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSessions() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 88,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(
                color: Color(0xFFF27121), strokeWidth: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySessionsWidget() {
    return Container(
      padding: const EdgeInsets.all(40),
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
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Training sessions will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(int percentage) {
    if (percentage >= 80) return Colors.green.shade600;
    if (percentage >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat('dd MMM, HH:mm').format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

// Helper Classes
class DashboardStats {
  final int playerCount;
  final int teamCount;
  final int coachCount;
  final int sessionCount;
  final double attendanceRate;

  DashboardStats({
    this.playerCount = 0,
    this.teamCount = 0,
    this.coachCount = 0,
    this.sessionCount = 0,
    this.attendanceRate = 0.0,
  });
}

class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}
