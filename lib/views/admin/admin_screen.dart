import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/admin/reports/player_report_screen.dart';
import 'package:footballtraining/views/admin/reports/session_report_screen.dart';
import 'package:footballtraining/views/admin/reports/team_report_screen.dart';
import 'package:footballtraining/views/dashboard/dashboard_screen.dart';
import 'package:footballtraining/views/login/login_page.dart';

import 'package:footballtraining/views/admin/user_management_screen.dart';
import 'package:footballtraining/views/admin/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // UI State
  String searchQuery = "";
  int currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // User data
  String? userName;
  String? email;
  String? profileImageUrl;

  // Loading states
  bool isLoading = false;
  String? errorMessage;

  // Tab configuration
  final List<TabConfig> tabConfigs = [
    TabConfig(
      icon: Icons.event_available,
      activeIcon: Icons.event_available,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    TabConfig(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    TabConfig(
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _getUserDetails();
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        currentTab = _tabController.index;
        searchQuery = "";
        _searchController.clear();
      });
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
    final user = _auth.currentUser;
    if (user?.uid == null) return;

    setState(() => isLoading = true);

    try {
      final doc = await _firestore.collection('users').doc(user!.uid).get();
      if (mounted) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            userName = data['name'] ?? 'Admin';
            email = data['email'] ?? user.email;
            profileImageUrl = data['picture'];
            isLoading = false;
          });
        } else {
          setState(() {
            userName = "Admin";
            email = user.email ?? "admin@example.com";
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
          isLoading = false;
        });
      }
    }
  }

  Stream<QuerySnapshot> _getStreamForCurrentTab(AppLocalizations l10n) {
    Query query;

    switch (currentTab) {
      case 0: // Training Sessions
        query = _firestore
            .collection('training_sessions')
            .orderBy('start_time', descending: true);
        if (searchQuery.isNotEmpty) {
          query = query
              .where('team', isGreaterThanOrEqualTo: searchQuery)
              .where('team', isLessThanOrEqualTo: '$searchQuery\uf8ff');
        }
        break;
      case 1: // Players
        query = _firestore.collection('players');
        if (searchQuery.isNotEmpty) {
          query = query
              .where('name', isGreaterThanOrEqualTo: searchQuery)
              .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy('name');
        } else {
          query = query.orderBy('name');
        }
        break;
      case 2: // Teams
        query = _firestore.collection('teams');
        if (searchQuery.isNotEmpty) {
          query = query
              .where('team_name', isGreaterThanOrEqualTo: searchQuery)
              .where('team_name', isLessThanOrEqualTo: '$searchQuery\uf8ff')
              .orderBy('team_name');
        } else {
          query = query.orderBy('team_name');
        }
        break;
      default:
        return const Stream.empty();
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    final tabs = [l10n.attendances, l10n.players, l10n.teams];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      drawer: _buildDrawer(l10n),
      body: Column(
        children: [
          _buildTabBar(l10n, tabs),
          _buildSearchBar(l10n, tabs),
          Expanded(child: _buildContent(l10n)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.adminScreen,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF27121), Color(0xFFFF8A50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () => setState(() {}),
          tooltip: 'Refresh',
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
                    icon: Icons.dashboard_rounded,
                    title: l10n.dashboardOverview,
                    onTap: () => _navigateToScreen(context, DashboardScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_alt_rounded,
                    title: l10n.manageUsers,
                    onTap: () =>
                        _navigateToScreen(context, UserManagementScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: "Reports",
                    onTap: () => _showComingSoon(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications_rounded,
                    title: "Notifications",
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: l10n.settings,
              onTap: () => _navigateToScreen(context, SettingsScreen()),
            ),
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: l10n.logout,
              textColor: Colors.red.shade600,
              iconColor: Colors.red.shade600,
              onTap: () => _showLogoutDialog(context, l10n),
            ),
            SizedBox(height: 20), // Add padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF27121), Color(0xFFFF8A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'admin_avatar',
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
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl?.isNotEmpty == true
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage('assets/images/admin.jpeg')
                            as ImageProvider,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                userName ?? l10n.adminScreen,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                email ?? "admin@example.com",
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
          color: (iconColor ?? Color(0xFFF27121)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Color(0xFFF27121),
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
        Icons.chevron_right,
        color: Colors.grey.shade400,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n, List<String> tabs) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
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
                offset: Offset(0, 4),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(horizontal: 8),
          tabs: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            final isActive = currentTab == index;

            return Tab(
              height: 50,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? tabConfigs[index].activeIcon
                          : tabConfigs[index].icon,
                      size: 20,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? Colors.white : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, List<String> tabs) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
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
              margin: EdgeInsets.all(12),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF27121).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFFF27121),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStreamForCurrentTab(l10n),
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

        final items = snapshot.data!.docs;
        return _buildItemsList(items, l10n);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFFF27121).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: CircularProgressIndicator(
              color: Color(0xFFF27121),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading...',
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
        padding: EdgeInsets.all(32),
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
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please try again or contact support',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF27121),
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
    final tabs = [l10n.attendances, l10n.players, l10n.teams];
    final icons = [
      Icons.event_note_rounded,
      Icons.people_rounded,
      Icons.groups_rounded
    ];

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
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
            SizedBox(height: 24),
            Text(
              searchQuery.isEmpty
                  ? 'No ${tabs[currentTab]} found'
                  : 'No results for "$searchQuery"',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(List<DocumentSnapshot> items, AppLocalizations l10n) {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        switch (currentTab) {
          case 0:
            return _buildTrainingSessionCard(item, l10n);
          case 1:
            return _buildPlayerCard(item, l10n);
          case 2:
            return _buildTeamCard(item, l10n);
          default:
            return SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildTrainingSessionCard(
      DocumentSnapshot sessionDoc, AppLocalizations l10n) {
    final data = sessionDoc.data() as Map<String, dynamic>? ?? {};

    final teamName = data['team'] ?? 'N/A';
    final trainingType = data['training_type'] ?? 'N/A';
    final coachName = data['coach_name'] ?? 'Unknown Coach';
    final startTime = data['start_time'] as Timestamp?;

    String dateStr = 'No Date';
    String timeStr = '';
    if (startTime != null) {
      dateStr = DateFormat('EEE, dd MMM').format(startTime.toDate());
      timeStr = DateFormat('HH:mm').format(startTime.toDate());
    }

    int attendeeCount = 0;
    int totalPlayers = 0;
    final playersList = data['players'] as List<dynamic>?;
    if (playersList != null) {
      totalPlayers = playersList.length;
      attendeeCount = playersList
          .where((p) => (p as Map<String, dynamic>?)?['present'] == true)
          .length;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionReportScreen(sessionDoc: sessionDoc),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$teamName - $trainingType',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      coachName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$dateStr at $timeStr',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: attendeeCount > 0
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '$attendeeCount/$totalPlayers',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: attendeeCount > 0
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    Text(
                      'Present',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(DocumentSnapshot playerDoc, AppLocalizations l10n) {
    final data = playerDoc.data() as Map<String, dynamic>? ?? {};

    final name = data['name'] ?? 'No Name';
    final position = data['position'] ?? 'N/A';
    final teamName = data['team'] ?? 'No Team';
    final pictureUrl = data['picture'] as String?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerReportScreen(playerDoc: playerDoc),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Hero(
                tag: 'player_${playerDoc.id}',
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: (pictureUrl?.isNotEmpty == true)
                        ? NetworkImage(pictureUrl!)
                        : AssetImage("assets/images/default_profile.jpeg")
                            as ImageProvider,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            position,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            teamName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(DocumentSnapshot teamDoc, AppLocalizations l10n) {
    final data = teamDoc.data() as Map<String, dynamic>? ?? {};

    final teamName = data['team_name'] ?? 'No Team Name';
    final playerCount = data['number_of_players'] ?? 0;
    final teamDescription = data['team_description'] ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TeamReportScreen(teamDoc: teamDoc)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (teamDescription.isNotEmpty) ...[
                      Text(
                        teamDescription,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '$playerCount ${l10n.players}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: playerCount > 0
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$playerCount',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: playerCount > 0
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showComingSoon(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Coming Soon!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFFF27121),
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
              SizedBox(width: 12),
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
                    borderRadius: BorderRadius.circular(12)),
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
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Helper classes
class TabConfig {
  final IconData icon;
  final IconData activeIcon;
  final List<Color> gradient;

  TabConfig({
    required this.icon,
    required this.activeIcon,
    required this.gradient,
  });
}

class DrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
