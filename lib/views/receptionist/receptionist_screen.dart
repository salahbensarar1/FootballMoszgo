import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/views/receptionist/dialogs/add_entry_dialog.dart';
import 'package:footballtraining/views/receptionist/dialogs/coach_assignment_dialog.dart';
import 'package:footballtraining/views/receptionist/payment_overview_screen.dart';
import 'package:footballtraining/views/receptionist/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:footballtraining/views/shared/widgets/payment_month_indicator.dart';
import 'package:footballtraining/data/repositories/coach_management_service.dart';
import 'package:footballtraining/services/organization_context.dart';
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
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
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
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .snapshots();
    } else if (currentTab == 1) {
      return FirebaseFirestore.instance
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('players')
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('teams')
          .snapshots();
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceptionistSettingsScreen(),
                ),
              ),
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
              l10n.noEntitiesFound(tabs[currentTab]),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addSomeEntities(tabs[currentTab].toLowerCase()),
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
              l10n.noResultsFor(searchQuery),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryAdjustingSearch,
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
            l10n.confirmLogout,
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

  // Helper method to pick an image from gallery
  Future<File?> _pickImageFromGallery() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  // Helper method to upload an image to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
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
          .add(await http.MultipartFile.fromPath('file', imageFile.path));

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout. Please check your connection.');
        },
      );

      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        throw Exception(jsonData['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
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

    // State notifiers for image handling
    final profileImageUrl = ValueNotifier<String?>(data['picture']);
    final imageFile = ValueNotifier<File?>(null);
    final isUploading = ValueNotifier<bool>(false);

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
            content: SizedBox(
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
                              const Icon(Icons.person_rounded, size: 14),
                              SizedBox(
                                  width: ResponsiveUtils.isMobile(context)
                                      ? 5
                                      : 8),
                              Text(
                                l10n.playerInfo,
                                style: TextStyle(
                                    fontSize: ResponsiveUtils.isMobile(context)
                                        ? 12
                                        : 14),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                l10n.payments,
                                style: TextStyle(
                                    fontSize: ResponsiveUtils.isMobile(context)
                                        ? 12
                                        : 14),
                              ),
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
                                    .collection('organizations')
                                    .doc(OrganizationContext.currentOrgId)
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
                "${l10n.edit} ${data['name'] ?? data['team_name'] ?? ''}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentTab == 0) ...[
                  // Profile image UI for coaches
                  Center(
                    child: ValueListenableBuilder<String?>(
                      valueListenable: profileImageUrl,
                      builder: (context, url, _) {
                        return ValueListenableBuilder<File?>(
                          valueListenable: imageFile,
                          builder: (context, file, _) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    image: (file != null)
                                        ? DecorationImage(
                                            image: FileImage(file),
                                            fit: BoxFit.cover,
                                          )
                                        : (url != null)
                                            ? DecorationImage(
                                                image: NetworkImage(url),
                                                fit: BoxFit.cover,
                                              )
                                            : const DecorationImage(
                                                image: AssetImage(
                                                    'assets/images/default_profile.jpeg'),
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: isUploading,
                                    builder: (context, uploading, _) {
                                      return uploading
                                          ? CircularProgressIndicator()
                                          : InkWell(
                                              onTap: () async {
                                                final file =
                                                    await _pickImageFromGallery();
                                                if (file != null) {
                                                  imageFile.value = file;
                                                  isUploading.value = true;

                                                  final url =
                                                      await _uploadImageToCloudinary(
                                                          file);
                                                  isUploading.value = false;

                                                  if (url != null) {
                                                    profileImageUrl.value = url;
                                                  }
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: tabConfigs[currentTab]
                                                      .gradient[0],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildTextField(
                  controller: nameController,
                  label: currentTab == 2 ? l10n.teamName : l10n.name,
                  icon: currentTab == 2
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                ),
                if (currentTab == 0) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: emailController,
                    label: l10n.email,
                    icon: Icons.email_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: descriptionController,
                    label: l10n.roleDescription,
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
                            labelText: l10n.team,
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
                              l10n.coachesManagement,
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
                          label: Text(l10n.manageTeamCoaches),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.assignMultipleCoaches,
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
                  if (currentTab == 0) {
                    // For coaches, include profile image URL if changed
                    Map<String, dynamic> updateData = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'role_description': descriptionController.text,
                      'team': selectedTeam,
                    };

                    // Only add the picture field if we have a new image URL
                    if (profileImageUrl.value != data['picture']) {
                      updateData['picture'] = profileImageUrl.value;
                    }

                    await FirebaseFirestore.instance
                        .collection('organizations')
                        .doc(OrganizationContext.currentOrgId)
                        .collection('users')
                        .doc(doc.id)
                        .update(updateData);
                  } else if (currentTab == 2) {
                    await FirebaseFirestore.instance
                        .collection('organizations')
                        .doc(OrganizationContext.currentOrgId)
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
                          const Icon(Icons.error_outline, color: Colors.white),
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
              .collection('organizations')
              .doc(OrganizationContext.currentOrgId)
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
            .collection('organizations')
            .doc(OrganizationContext.currentOrgId)
            .collection('teams')
            .where('team_name', isEqualTo: teamName)
            .limit(1)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          final teamDoc = teamSnapshot.docs.first;
          final teamRef = FirebaseFirestore.instance
              .collection('organizations')
              .doc(OrganizationContext.currentOrgId)
              .collection('teams')
              .doc(teamDoc.id);

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

  /// 🔥 ENTERPRISE-GRADE: Responsive configuration for the payment grid
  /// Calculates optimal layout parameters based on device characteristics
  Map<String, dynamic> _calculateResponsiveLayout({
    required double screenWidth,
    required double screenHeight,
    required bool isLandscape,
    required double availableWidth,
    required double textScaleFactor,
    required double devicePixelRatio,
  }) {
    // 🔥 ADVANCED: Calculate effective screen real estate
    final isHighDensity = devicePixelRatio >= 3.0;
    final accessibilityScale = textScaleFactor.clamp(0.8, 1.4);

    // 🔥 DYNAMIC BREAKPOINTS: Based on actual usable space and device characteristics
    int crossAxisCount;
    double cardAspectRatio;
    double baseSpacing;

    if (availableWidth < 360) {
      // Small phones (iPhone SE, older Android)
      crossAxisCount = isLandscape ? 4 : 2;
      cardAspectRatio = isLandscape ? 1.4 : 1.1;
      baseSpacing = 8.0;
    } else if (availableWidth < 400) {
      // Medium phones (iPhone 12 mini, Pixel 4a)
      crossAxisCount = isLandscape ? 5 : 3;
      cardAspectRatio = isLandscape ? 1.3 : 1.0;
      baseSpacing = 10.0;
    } else if (availableWidth < 500) {
      // Large phones (iPhone 14 Pro Max, Pixel 6 Pro)
      crossAxisCount = isLandscape ? 5 : 3;
      cardAspectRatio = isLandscape ? 1.3 : 1.2;
      baseSpacing = 12.0;
    } else if (availableWidth < 700) {
      // Small tablets (iPad mini)
      crossAxisCount = isLandscape ? 6 : 4;
      cardAspectRatio = 1.3;
      baseSpacing = 14.0;
    } else if (availableWidth < 1000) {
      // Standard tablets (iPad)
      crossAxisCount = isLandscape ? 7 : 5;
      cardAspectRatio = 1.4;
      baseSpacing = 16.0;
    } else {
      // Large tablets/Desktop (iPad Pro 12.9")
      crossAxisCount = isLandscape ? 8 : 6;
      cardAspectRatio = 1.5;
      baseSpacing = 18.0;
    }

    // 🔥 ADAPTIVE SPACING: Scales with device size and density
    final scaledSpacing = baseSpacing * (isHighDensity ? 1.2 : 1.0);
    final deviceScale =
        (availableWidth / 360).clamp(0.8, 2.0); // Base scale from iPhone SE

    return {
      'crossAxisCount': crossAxisCount,
      'cardAspectRatio': cardAspectRatio,
      'paddingTiny': (scaledSpacing * 0.25 * deviceScale).clamp(2.0, 6.0),
      'paddingSmall': (scaledSpacing * 0.5 * deviceScale).clamp(4.0, 12.0),
      'paddingMedium': (scaledSpacing * 0.75 * deviceScale).clamp(8.0, 20.0),
      'paddingLarge': (scaledSpacing * 1.0 * deviceScale).clamp(12.0, 28.0),
      'gridSpacing': (scaledSpacing * 0.6 * deviceScale).clamp(6.0, 16.0),
      'titleFontSize':
          (16.0 * deviceScale * accessibilityScale).clamp(14.0, 24.0),
      'monthFontSize':
          (12.0 * deviceScale * accessibilityScale).clamp(10.0, 18.0),
      'buttonFontSize':
          (14.0 * deviceScale * accessibilityScale).clamp(12.0, 20.0),
      'iconSize': (18.0 * deviceScale).clamp(16.0, 32.0),
      'borderRadius': (8.0 * deviceScale).clamp(8.0, 20.0),
      'shadowBlur': isHighDensity ? 12.0 : 8.0,
      'shadowOffset': isHighDensity ? 3.0 : 2.0,
      'buttonVerticalPadding':
          (12.0 * deviceScale * accessibilityScale).clamp(10.0, 24.0),
    };
  }

  Widget _buildPaymentManagementTab(String playerId) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final currentYear = now.year;
    final months = [
      l10n.monthJan,
      l10n.monthFeb,
      l10n.monthMar,
      l10n.monthApr,
      l10n.monthMay,
      l10n.monthJun,
      l10n.monthJul,
      l10n.monthAug,
      l10n.monthSep,
      l10n.monthOct,
      l10n.monthNov,
      l10n.monthDec
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 🔥 SENIOR-LEVEL: Advanced responsive design using MediaQuery and device context
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final screenHeight = mediaQuery.size.height;
        final isLandscape = mediaQuery.orientation == Orientation.landscape;
        final devicePixelRatio = mediaQuery.devicePixelRatio;
        final textScaleFactor = mediaQuery.textScaler.scale(1.0);

        // 🔥 ENTERPRISE-GRADE: Dynamic breakpoints based on actual device capabilities
        final config = _calculateResponsiveLayout(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          isLandscape: isLandscape,
          availableWidth: constraints.maxWidth,
          textScaleFactor: textScaleFactor,
          devicePixelRatio: devicePixelRatio,
        );

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 RESPONSIVE HEADER with adaptive spacing
              Container(
                margin: EdgeInsets.all(config['paddingMedium']),
                padding: EdgeInsets.all(config['paddingLarge']),
                decoration: BoxDecoration(
                  color: tabConfigs[currentTab].gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(config['borderRadius']),
                  border: Border.all(
                    color: tabConfigs[currentTab].gradient[0].withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: tabConfigs[currentTab].gradient[0],
                      size: config['iconSize'],
                    ),
                    SizedBox(width: config['paddingMedium']),
                    Expanded(
                      child: Text(
                        "$currentYear Payment Management",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: config['titleFontSize'],
                          color: tabConfigs[currentTab].gradient[0],
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 RESPONSIVE PAYMENT GRID with optimized scrolling
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('players')
                      .doc(playerId)
                      .collection('payments')
                      .where('year', isEqualTo: currentYear.toString())
                      .snapshots(),
                  builder: (context, snapshot) {
                    // ENTERPRISE-GRADE: Store payment status with 3 states
                    Map<String, PaymentStatus> payments = {};
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final paymentData = doc.data() as Map<String, dynamic>;
                        final isPaid = paymentData['isPaid'] ?? false;
                        final isActive = paymentData['isActive'] ?? true;

                        // Determine 3-state payment status
                        PaymentStatus status;
                        if (!isActive) {
                          status = PaymentStatus.notActive; // Grey - Not Active
                        } else if (isPaid) {
                          status = PaymentStatus.paid; // Green - Paid
                        } else {
                          status = PaymentStatus.unpaid; // Red - Unpaid
                        }

                        payments[doc['month']] = status;
                      }
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: config['paddingMedium']),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(config['paddingSmall']),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: config['crossAxisCount'],
                          childAspectRatio: config['cardAspectRatio'],
                          crossAxisSpacing: config['gridSpacing'],
                          mainAxisSpacing: config['gridSpacing'],
                        ),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final monthNumber =
                              (index + 1).toString().padLeft(2, '0');
                          final paymentStatus =
                              payments[monthNumber] ?? PaymentStatus.unpaid;
                          final statusColors =
                              _getGridStatusColors(paymentStatus);

                          return GestureDetector(
                            onTap: () => _togglePaymentStatusInGrid(
                                playerId,
                                currentYear.toString(),
                                monthNumber,
                                paymentStatus),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: statusColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(
                                    config['borderRadius']),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        statusColors[0].withValues(alpha: 0.25),
                                    blurRadius: config['shadowBlur'],
                                    offset: Offset(0, config['shadowOffset']),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: EdgeInsets.all(config['paddingSmall']),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        months[index],
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: config['monthFontSize'],
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(height: config['paddingTiny']),
                                    Icon(
                                      paymentStatus == PaymentStatus.paid
                                          ? Icons.check_circle_rounded
                                          : paymentStatus ==
                                                  PaymentStatus.notActive
                                              ? Icons
                                                  .remove_circle_outline_rounded
                                              : Icons.cancel_rounded,
                                      color: Colors.white,
                                      size: config['iconSize'],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // 🔥 RESPONSIVE ACTION BUTTONS with adaptive sizing
              Container(
                margin: EdgeInsets.all(config['paddingMedium']),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.email_rounded, size: config['iconSize']),
                    label: Text(
                      "Send Reminder",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: config['buttonFontSize'],
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tabConfigs[currentTab].gradient[0],
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor:
                          tabConfigs[currentTab].gradient[0].withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(config['borderRadius']),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: config['buttonVerticalPadding'],
                        horizontal: config['paddingLarge'],
                      ),
                    ),
                    onPressed: () => _sendPaymentReminder(playerId),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced method to cycle through all 3 payment states
  Future<void> _togglePaymentStatusInGrid(String playerId, String year,
      String month, PaymentStatus currentStatus) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('players')
          .doc(playerId)
          .collection('payments')
          .doc('$year-$month');

      // Cycle through states: unpaid → paid → notActive → unpaid
      switch (currentStatus) {
        case PaymentStatus.unpaid:
          // unpaid (red) → paid (green)
          await docRef.set({
            'playerId': playerId,
            'year': year,
            'month': month,
            'isPaid': true,
            'isActive': true,
            'updatedAt': Timestamp.now(),
            'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          }, SetOptions(merge: true));
          break;
        case PaymentStatus.paid:
          // paid (green) → notActive (grey)
          await docRef.set({
            'playerId': playerId,
            'year': year,
            'month': month,
            'isPaid': false,
            'isActive': false, // Set to inactive (grey)
            'updatedAt': Timestamp.now(),
            'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          }, SetOptions(merge: true));
          break;
        case PaymentStatus.notActive:
          // notActive (grey) → unpaid (red)
          await docRef.set({
            'playerId': playerId,
            'year': year,
            'month': month,
            'isPaid': false,
            'isActive': true, // Back to active but unpaid
            'updatedAt': Timestamp.now(),
            'updatedBy': FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          }, SetOptions(merge: true));
          break;
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      if (mounted) {
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
  }

  Future<void> _sendPaymentReminder(String playerId) async {
    final l10n = AppLocalizations.of(context)!;

    // Find the player's details first
    final playerDoc = await FirebaseFirestore.instance
        .collection('players')
        .doc(playerId)
        .get();

    if (!playerDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.playerNotFound),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final playerData = playerDoc.data() as Map<String, dynamic>;
    final playerName = playerData['name'] ?? 'Unknown Player';
    final email = playerData['email'] ?? '';

    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(l10n.noEmailAvailable),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Find unpaid months
    final unpaidMonths = <String>[];
    final now = DateTime.now();
    final currentYear = now.year.toString();
    final monthNames = [
      l10n.monthJanuary,
      l10n.monthFebruary,
      l10n.monthMarch,
      l10n.monthApril,
      l10n.monthMayFull,
      l10n.monthJune,
      l10n.monthJuly,
      l10n.monthAugust,
      l10n.monthSeptember,
      l10n.monthOctober,
      l10n.monthNovember,
      l10n.monthDecember
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(l10n.allMonthsPaid),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      // Show email preview dialog
      if (mounted) {
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
                  l10n.paymentReminderEmail,
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
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                        Text('Subject: Payment Reminder for $playerName',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.dearParentGuardian,
                      style: GoogleFonts.poppins()),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.reminderUnpaidMonths,
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
                  Text(AppLocalizations.of(context)!.pleasePayEarliest,
                      style: GoogleFonts.poppins()),
                  const SizedBox(height: 10),
                  Text(AppLocalizations.of(context)!.thankYou,
                      style: GoogleFonts.poppins()),
                  Text(AppLocalizations.of(context)!.footballClubManagement,
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
      }
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

// Payment status enum for grid
enum PaymentStatus { paid, unpaid, notActive }

// Helper to get color gradients for payment status grid
List<Color> _getGridStatusColors(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.paid:
      return [Colors.green.shade400, Colors.green.shade700];
    case PaymentStatus.unpaid:
      return [Colors.red.shade400, Colors.red.shade700];
    case PaymentStatus.notActive:
      return [Colors.grey.shade400, Colors.grey.shade600];
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
