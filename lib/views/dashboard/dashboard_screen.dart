import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/admin/admin_screen.dart';
import 'package:footballtraining/views/admin/reports/session_report_screen.dart';
import 'package:footballtraining/views/admin/settings_screen.dart'
    as admin_settings;
import 'package:footballtraining/views/admin/user_management_screen.dart';
import 'package:footballtraining/views/coach/coach_screen.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/views/receptionist/receptionist_screen.dart';

import 'package:footballtraining/utils/responsive_design.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  // Dashboard Stats
  DashboardStats stats = DashboardStats();
  bool isLoadingStats = true;

  // User data
  String? userRole;
  String? userName;
  String? userEmail;
  bool isLoadingUser = true;

  // Performance optimizations
  DateTime? _lastDataLoad;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
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
      duration: const Duration(milliseconds: 600), // Faster fade-in
      vsync: this,
    );
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster rotation
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

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            final data = userDoc.data()!;
            userRole = data['role'] as String?;
            userName = data['name'] as String?;
            userEmail = user.email;
            isLoadingUser = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoadingUser = false);
        }
      }
    }
  }

  Future<void> _loadDashboardData() async {
    // Check if data is still valid (cached)
    if (_lastDataLoad != null &&
        DateTime.now().difference(_lastDataLoad!) < _cacheValidityDuration &&
        !isLoadingStats) {
      return; // Use cached data
    }

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
          _lastDataLoad = DateTime.now(); // Update cache timestamp
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

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Professional responsive breakpoints
    final isTablet = size.width > 768;
    final isLargePhone = size.width > 414;
    final isSmallScreen = size.width < 375; // iPhone SE and smaller
    final isVerySmallScreen = size.width < 350;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: _buildNavigationDrawer(l10n),
      body: RefreshIndicator(
        onRefresh: () async {
          _lastDataLoad = null; // Force refresh
          HapticFeedback.lightImpact(); // Haptic feedback
          await _loadDashboardData();
        },
        color: const Color(0xFFF27121),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(l10n, isSmallScreen, isVerySmallScreen),
            SliverPadding(
              padding: EdgeInsets.only(
                left: isVerySmallScreen ? 12 : 16,
                right: isVerySmallScreen ? 12 : 16,
                bottom: padding.bottom + 32,
              ),
              sliver: SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(
                          l10n, isSmallScreen, isVerySmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildStatsSection(l10n, isTablet, isLargePhone,
                          isVerySmallScreen, size),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildQuickActions(
                          l10n, isTablet, isLargePhone, isVerySmallScreen),
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      _buildRecentSessionsSection(
                          l10n, isSmallScreen, isVerySmallScreen),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(
      AppLocalizations l10n, bool isSmallScreen, bool isVerySmallScreen) {
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
                color: Colors.black.withValues(alpha: 0.3),
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
                    color: Colors.white.withValues(alpha: 0.1),
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
                    color: Colors.white.withValues(alpha: 0.1),
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

  Widget _buildWelcomeSection(
      AppLocalizations l10n, bool isSmallScreen, bool isVerySmallScreen) {
    final size = MediaQuery.of(context).size;
    final isTinyScreen = size.width < 320;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      padding: EdgeInsets.all(isTinyScreen ? 12 : (isSmallScreen ? 16 : 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _getGreeting(l10n),
              style: TextStyle(
                fontSize: isTinyScreen ? 20 : (isSmallScreen ? 24 : 28),
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.clubOverviewToday,
            style: TextStyle(
              fontSize: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n, bool isTablet,
      bool isLargePhone, bool isVerySmallScreen, Size size) {
    final isSmallScreen = size.width < 375;
    final isTinyScreen = size.width < 320;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isTinyScreen ? 8 : (isSmallScreen ? 12 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed responsive header
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 350;
              if (isVeryNarrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.keyStatistics,
                      style: TextStyle(
                        fontSize: isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Navigate to detailed stats
                      },
                      icon: Icon(Icons.arrow_forward_rounded,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16)),
                      label: Text(
                        l10n.viewDetails,
                        style: TextStyle(
                            fontSize:
                                isTinyScreen ? 10 : (isSmallScreen ? 12 : 14)),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF27121),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 8 : 12,
                          vertical: isTinyScreen ? 4 : 8,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.keyStatistics,
                        style: TextStyle(
                          fontSize:
                              isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Navigate to detailed stats
                      },
                      icon: Icon(Icons.arrow_forward_rounded,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16)),
                      label: Text(
                        l10n.viewDetails,
                        style: TextStyle(
                            fontSize:
                                isTinyScreen ? 10 : (isSmallScreen ? 12 : 14)),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF27121),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 8 : 12,
                          vertical: isTinyScreen ? 4 : 8,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          isLoadingStats
              ? _buildLoadingStats(isTablet, size)
              : _buildStatsGrid(l10n, isTablet, size),
        ],
      ),
    );
  }

  Widget _buildLoadingStats(bool isTablet, Size size) {
    final isSmallScreen = size.width < 375;
    final isTinyScreen = size.width < 320;
    final crossAxisCount = isTablet ? 4 : 2;

    final horizontalPadding = isTinyScreen ? 16 : (isSmallScreen ? 24 : 32);
    final cardSpacing = isTinyScreen ? 8 : 12;
    final cardWidth =
        (size.width - horizontalPadding - (crossAxisCount - 1) * cardSpacing) /
            crossAxisCount;
    final optimalHeight = isTinyScreen ? 95.0 : (isSmallScreen ? 110.0 : 125.0);
    final aspectRatio = (cardWidth / optimalHeight).clamp(0.8, 2.0);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: aspectRatio,
      crossAxisSpacing: cardSpacing.toDouble(),
      mainAxisSpacing: cardSpacing.toDouble(),
      children: List.generate(5, (_) => _buildLoadingCard()),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 80,
        maxHeight: 140,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
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

  Widget _buildStatsGrid(AppLocalizations l10n, bool isTablet, Size size) {
    final isSmallScreen = size.width < 375;
    final isTinyScreen = size.width < 320;
    final crossAxisCount = isTablet ? 4 : 2;

    // Professional responsive calculations with safe constraints
    final horizontalPadding = isTinyScreen ? 16 : (isSmallScreen ? 24 : 32);
    final cardSpacing = isTinyScreen ? 8 : 12;
    final cardWidth =
        (size.width - horizontalPadding - (crossAxisCount - 1) * cardSpacing) /
            crossAxisCount;
    final optimalHeight = isTinyScreen
        ? 95.0
        : (isSmallScreen ? 110.0 : 125.0); // Increased slightly
    final aspectRatio =
        (cardWidth / optimalHeight).clamp(0.8, 2.0); // Safe aspect ratio

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
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: cardSpacing.toDouble(),
        mainAxisSpacing: cardSpacing.toDouble(),
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
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
    final isTinyScreen = MediaQuery.of(context).size.width < 320;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: stat.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat.gradient[0].withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding:
                EdgeInsets.all(isTinyScreen ? 8 : (isSmallScreen ? 10 : 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with overflow protection
                Container(
                  constraints: BoxConstraints(
                    maxWidth: double.infinity,
                    maxHeight: isTinyScreen ? 28 : (isSmallScreen ? 32 : 36),
                  ),
                  padding: EdgeInsets.all(isTinyScreen ? 4 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat.icon,
                    color: Colors.white,
                    size: isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                  ),
                ),

                // Flexible space with constraint
                const Spacer(),

                // Value with constrained sizing
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      stat.value,
                      style: TextStyle(
                        fontSize: isTinyScreen ? 20 : (isSmallScreen ? 22 : 24),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Title with overflow protection
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 16),
                  child: Text(
                    stat.title,
                    style: TextStyle(
                      fontSize: isTinyScreen ? 10 : (isSmallScreen ? 11 : 12),
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n, bool isTablet,
      bool isLargePhone, bool isVerySmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: TextStyle(
            fontSize: isVerySmallScreen ? 16 : (isTablet ? 22 : 18),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: isVerySmallScreen ? 12 : 16),
        // Adaptive layout based on screen size
        isVerySmallScreen
            ? _buildQuickActionsGrid(l10n, isVerySmallScreen)
            : _buildQuickActionsRow(l10n, isTablet, isLargePhone),
      ],
    );
  }

  Widget _buildQuickActionsRow(
      AppLocalizations l10n, bool isTablet, bool isLargePhone) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            title: l10n.teams,
            icon: Icons.groups_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navigate to team management
            },
            isSmallScreen: !isLargePhone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            title: l10n.reports,
            icon: Icons.analytics_outlined,
            color: const Color(0xFF6366F1),
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navigate to reports
            },
            isSmallScreen: !isLargePhone,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            title: l10n.manageUsers,
            icon: Icons.people_outline,
            color: const Color(0xFFEF4444),
            onTap: () {
              HapticFeedback.mediumImpact();
              // Navigate to user management
            },
            isSmallScreen: !isLargePhone,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(AppLocalizations l10n, bool isVerySmallScreen) {
    final actions = [
      {
        'title': l10n.teams,
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF10B981)
      },
      {
        'title': l10n.reports,
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF6366F1)
      },
      {
        'title': l10n.manageUsers,
        'icon': Icons.people_outline,
        'color': const Color(0xFFEF4444)
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3, // Reduced to accommodate taller cards
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildQuickActionCard(
          title: action['title'] as String,
          icon: action['icon'] as IconData,
          color: action['color'] as Color,
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate based on index
          },
          isSmallScreen: isVerySmallScreen,
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    final size = MediaQuery.of(context).size;
    final isTinyScreen = size.width < 320;

    return Container(
      height:
          isTinyScreen ? 85 : (isSmallScreen ? 90 : 95), // Increased heights
      constraints: BoxConstraints(
        minHeight: isTinyScreen ? 85 : (isSmallScreen ? 90 : 95),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding:
                EdgeInsets.all(isTinyScreen ? 6 : (isSmallScreen ? 8 : 10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isTinyScreen ? 28 : (isSmallScreen ? 32 : 36),
                  height: isTinyScreen ? 28 : (isSmallScreen ? 32 : 36),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      color: color,
                      size: isTinyScreen ? 14 : (isSmallScreen ? 16 : 18)),
                ),
                SizedBox(height: isTinyScreen ? 3 : 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isTinyScreen ? 9 : (isSmallScreen ? 10 : 11),
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                      height: 1.2, // Better line height
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSessionsSection(
      AppLocalizations l10n, bool isSmallScreen, bool isVerySmallScreen) {
    final size = MediaQuery.of(context).size;
    final isTinyScreen = size.width < 320;

    return Padding(
      padding: EdgeInsets.all(isTinyScreen ? 8 : (isSmallScreen ? 12 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed responsive sessions header
          LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 350;
              if (isVeryNarrow) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recentTrainingSessions,
                      style: TextStyle(
                        fontSize: isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Navigate to all sessions
                      },
                      icon: Icon(Icons.arrow_forward_rounded,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16)),
                      label: Text(
                        l10n.seeAll,
                        style: TextStyle(
                            fontSize:
                                isTinyScreen ? 10 : (isSmallScreen ? 12 : 14)),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF27121),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 8 : 12,
                          vertical: isTinyScreen ? 4 : 8,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recentTrainingSessions,
                        style: TextStyle(
                          fontSize:
                              isTinyScreen ? 16 : (isSmallScreen ? 18 : 20),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // Navigate to all sessions
                      },
                      icon: Icon(Icons.arrow_forward_rounded,
                          size: isTinyScreen ? 12 : (isSmallScreen ? 14 : 16)),
                      label: Text(
                        l10n.seeAll,
                        style: TextStyle(
                            fontSize:
                                isTinyScreen ? 10 : (isSmallScreen ? 12 : 14)),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF27121),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 8 : 12,
                          vertical: isTinyScreen ? 4 : 8,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
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
              duration: Duration(milliseconds: 250 + (index * 75)),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                            .withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _buildNavigationDrawer(AppLocalizations l10n) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(l10n),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: l10n.dashboardOverview,
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  if (userRole == 'admin') ...[
                    _buildDrawerSection('Administration'),
                    _buildDrawerItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin Panel',
                      onTap: () => _navigateToScreen(const AdminScreen()),
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_rounded,
                      title: l10n.manageUsers,
                      onTap: () =>
                          _navigateToScreen(const UserManagementScreen()),
                    ),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: l10n.settings,
                      onTap: () => _navigateToScreen(
                          const admin_settings.SettingsScreen()),
                    ),
                  ],
                  if (userRole == 'receptionist') ...[
                    _buildDrawerSection('Reception'),
                    _buildDrawerItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Reception Panel',
                      onTap: () =>
                          _navigateToScreen(const ReceptionistScreen()),
                    ),
                  ],
                  if (userRole == 'coach') ...[
                    _buildDrawerSection('Coaching'),
                    _buildDrawerItem(
                      icon: Icons.sports_rounded,
                      title: 'Coach Panel',
                      onTap: () => _navigateToScreen(const CoachScreen()),
                    ),
                  ],
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    title: l10n.logout,
                    isDestructive: true,
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.spacing()),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF27121), Color(0xFFE94057), Color(0xFF8A2387)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: context.isMobile ? 30 : 35,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              (userName?.isNotEmpty == true)
                  ? userName!.substring(0, 1).toUpperCase()
                  : 'U',
              style: TextStyle(
                fontSize: context.isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: context.spacing(factor: 0.5)),
          Text(
            userName ?? 'User',
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            userRole?.toUpperCase() ?? 'USER',
            style: TextStyle(
              fontSize: context.captionFontSize,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          context.spacing(),
          context.spacing(factor: 0.75),
          context.spacing(),
          context.spacing(factor: 0.25)),
      child: Text(
        title,
        style: TextStyle(
          fontSize: context.captionFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red.shade600
        : isSelected
            ? const Color(0xFFF27121)
            : Colors.grey.shade700;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spacing(factor: 0.5)),
      child: ListTile(
        leading: Icon(icon, color: color, size: context.iconSize * 0.8),
        title: Text(
          title,
          style: TextStyle(
            fontSize: context.bodyFontSize * 0.9,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFFF27121).withValues(alpha: 0.1),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: context.spacing()),
      ),
    );
  }

  void _navigateToScreen(Widget screen) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Loginpage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Logout failed: $e');
      }
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
