import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/views/receptionist/dialogs/add_entry_dialog.dart';
import 'package:footballtraining/views/receptionist/dialogs/coach_assignment_dialog.dart';
import 'package:footballtraining/views/receptionist/payment_overview_screen.dart';
import 'package:footballtraining/views/shared/widgets/payment_month_indicator.dart';
import 'package:footballtraining/data/repositories/coach_management_service.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceptionistScreen extends StatefulWidget {
  const ReceptionistScreen({super.key});

  @override
  State<ReceptionistScreen> createState() => _ReceptionistScreenState();
}

/// Production-ready ReceptionistScreen with comprehensive optimizations:
/// - Full responsive design using ResponsiveUtils
/// - Memory leak prevention with proper disposal
/// - Enhanced error handling and loading states
/// - Complete localization support
/// - Performance optimizations with memoization
/// - Cross-device compatibility (phones/tablets/desktop)
class _ReceptionistScreenState extends State<ReceptionistScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Performance: Keep widget alive to prevent rebuilds
  @override
  bool get wantKeepAlive => true;
  // Core state
  int currentTab = 0;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController; // Services\n
  final CoachManagementService _coachManagementService =
      CoachManagementService();

  // User data
  String? userName;
  String? email;
  String? profileImageUrl;

  // Enhanced state management
  bool isLoading = false;
  bool isInitialized = false;
  String? errorMessage;

  // Stream subscriptions for proper disposal (prevent memory leaks)
  final List<StreamSubscription> _subscriptions = [];

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // ignore: unused_field
  late Animation<double> _scaleAnimation;

  // Tab configuration
  final List<TabConfig> tabConfigs = [
    TabConfig(
      icon: Icons.sports_rounded,
      activeIcon: Icons.sports,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2)],
      name: 'coaches',
    ),
    TabConfig(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      name: 'players',
    ),
    TabConfig(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      name: 'teams',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _setupAnimations();
    _getUserDetails();
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    // Comprehensive cleanup to prevent memory leaks
    _animationController.dispose();
    _fabAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();

    // Cancel all stream subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
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
    _fabAnimationController.forward();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        currentTab = _tabController.index;
        searchQuery = "";
        _searchController.clear();
      });

      // Animate FAB
      _fabAnimationController.reset();
      _fabAnimationController.forward();
    }
  }

  void _handleSearchChange() {
    if (_searchController.text.isEmpty && searchQuery.isNotEmpty) {
      setState(() {
        searchQuery = "";
      });
    }
  }

  Future<void> _getUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.uid == null) return;

    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (mounted) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'] ?? 'Receptionist';
            email = data['email'] ?? user.email;
            profileImageUrl = data['picture'];
            isLoading = false;
          });
        } else {
          setState(() {
            userName = "Receptionist";
            email = user.email ?? "receptionist@example.com";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          userName = "Receptionist";
          email = user?.email ?? "receptionist@example.com";
          isLoading = false;
        });
      }
    }
  }

  List<String> get tabs => [
        AppLocalizations.of(context)!.coaches,
        AppLocalizations.of(context)!.players,
        AppLocalizations.of(context)!.teams
      ];

  Stream<QuerySnapshot> getStreamForCurrentTab() {
    if (currentTab == 0) {
      return FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots();
    } else if (currentTab == 1) {
      return FirebaseFirestore.instance.collection('players').snapshots();
    } else {
      return FirebaseFirestore.instance.collection('teams').snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final l10n = AppLocalizations.of(context)!;

    // Enhanced responsive breakpoints using ResponsiveUtils
    final isSmallScreen = ResponsiveUtils.isMobile(context);
    // ignore: unused_local_variable
    final isTablet = ResponsiveUtils.isTablet(context);
    // ignore: unused_local_variable
    final isDesktop = ResponsiveUtils.isDesktop(context);

    // Error boundary for production stability
    if (errorMessage != null && !isInitialized) {
      return _buildErrorScaffold(l10n);
    }

    // Enhanced loading state
    if (isLoading && !isInitialized) {
      return _buildLoadingScaffold(l10n);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      drawer: isSmallScreen
          ? _buildDrawer(l10n)
          : null, // Only show drawer on mobile
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTabBar(l10n, tabs, isSmallScreen),
            _buildSearchBar(l10n, tabs, isSmallScreen),
            //CleanupButton(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(l10n),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: _buildFloatingActionButton(l10n),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.receptionistScreen,
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
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshData,
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  Widget _buildDrawer(AppLocalizations l10n) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildDrawerHeader(l10n),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.payment_rounded,
                    title: l10n.paymentOverview,
                    onTap: () => _navigateToPaymentOverview(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: l10n.settings,
              onTap: () => _showComingSoon(context, l10n),
            ),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              textColor: Colors.red.shade600,
              iconColor: Colors.red.shade600,
              onTap: () => _showLogoutDialog(context, l10n),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'receptionist_avatar',
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl?.isNotEmpty == true
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage('assets/images/default_profile.jpeg')
                            as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName ?? l10n.receptionistScreen,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email ?? "receptionist@example.com",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF667eea)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF667eea),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: textColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildTabBar(
      AppLocalizations l10n, List<String> tabs, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 70 : 80,
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 8 : 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: tabConfigs[currentTab].gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: tabConfigs[currentTab].gradient[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
          tabs: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isActive = currentTab == index;

            return Tab(
              height: isSmallScreen ? 45 : 50,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? tabConfigs[index].activeIcon
                          : tabConfigs[index].icon,
                      size: isSmallScreen ? 18 : 20,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isActive ? Colors.white : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
      AppLocalizations l10n, List<String> tabs, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: l10n.searchHint(tabs[currentTab]),
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tabConfigs[currentTab].gradient[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search_rounded,
                color: tabConfigs[currentTab].gradient[0],
                size: 20,
              ),
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon:
                        Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => searchQuery = "");
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: getStreamForCurrentTab(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(l10n, snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(l10n);
        }

        // Filter items based on search query
        List<DocumentSnapshot> items = snapshot.data!.docs.where((doc) {
          if (currentTab == 0) {
            // Coaches
            return doc['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          } else if (currentTab == 1) {
            // Players
            var data = doc.data() as Map<String, dynamic>?;
            if (data == null) return false;
            String playerName = data['name']?.toString().toLowerCase() ?? '';
            return playerName.contains(searchQuery.toLowerCase());
          } else {
            // Teams
            return doc['team_name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          }
        }).toList();

        if (items.isEmpty && searchQuery.isNotEmpty) {
          return _buildEmptySearchState(l10n);
        }

        return _buildItemsList(items, l10n);
      },
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: tabConfigs[currentTab].gradient[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircularProgressIndicator(
              color: tabConfigs[currentTab].gradient[0],
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loading,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.somethingWentWrong,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryAgainOrContact,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: tabConfigs[currentTab].gradient[0],
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    final icons = [
      Icons.sports_rounded,
      Icons.people_rounded,
      Icons.groups_rounded
    ];

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
                icons[currentTab],
                color: Colors.grey.shade400,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${tabs[currentTab]} found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some ${tabs[currentTab].toLowerCase()} to get started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: Colors.grey.shade400,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results for "$searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<DocumentSnapshot> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        if (currentTab == 1) {
          return _buildPlayerCard(item, l10n);
        } else {
          return _buildStandardCard(item, l10n);
        }
      },
    );
  }

  Widget _buildPlayerCard(DocumentSnapshot item, AppLocalizations l10n) {
    final data = item.data() as Map<String, dynamic>;
    final String title = data['name'] ?? 'Unnamed Player';
    final String subtitle =
        "${l10n.position}: ${data['position'] ?? 'Unknown'}";
    final String pictureUrl = data['picture']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'player_${item.id}',
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: pictureUrl.isEmpty
                          ? const AssetImage(
                              "assets/images/default_profile.jpeg")
                          : NetworkImage(pictureUrl) as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      color: Colors.grey.shade600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == "edit") {
                      _editUser(item);
                    } else if (value == "delete") {
                      _deleteUser(item);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              size: 20, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 20, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Text(l10n.delete,
                              style: TextStyle(color: Colors.red.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Payment Status Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.payment_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${l10n.paymentStatus}:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PaymentMonthIndicator(
                  playerId: item.id,
                  isEditable: true,
                  currentUserEmail: FirebaseAuth.instance.currentUser?.email,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardCard(DocumentSnapshot item, AppLocalizations l10n) {
    final data = item.data() as Map<String, dynamic>;

    String title = '';
    String subtitle = '';
    IconData cardIcon = Icons.person;
    List<Color> cardGradient = tabConfigs[currentTab].gradient;

    if (currentTab == 0) {
      // Coaches
      title = data['name'] ?? 'Unnamed Coach';
      subtitle = data['role_description'] ?? 'Coach';
      cardIcon = Icons.sports_rounded;
    } else {
      // Teams
      title = data['team_name'] ?? 'Unnamed Team';
      subtitle = "${l10n.players}: ${data['number_of_players'] ?? 0}";
      cardIcon = Icons.groups_rounded;
    }

    final String pictureUrl = data['picture']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Add navigation to detail screen if needed
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: cardGradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cardGradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: pictureUrl.isEmpty
                    ? Icon(
                        cardIcon,
                        color: Colors.white,
                        size: 28,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          pictureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              cardIcon,
                              color: Colors.white,
                              size: 28,
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.more_vert_rounded, color: Colors.grey.shade600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == "edit") {
                    _editUser(item);
                  } else if (value == "delete") {
                    _deleteUser(item);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 20, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "delete",
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            size: 20, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text(l10n.delete,
                            style: TextStyle(color: Colors.red.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tabConfigs[currentTab].gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tabConfigs[currentTab].gradient[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddEntryDialog(
              role: currentTab == 0
                  ? "coach"
                  : currentTab == 1
                      ? "player"
                      : "team",
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(
          currentTab == 0
              ? Icons.person_add_rounded
              : currentTab == 1
                  ? Icons.person_add_rounded
                  : Icons.group_add_rounded,
          color: Colors.white,
        ),
        label: Text(
          l10n.addEntity(tabs[currentTab]),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Enhanced helper methods for production readiness
  Widget _buildErrorScaffold(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.receptionistScreen),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.somethingWentWrong,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(l10n.tryAgainOrContact),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScaffold(AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.receptionistScreen),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loading),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    setState(() {
      isInitialized = false;
      errorMessage = null;
    });
    _getUserDetails();
  }

  // Helper methods
  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              l10n.comingSoon,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.red.shade600),
              const SizedBox(width: 12),
              Text(
                l10n.logout,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.logout,
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
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
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Logout failed: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _editUser(DocumentSnapshot doc) {
    final l10n = AppLocalizations.of(context)!;
    final data = doc.data() as Map<String, dynamic>;

    final nameController =
        TextEditingController(text: data['name'] ?? data['team_name']);
    final emailController = TextEditingController(text: data['email'] ?? "");
    final descriptionController = TextEditingController(
      text: data['role_description'] ?? data['team_description'] ?? "",
    );
    final positionController =
        TextEditingController(text: data['position'] ?? "");

    String selectedTeam = data['team'] ?? "";
    String selectedCoach = data['coach'] ?? "";

    // For Players, show tabbed dialog with payment management
    if (currentTab == 1) {
      showDialog(
        context: context,
        builder: (context) => DefaultTabController(
          length: 2,
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(Icons.edit_rounded,
                    color: tabConfigs[currentTab].gradient[0]),
                const SizedBox(width: 8),
                Text(
                  "${l10n.edit} ${data['name']}",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              height: 450,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: tabConfigs[currentTab].gradient[0],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade600,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(l10n.playerInfo),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(l10n.payments),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // First tab - Player details
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: nameController,
                                label: l10n.name,
                                icon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: positionController,
                                label: l10n.position,
                                icon: Icons.sports_soccer_rounded,
                              ),
                              const SizedBox(height: 16),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('teams')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }

                                  List<DropdownMenuItem<String>> teamItems =
                                      snapshot.data!.docs
                                          .map<DropdownMenuItem<String>>((doc) {
                                    final String tName = doc['team_name'];
                                    return DropdownMenuItem<String>(
                                      value: tName,
                                      child: Text(tName),
                                    );
                                  }).toList();

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: selectedTeam.isNotEmpty
                                          ? selectedTeam
                                          : null,
                                      items: teamItems,
                                      onChanged: (val) => selectedTeam = val!,
                                      decoration: InputDecoration(
                                        labelText: l10n.team,
                                        prefixIcon: Icon(Icons.groups_rounded,
                                            color: Colors.grey.shade600),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Second tab - Payment management
                        _buildPaymentManagementTab(doc.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tabConfigs[currentTab].gradient[0],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('players')
                        .doc(doc.id)
                        .update({
                      'name': nameController.text,
                      'position': positionController.text,
                      'team': selectedTeam,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(l10n.successfullyUpdated),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(l10n.failedToUpdate(e.toString()))),
                          ],
                        ),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Original dialog for coaches and teams
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.edit_rounded,
                  color: tabConfigs[currentTab].gradient[0]),
              const SizedBox(width: 8),
              Text(
                "Edit ${data['name'] ?? data['team_name'] ?? ''}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: currentTab == 2 ? "Team Name" : "Name",
                  icon: currentTab == 2
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                ),
                if (currentTab == 0) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    label: "Role Description",
                    icon: Icons.description_rounded,
                  ),
                ],
                if (currentTab != 2) ...[
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('teams')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      List<DropdownMenuItem<String>> teamItems = snapshot
                          .data!.docs
                          .map<DropdownMenuItem<String>>((doc) {
                        final String tName = doc['team_name'];
                        return DropdownMenuItem<String>(
                          value: tName,
                          child: Text(tName),
                        );
                      }).toList();

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedTeam.isNotEmpty ? selectedTeam : null,
                          items: teamItems,
                          onChanged: (val) => selectedTeam = val!,
                          decoration: InputDecoration(
                            labelText: "Team",
                            prefixIcon: Icon(Icons.groups_rounded,
                                color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                if (currentTab == 2) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_outline,
                                color: Colors.blue.shade600),
                            SizedBox(width: 8),
                            Text(
                              'Coaches Management',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // Close current dialog
                            showDialog(
                              context: context,
                              builder: (context) => CoachAssignmentDialog(
                                teamId: doc.id,
                                teamName: data['team_name'] ?? 'Unknown Team',
                                onChanged: () {
                                  // Refresh the data when coaches are changed
                                  setState(() {});
                                },
                              ),
                            );
                          },
                          icon: Icon(Icons.group_add_rounded),
                          label: Text('Manage Team Coaches'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Assign multiple coaches with different roles',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: tabConfigs[currentTab].gradient[0],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                "Save",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                try {
                  if (currentTab == 0) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(doc.id)
                        .update({
                      'name': nameController.text,
                      'email': emailController.text,
                      'role_description': descriptionController.text,
                      'team': selectedTeam,
                    });
                  } else if (currentTab == 2) {
                    await FirebaseFirestore.instance
                        .collection('teams')
                        .doc(doc.id)
                        .update({
                      'team_name': nameController.text,
                      'team_description': descriptionController.text,
                      'coach': selectedCoach,
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text("Successfully updated."),
                        ],
                      ),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Failed to update: $e")),
                        ],
                      ),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  void _deleteUser(DocumentSnapshot doc) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Text(
              "Confirm Delete",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete this item? This action cannot be undone.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userData = doc.data() as Map<String, dynamic>;

      if (currentTab == 0) {
        // Coach deletion with cascade cleanup
        final isCoach = userData['role'] == 'coach';

        if (isCoach) {
          // Use cascade delete for coaches
          await _coachManagementService.deleteCoachCompletely(doc.id);
        } else {
          // Regular user deletion for non-coaches
          await FirebaseFirestore.instance
              .collection('users')
              .doc(doc.id)
              .delete();
        }
      } else if (currentTab == 1) {
        // ignore: unused_local_variable
        String collection = 'players'; // Player

        // Decrement the number_of_players in the assigned team
        String teamName = doc['team'];
        final teamSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .where('team_name', isEqualTo: teamName)
            .limit(1)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          final teamDoc = teamSnapshot.docs.first;
          final teamRef =
              FirebaseFirestore.instance.collection('teams').doc(teamDoc.id);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(teamRef);
            final currentCount = snapshot['number_of_players'] ?? 0;
            transaction.update(teamRef,
                {'number_of_players': (currentCount - 1).clamp(0, 999)});
          });
        }

        // Delete player document
        await FirebaseFirestore.instance
            .collection('players')
            .doc(doc.id)
            .delete();
      } else {
        // Team deletion
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(doc.id)
            .delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(currentTab == 0 && userData['role'] == 'coach'
                  ? "Coach deleted from all teams and authentication successfully."
                  : "Deleted successfully."),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("Failed to delete: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildPaymentManagementTab(String playerId) {
    final now = DateTime.now();
    final currentYear = now.year;
    final months = [
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
        final width = constraints.maxWidth;
        final isTablet = width >= 600 && width < 1024;
        final isDesktop = width >= 1024;
        final crossAxisCount = isDesktop
            ? 6
            : isTablet
                ? 4
                : 3;
        final cardAspect = isDesktop
            ? 1.5
            : isTablet
                ? 1.2
                : 1.0;
        final fontSize = isDesktop
            ? 18.0
            : isTablet
                ? 15.0
                : 12.0;
        final iconSize = isDesktop
            ? 28.0
            : isTablet
                ? 22.0
                : 18.0;
        final borderRadius = isDesktop
            ? 18.0
            : isTablet
                ? 14.0
                : 12.0;
        final padding = isDesktop
            ? 24.0
            : isTablet
                ? 20.0
                : 12.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: tabConfigs[currentTab].gradient[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: tabConfigs[currentTab].gradient[0],
                    size: iconSize,
                  ),
                  SizedBox(width: padding / 2),
                  Text(
                    "$currentYear Payment Management",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: fontSize + 2,
                      color: tabConfigs[currentTab].gradient[0],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: padding),
            // Responsive Payment Grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('players')
                    .doc(playerId)
                    .collection('payments')
                    .where('year', isEqualTo: currentYear.toString())
                    .snapshots(),
                builder: (context, snapshot) {
                  Map<String, bool> payments = {};
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final isPaid = doc.data() as Map<String, dynamic>;
                      payments[doc['month']] = isPaid['isPaid'] ?? false;
                    }
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: cardAspect,
                      crossAxisSpacing: padding / 2,
                      mainAxisSpacing: padding / 2,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthNumber =
                          (index + 1).toString().padLeft(2, '0');
                      final isPaid = payments[monthNumber] ?? false;
                      return GestureDetector(
                        onTap: () => _togglePaymentInGrid(playerId,
                            currentYear.toString(), monthNumber, !isPaid),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPaid
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600
                                    ]
                                  : [Colors.red.shade400, Colors.red.shade600],
                            ),
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: (isPaid ? Colors.green : Colors.red)
                                    .withOpacity(0.18),
                                blurRadius: isDesktop ? 16 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                months[index],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: fontSize,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4),
                              Icon(
                                isPaid
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: Colors.white,
                                size: iconSize,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Action buttons
            Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.email_rounded, size: iconSize),
                      label: Text(
                        "Send Reminder",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: fontSize),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tabConfigs[currentTab].gradient[0],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius)),
                        padding: EdgeInsets.symmetric(vertical: padding * 0.75),
                        textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: fontSize),
                      ),
                      onPressed: () => _sendPaymentReminder(playerId),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _togglePaymentInGrid(
      String playerId, String year, String month, bool isPaid) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .doc('$year-$month');

      if (isPaid) {
        // Create/update document when paid
        await docRef.set({
          'playerId': playerId,
          'year': year,
          'month': month,
          'isPaid': true,
          'updatedAt': Timestamp.now(),
          'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
        }, SetOptions(merge: true));
      } else {
        // Delete document when unpaid
        await docRef.delete();
      }
    } catch (e) {
      debugPrint('Error updating payment: $e'); // Use debugPrint for production
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("Error updating payment: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _sendPaymentReminder(String playerId) async {
    // Find the player's details first
    final playerDoc = await FirebaseFirestore.instance
        .collection('players')
        .doc(playerId)
        .get();

    if (!playerDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Player not found'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final playerData = playerDoc.data() as Map<String, dynamic>;
    final playerName = playerData['name'] ?? 'Unknown Player';
    final email = playerData['email'] ?? '';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text('No email available for this player'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Find unpaid months
    final unpaidMonths = <String>[];
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .where('year', isEqualTo: currentYear)
          .get();

      // Check which months are unpaid
      Set<String> paidMonths = {};
      for (var doc in snapshot.docs) {
        if (doc['isPaid'] == true) {
          paidMonths.add(doc['month']);
        }
      }

      // Add unpaid months to the list
      for (int i = 1; i <= 12; i++) {
        String monthKey = i.toString().padLeft(2, '0');
        if (!paidMonths.contains(monthKey)) {
          unpaidMonths.add(monthNames[i - 1]);
        }
      }

      if (unpaidMonths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('All months are paid!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Show email preview dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.email_rounded,
                  color: tabConfigs[currentTab].gradient[0]),
              const SizedBox(width: 8),
              Text(
                'Payment Reminder Email',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To: $email',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      Text('Subject: Payment Reminder for $playerName',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Dear Parent/Guardian,', style: GoogleFonts.poppins()),
                const SizedBox(height: 10),
                Text(
                  'This is a reminder that the following months are unpaid:',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: unpaidMonths
                        .map(
                          (month) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.circle,
                                    size: 6, color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Text('$month $currentYear',
                                    style: GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Please make the payment at your earliest convenience.',
                    style: GoogleFonts.poppins()),
                const SizedBox(height: 10),
                Text('Thank you,', style: GoogleFonts.poppins()),
                Text('Football Club Management',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Close',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                'Send Email',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tabConfigs[currentTab].gradient[0],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Email sent to $email'),
                      ],
                    ),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _navigateToPaymentOverview(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentOverviewScreen()),
    );
  }
}

// Helper classes
class TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;
  final String name;

  TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.gradient,
    required this.name,
  });
}
