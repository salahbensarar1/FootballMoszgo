import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Import your updated payment models
import '../../data/models/payment_model.dart';

// Import dialogs
import 'dialogs/mark_payment_dialog.dart';
import 'dialogs/export_report_dialog.dart';
import 'dialogs/bulk_reminder_dialog.dart';
import 'dialogs/player_details_dialog.dart';

class PaymentOverviewScreen extends StatefulWidget {
  const PaymentOverviewScreen({super.key});

  @override
  State<PaymentOverviewScreen> createState() => _PaymentOverviewScreenState();
}

class _PaymentOverviewScreenState extends State<PaymentOverviewScreen>
    with TickerProviderStateMixin {
  // Animation controllers - optimized for performance
  late AnimationController _animationController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State management
  int selectedYear = DateTime.now().year;
  String selectedFilter = 'all';
  bool isLoading = false;

  // Tab controller for different views
  late TabController _tabController;

  // Team payment fees cache - performance optimization
  Map<String, double> teamPaymentFees = {};
  bool isLoadingTeamFees = true;

  // Hungarian Forint formatter - const for performance
  static const String _currencySymbol = 'Ft';
  static final NumberFormat _hungarianFormatter =
      NumberFormat('#,##0', 'hu_HU');

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeamPaymentFees();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Reduced from 1200ms
      vsync: this,
    );

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 600), // Reduced from 800ms
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve:
          const Interval(0.0, 0.6, curve: Curves.easeOut), // Optimized timing
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Reduced offset for better UX
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve:
          const Interval(0.2, 0.8, curve: Curves.easeOutCubic), // Better curve
    ));

    _animationController.forward();
  }

  Future<void> _loadTeamPaymentFees() async {
    try {
      final teamsSnapshot =
          await FirebaseFirestore.instance.collection('teams').get();

      final Map<String, double> fees = {};

      for (final doc in teamsSnapshot.docs) {
        final data = doc.data();
        final teamName = data['team_name'] as String? ?? '';
        final payment = data['payment'] as num? ?? 15000; // Default 15000 HUF
        fees[teamName] = payment.toDouble();
      }

      if (mounted) {
        setState(() {
          teamPaymentFees = fees;
          isLoadingTeamFees = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingTeamFees = false;
        });
      }
      debugPrint('Error loading team payment fees: $e');
    }
  }

  // Helper method to get team payment fee - optimized
  double _getTeamPaymentFee(String teamName) {
    return teamPaymentFees[teamName] ?? 15000.0; // Default 15000 HUF
  }

  // Helper method to format Hungarian Forint - optimized static method
  String _formatHUF(double amount) {
    return '${_hungarianFormatter.format(amount)} $_currencySymbol';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      body: isLoadingTeamFees
          ? _buildLoadingState(l10n)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTabBar(l10n, isSmallScreen, isTablet),
                  _buildFilters(l10n, isSmallScreen, isTablet),
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildTabContent(l10n),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton:
          isLoadingTeamFees ? null : _buildFloatingActionButton(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.paymentOverview,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshData,
          tooltip: l10n.refresh,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  const Icon(Icons.file_download_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.exportData),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'bulk_reminder',
              child: Row(
                children: [
                  const Icon(Icons.email_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.sendReminders),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'download_center',
              child: Row(
                children: [
                  const Icon(Icons.download_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.downloadCenter),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(
      AppLocalizations l10n, bool isSmallScreen, bool isTablet) {
    const double height = 60; // Fixed height for better performance
    final double horizontalPadding = isSmallScreen ? 12 : (isTablet ? 14 : 16);

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          tabs: [
            _buildTab(l10n.overview, Icons.dashboard_rounded, 0, isSmallScreen),
            _buildTab(l10n.players, Icons.people_rounded, 1, isSmallScreen),
            _buildTab(l10n.reports, Icons.analytics_rounded, 2, isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, IconData icon, int index, bool isSmallScreen) {
    final isActive = _tabController.index == index;

    return Tab(
      height: 40,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 16 : 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            if (!isSmallScreen) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(
      AppLocalizations l10n, bool isSmallScreen, bool isTablet) {
    final double horizontalPadding = isSmallScreen ? 12 : (isTablet ? 14 : 16);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use Column for very small screens
          if (constraints.maxWidth < 400) {
            return Column(
              children: [
                _buildYearSelector(l10n),
                const SizedBox(height: 8),
                _buildFilterSelector(l10n),
              ],
            );
          }

          // Use Row for larger screens
          return Row(
            children: [
              Expanded(child: _buildYearSelector(l10n)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildFilterSelector(l10n)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<int>(
        value: selectedYear,
        decoration: InputDecoration(
          labelText: l10n.year,
          labelStyle: GoogleFonts.poppins(fontSize: 12),
          prefixIcon: const Icon(Icons.calendar_today_rounded,
              color: Color(0xFF667eea), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: List.generate(5, (index) {
          final year = DateTime.now().year - index;
          return DropdownMenuItem(
            value: year,
            child: Text(year.toString()),
          );
        }),
        onChanged: (value) {
          setState(() => selectedYear = value!);
        },
      ),
    );
  }

  Widget _buildFilterSelector(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedFilter,
        decoration: InputDecoration(
          labelText: l10n.filter,
          labelStyle: GoogleFonts.poppins(fontSize: 12),
          prefixIcon: const Icon(Icons.filter_list_rounded,
              color: Color(0xFF667eea), size: 18),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          DropdownMenuItem(value: 'all', child: Text(l10n.allPlayers)),
          DropdownMenuItem(value: 'paid', child: Text(l10n.fullyPaid)),
          DropdownMenuItem(value: 'unpaid', child: Text(l10n.unpaid)),
          DropdownMenuItem(value: 'partial', child: Text(l10n.partial)),
        ],
        onChanged: (value) {
          setState(() => selectedFilter = value!);
        },
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(l10n),
        _buildPlayersTab(l10n),
        _buildReportsTab(l10n),
      ],
    );
  }

  Widget _buildOverviewTab(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(l10n);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(l10n.noPaymentDataAvailable);
        }

        return FutureBuilder<PaymentStats>(
          future: _calculatePaymentStats(snapshot.data!.docs),
          builder: (context, statsSnapshot) {
            if (!statsSnapshot.hasData) {
              return _buildLoadingState(l10n);
            }

            final stats = statsSnapshot.data!;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 12 : 16),
              child: Column(
                children: [
                  _buildStatsCards(l10n, stats),
                  const SizedBox(height: 20),
                  _buildMonthlyChart(l10n, stats),
                  const SizedBox(height: 20),
                  _buildQuickActions(l10n),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCards(AppLocalizations l10n, PaymentStats stats) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 1 : 2;
    final childAspectRatio = screenWidth < 600 ? 2.5 : 1.5;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard(
          l10n.totalCollected,
          _formatHUF(stats.totalCollected),
          Icons.account_balance_wallet_rounded,
          const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
          stats.collectionRate,
        ),
        _buildStatCard(
          l10n.outstanding,
          _formatHUF(stats.totalOutstanding),
          Icons.pending_actions_rounded,
          const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
          100 - stats.collectionRate,
        ),
        _buildStatCard(
          l10n.paidPlayers,
          '${stats.fullyPaidPlayers}/${stats.totalPlayers}',
          Icons.people_rounded,
          const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
          stats.totalPlayers > 0
              ? (stats.fullyPaidPlayers / stats.totalPlayers * 100)
              : 0,
        ),
        _buildStatCard(
          l10n.thisMonth,
          _formatHUF(stats.thisMonthCollected),
          Icons.calendar_month_rounded,
          const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFBE185D)]),
          stats.thisMonthProgress,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      LinearGradient gradient, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                gradient.colors.first,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart(AppLocalizations l10n, PaymentStats stats) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF667eea), size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.monthlyCollectionTrend,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSimpleChart(stats.monthlyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(Map<int, double> monthlyData) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth > 300 ? constraints.maxWidth : 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                final value = monthlyData[index + 1] ?? 0;
                final maxValue = monthlyData.values.isNotEmpty
                    ? monthlyData.values.reduce((a, b) => a > b ? a : b)
                    : 1;
                final height = maxValue > 0
                    ? (value / maxValue * 100).clamp(10, 100)
                    : 10.0;

                return Flexible(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 16,
                          height: height.toDouble(),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        months[index],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on_rounded,
                    color: Color(0xFF667eea), size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.quickActions,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 400) {
                  // Stack buttons vertically on small screens
                  return Column(
                    children: [
                      _buildActionButton(
                        l10n.markPayment,
                        Icons.payment_rounded,
                        const Color(0xFF667eea),
                        () => _showMarkPaymentDialog(),
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        l10n.sendReminders,
                        Icons.email_rounded,
                        const Color(0xFFF59E0B),
                        () => _showBulkReminderDialog(),
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        l10n.exportReport,
                        Icons.file_download_rounded,
                        const Color(0xFF10B981),
                        () => _showExportDialog(),
                      ),
                    ],
                  );
                } else {
                  // Use row layout for larger screens
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              l10n.markPayment,
                              Icons.payment_rounded,
                              const Color(0xFF667eea),
                              () => _showMarkPaymentDialog(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              l10n.sendReminders,
                              Icons.email_rounded,
                              const Color(0xFFF59E0B),
                              () => _showBulkReminderDialog(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          l10n.exportReport,
                          Icons.file_download_rounded,
                          const Color(0xFF10B981),
                          () => _showExportDialog(),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('players').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(l10n);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('${l10n.noPlayersFound}');
        }

        return FutureBuilder<List<PlayerPaymentStatus>>(
          future: _getPlayerPaymentStatuses(snapshot.data!.docs),
          builder: (context, statusSnapshot) {
            if (!statusSnapshot.hasData) {
              return _buildLoadingState(l10n);
            }

            final List<PlayerPaymentStatus> filteredPlayers =
                _filterPlayersByStatus(statusSnapshot.data!);

            return ListView.separated(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 12 : 16),
              itemCount: filteredPlayers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildPlayerCard(l10n, filteredPlayers[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerCard(AppLocalizations l10n, PlayerPaymentStatus player) {
    final teamFee = _getTeamPaymentFee(player.team);
    final totalPaid = player.paidMonths * teamFee;
    final totalOutstanding = (player.totalMonths - player.paidMonths) * teamFee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _getStatusGradient(player.status),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      player.name.isNotEmpty
                          ? player.name[0].toUpperCase()
                          : 'P',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
                        player.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${player.team} • ${_formatHUF(teamFee)}/${l10n.month}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(player.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(l10n, player.status),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(player.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.paymentProgress,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '${player.paidMonths}/${player.totalMonths} ${l10n.months}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: player.totalMonths > 0
                        ? player.paidMonths / player.totalMonths
                        : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(player.status),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.paid}: ${_formatHUF(totalPaid)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${l10n.outstanding}: ${_formatHUF(totalOutstanding)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlayerActionButton(
                          l10n.viewDetails,
                          Icons.visibility_rounded,
                          const Color(0xFF667eea),
                          () => _showPlayerDetailsDialog(player),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPlayerActionButton(
                          l10n.sendReminder,
                          Icons.email_rounded,
                          const Color(0xFFF59E0B),
                          () => _sendReminderToPlayer(l10n, player),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          _buildReportCard(
            l10n.monthlyReport,
            l10n.detailedBreakdownByMonth,
            Icons.calendar_view_month_rounded,
            const Color(0xFF667eea),
            () => _generateMonthlyReport(l10n),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            l10n.teamReport,
            l10n.paymentStatusByTeam,
            Icons.groups_rounded,
            const Color(0xFF10B981),
            () => _generateTeamReport(l10n),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            l10n.overdueReport,
            l10n.playersWithOutstandingPayments,
            Icons.warning_rounded,
            const Color(0xFFF59E0B),
            () => _generateOverdueReport(l10n),
          ),
          const SizedBox(height: 12),
          _buildReportCard(
            l10n.annualSummary,
            l10n.completeYearOverview,
            Icons.summarize_rounded,
            const Color(0xFFEC4899),
            () => _generateAnnualReport(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon,
      Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF667eea),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loadingPaymentData,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.payment_rounded,
                color: Colors.grey.shade400,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showPaymentActions(l10n),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          l10n.paymentActions,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper methods and data processing
  Future<PaymentStats> _calculatePaymentStats(
      List<DocumentSnapshot> players) async {
    double totalCollected = 0;
    double totalOutstanding = 0;
    int fullyPaidPlayers = 0;
    double thisMonthCollected = 0;
    final Map<int, double> monthlyData = {};

    final currentMonth = DateTime.now().month;

    for (final player in players) {
      final playerId = player.id;
      final playerData = player.data() as Map<String, dynamic>;
      final playerTeam = playerData['team'] ?? '';
      final monthlyFee = _getTeamPaymentFee(playerTeam);

      // Get payment data for this player
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .get();

      int paidMonths = 0;
      for (final payment in paymentsSnapshot.docs) {
        final paymentData = payment.data();
        final docId = payment.id; // Format: "2025-01", "2025-02", etc.

        // Check if this payment is for the selected year
        if (docId.startsWith(selectedYear.toString()) &&
            paymentData['isPaid'] == true) {
          paidMonths++;
          totalCollected += monthlyFee;

          // Extract month from document ID (e.g., "2025-01" -> "01")
          final monthStr = docId.split('-').last;
          final monthNumber = int.tryParse(monthStr) ?? 0;

          if (monthNumber == currentMonth) {
            thisMonthCollected += monthlyFee;
          }

          // Add to monthly data
          monthlyData[monthNumber] =
              (monthlyData[monthNumber] ?? 0) + monthlyFee;
        }
      }

      // Calculate outstanding (assuming 12 months total)
      final unpaidMonths = 12 - paidMonths;
      totalOutstanding += unpaidMonths * monthlyFee;

      if (paidMonths == 12) {
        fullyPaidPlayers++;
      }
    }

    final totalExpected = totalCollected + totalOutstanding;
    final collectionRate =
        totalExpected > 0 ? (totalCollected / totalExpected) * 100 : 0.0;

    // Calculate this month's progress more accurately
    double totalExpectedThisMonth = 0;
    for (final player in players) {
      final playerData = player.data() as Map<String, dynamic>;
      final playerTeam = playerData['team'] ?? '';
      final monthlyFee = _getTeamPaymentFee(playerTeam);
      totalExpectedThisMonth += monthlyFee;
    }

    final thisMonthProgress = totalExpectedThisMonth > 0
        ? (thisMonthCollected / totalExpectedThisMonth) * 100
        : 0.0;

    return PaymentStats(
      totalCollected: totalCollected,
      totalOutstanding: totalOutstanding,
      fullyPaidPlayers: fullyPaidPlayers,
      totalPlayers: players.length,
      thisMonthCollected: thisMonthCollected,
      monthlyData: monthlyData,
      collectionRate: collectionRate,
      thisMonthProgress: thisMonthProgress,
    );
  }

  Future<List<PlayerPaymentStatus>> _getPlayerPaymentStatuses(
      List<DocumentSnapshot> players) async {
    final List<PlayerPaymentStatus> statuses = [];

    for (final player in players) {
      final data = player.data() as Map<String, dynamic>;
      final playerId = player.id;
      final playerTeam = data['team'] ?? '';

      // Get payment data for selected year
      final paymentsSnapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .get();

      int paidMonths = 0;
      for (final payment in paymentsSnapshot.docs) {
        final paymentData = payment.data();
        final docId = payment.id; // Format: "2025-01", "2025-02", etc.

        // Check if this payment is for the selected year and is paid
        if (docId.startsWith(selectedYear.toString()) &&
            paymentData['isPaid'] == true) {
          paidMonths++;
        }
      }

      PaymentStatus status;
      if (paidMonths == 0) {
        status = PaymentStatus.unpaid;
      } else if (paidMonths == 12) {
        status = PaymentStatus.paid;
      } else {
        status = PaymentStatus.partial;
      }

      statuses.add(PlayerPaymentStatus(
        playerId: playerId,
        name: data['name'] ?? 'Unknown Player',
        team: playerTeam,
        paidMonths: paidMonths,
        totalMonths: 12,
        status: status,
        email: data['email'],
        phoneNumber: data['phone'],
      ));
    }

    return statuses;
  }

  List<PlayerPaymentStatus> _filterPlayersByStatus(
      List<PlayerPaymentStatus> players) {
    switch (selectedFilter) {
      case 'paid':
        return players.where((p) => p.status == PaymentStatus.paid).toList();
      case 'unpaid':
        return players.where((p) => p.status == PaymentStatus.unpaid).toList();
      case 'partial':
        return players.where((p) => p.status == PaymentStatus.partial).toList();
      default:
        return players;
    }
  }

  List<Color> _getStatusGradient(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const [Color(0xFF10B981), Color(0xFF059669)];
      case PaymentStatus.partial:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)];
      case PaymentStatus.unpaid:
        return const [Color(0xFFEF4444), Color(0xFFDC2626)];
      case PaymentStatus.notActive:
        return const [Color(0xFF6B7280), Color(0xFF4B5563)]; // Grey gradient
    }
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return const Color(0xFF10B981);
      case PaymentStatus.partial:
        return const Color(0xFFF59E0B);
      case PaymentStatus.unpaid:
        return const Color(0xFFEF4444);
      case PaymentStatus.notActive:
        return const Color(0xFF6B7280); // Grey color for not active
    }
  }

  String _getStatusText(AppLocalizations l10n, PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return l10n.fullyPaid;
      case PaymentStatus.partial:
        return l10n.partial;
      case PaymentStatus.unpaid:
        return l10n.unpaid;
      case PaymentStatus.notActive:
        return l10n.notActive; // New status text
    }
  }

  // Action methods
  void _refreshData() async {
    setState(() => isLoading = true);
    await _loadTeamPaymentFees();
    _refreshController.forward().then((_) {
      _refreshController.reverse();
      setState(() => isLoading = false);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'bulk_reminder':
        _showBulkReminderDialog();
        break;
      case 'download_center':
        _showDownloadCenter();
        break;
    }
  }

  void _showPaymentActions(AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.paymentActions,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildActionListTile(
                l10n.markPayment,
                l10n.recordNewPayment,
                Icons.payment_rounded,
                () => _showMarkPaymentDialog(),
              ),
              _buildActionListTile(
                l10n.sendReminders,
                l10n.sendBulkPaymentReminders,
                Icons.email_rounded,
                () => _showBulkReminderDialog(),
              ),
              _buildActionListTile(
                l10n.exportData,
                l10n.downloadPaymentReport,
                Icons.file_download_rounded,
                () => _showExportDialog(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionListTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF667eea).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF667eea)),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
    );
  }

  // Dialog methods
  void _showMarkPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => MarkPaymentDialog(
        selectedYear: selectedYear,
        teamPaymentFees: teamPaymentFees,
      ),
    );
  }

  void _showBulkReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => BulkReminderDialog(
        selectedYear: selectedYear,
        teamPaymentFees: teamPaymentFees,
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const ExportReportDialog(),
    );
  }

  void _showPlayerDetailsDialog(PlayerPaymentStatus player) {
    showDialog(
      context: context,
      builder: (context) => PlayerDetailsDialog(
        player: player,
        selectedYear: selectedYear,
      ),
    );
  }

  void _showDownloadCenter() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.downloadCenter,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded,
                      color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.exportedReportsAvailable,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.recentDownloads,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open_rounded, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(
                    l10n.noRecentDownloads,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.close,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder methods for functionality
  void _sendReminderToPlayer(
      AppLocalizations l10n, PlayerPaymentStatus player) {
    final teamFee = _getTeamPaymentFee(player.team);
    final amount =
        _formatHUF((player.totalMonths - player.paidMonths) * teamFee);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.paymentReminderSent(player.name, amount),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _generateMonthlyReport(AppLocalizations l10n) {
    _showSuccessSnackBar(l10n.monthlyReportGenerated);
  }

  void _generateTeamReport(AppLocalizations l10n) {
    _showSuccessSnackBar(l10n.teamReportGenerated);
  }

  void _generateOverdueReport(AppLocalizations l10n) {
    _showSuccessSnackBar(l10n.overdueReportGenerated);
  }

  void _generateAnnualReport(AppLocalizations l10n) {
    _showSuccessSnackBar(l10n.annualReportGenerated);
  }

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
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
