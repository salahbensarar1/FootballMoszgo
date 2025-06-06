import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/admin/reports/session_report_screen.dart';

import 'package:google_fonts/google_fonts.dart';
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

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  // State variables
  int playerCount = 0;
  int teamCount = 0;
  int coachCount = 0;
  int sessionCount = 0;
  double attendanceRate = 0.0;
  bool isLoadingStats = true;

  // Stream for recent sessions
  Stream<QuerySnapshot>? recentSessionsStream;

  // Greeting based on time
  String greeting = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setGreeting();
    _fetchAllStats();
    _setupRecentSessionsStream();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    // Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Scale Animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Slide Animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Rotation Animation (for refresh icon)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    _slideController.forward();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
  }

  Future<void> _fetchAllStats() async {
    setState(() => isLoadingStats = true);
    _rotationController.repeat();

    try {
      // Fetch all counts in parallel
      final results = await Future.wait([
        _firestore.collection('players').count().get(),
        _firestore.collection('teams').count().get(),
        _firestore
            .collection('users')
            .where('role', isEqualTo: 'coach')
            .count()
            .get(),
        _firestore.collection('training_sessions').count().get(),
      ]);

      // Calculate attendance rate
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

      if (mounted) {
        setState(() {
          playerCount = results[0].count ?? 0;
          teamCount = results[1].count ?? 0;
          coachCount = results[2].count ?? 0;
          sessionCount = results[3].count ?? 0;
          attendanceRate =
              totalPossible > 0 ? (totalAttendance / totalPossible) * 100 : 0;
          isLoadingStats = false;
        });
        _rotationController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingStats = false);
        _rotationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _setupRecentSessionsStream() {
    recentSessionsStream = _firestore
        .collection('training_sessions')
        .orderBy('start_time', descending: true)
        .limit(5)
        .snapshots();
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
                  _buildWelcomeSection(l10n, isSmallScreen),
                  _buildStatsSection(l10n, isTablet, size),
                  _buildQuickActions(l10n, size),
                  _buildRecentSessionsSection(l10n, size),
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
      expandedHeight: isSmallScreen ? 120 : 200,
      floating: true,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          l10n.dashboardOverview,
          style: GoogleFonts.poppins(
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF27121),
                Color(0xFFE94057),
                Color(0xFF8A2387),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
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
                onPressed: _fetchAllStats,
                tooltip: 'Refresh',
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notifications coming soon!'),
                backgroundColor: Color(0xFFF27121),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(AppLocalizations l10n, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s your club overview for today',
            style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to detailed stats
                },
                icon: Icon(Icons.arrow_forward_rounded,
                    size: isSmallScreen ? 14 : 16),
                label: Text(
                  'View All',
                  style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFFF27121),
                ),
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
      children: List.generate(4, (index) => _buildLoadingStatCard()),
    );
  }

  double _calculateCardHeight(Size size) {
    final isSmallScreen = size.height < 700;
    if (isSmallScreen) {
      return 100; // Smaller height for small screens
    } else if (size.height < 800) {
      return 120; // Medium height
    } else {
      return 140; // Default height
    }
  }

  Widget _buildLoadingStatCard() {
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
        child: CircularProgressIndicator(
          color: Color(0xFFF27121),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppLocalizations l10n, bool isTablet, Size size) {
    final cardHeight = _calculateCardHeight(size);
    final isSmallScreen = size.height < 700;

    final stats = [
      StatItem(
        title: l10n.players,
        value: playerCount.toString(),
        icon: Icons.people_rounded,
        gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
        delay: 0,
      ),
      StatItem(
        title: l10n.teams,
        value: teamCount.toString(),
        icon: Icons.groups_rounded,
        gradient: [Color(0xFFF093fb), Color(0xFFF5576c)],
        delay: 100,
      ),
      StatItem(
        title: 'Coaches',
        value: coachCount.toString(),
        icon: Icons.sports_rounded,
        gradient: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        delay: 200,
      ),
      StatItem(
        title: 'Sessions',
        value: sessionCount.toString(),
        icon: Icons.event_available_rounded,
        gradient: [Color(0xFFfa709a), Color(0xFFfee140)],
        delay: 300,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        childAspectRatio: isTablet ? 1.2 : (size.width / 2 - 24) / cardHeight,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + stats[index].delay),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildStatCard(stats[index], isSmallScreen),
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
                    style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
                  title: 'Add Session',
                  icon: Icons.add_circle_outline_rounded,
                  color: Color(0xFF10B981),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to add session
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'View Reports',
                  icon: Icons.analytics_outlined,
                  color: Color(0xFF6366F1),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Navigate to reports
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
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Container(
                  width: isSmallScreen ? 40 : 48,
                  height: isSmallScreen ? 40 : 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsSection(AppLocalizations l10n, Size size) {
    final isSmallScreen = size.height < 700;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Sessions',
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Navigate to all sessions
                },
                icon: Icon(Icons.arrow_forward_rounded,
                    size: isSmallScreen ? 14 : 16),
                label: Text(
                  'See All',
                  style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFFF27121),
                ),
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
      stream: recentSessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSession();
        }

        if (snapshot.hasError) {
          return _buildErrorWidget('Error loading sessions');
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptySessionsWidget();
        }

        final sessions = snapshot.data!.docs;
        return SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final sessionDoc = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
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
          ),
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
                    gradient: LinearGradient(
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
                        style: GoogleFonts.poppins(
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
                                    style: GoogleFonts.poppins(
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
                            style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
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

  Widget _buildLoadingSession() {
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
              color: Color(0xFFF27121),
              strokeWidth: 2,
            ),
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
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Training sessions will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
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
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
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

  String _formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMM, HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }
}

// Helper Classes
class StatItem {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int delay;

  StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.delay,
  });
}
