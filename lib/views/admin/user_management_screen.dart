// File: lib/views/admin/user_management_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/views/admin/components/user_card.dart';
import 'package:footballtraining/views/admin/components/user_filters.dart';
import 'package:footballtraining/views/shared/widgets/empty_state_widget.dart';
import 'package:footballtraining/views/shared/widgets/error_state_widget.dart';
import 'package:footballtraining/views/shared/widgets/loading_state_widget.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:footballtraining/core/painters/pitch_painter.dart';

// Import components
import 'package:footballtraining/views/admin/dialogs/add_user_dialog.dart';
import 'package:footballtraining/views/admin/dialogs/edit_user_dialog.dart';
import 'package:footballtraining/views/admin/dialogs/delete_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  String searchQuery = "";
  String? selectedRoleFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(_handleSearchChange);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _handleSearchChange() {
    if (_searchController.text.isEmpty && searchQuery.isNotEmpty) {
      setState(() {
        searchQuery = "";
      });
    }
  }

  Stream<QuerySnapshot> _getUsersStream() {
    Query query = _firestore
        .collection('organizations')
        .doc(OrganizationContext.currentOrgId)
        .collection('users')
        .orderBy('name');

    // Filter by role if selected
    if (selectedRoleFilter != null &&
        selectedRoleFilter!.isNotEmpty &&
        selectedRoleFilter != 'all') {
      // Try multiple case variations
      final List<String> roleVariations = [
        selectedRoleFilter!.toLowerCase(),
        selectedRoleFilter!.toUpperCase(),
        '${selectedRoleFilter![0].toUpperCase()}${selectedRoleFilter!.substring(1).toLowerCase()}',
      ];

      query = query.where('role', whereIn: roleVariations);
    }

    // Apply search query
    if (searchQuery.isNotEmpty) {
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQuery)
          .where('name', isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    ScreenConfig.init(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: false,
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(l10n),
      body: Stack(
        children: [
          // Background pitch pattern
          CustomPaint(
            painter: PitchLinePainter(
              lineColor: AppTheme.primary.withValues(alpha: 0.02),
            ),
            size: Size.infinite,
          ),

          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Premium header section with stats
                  _buildHeaderSection(l10n),

                  // Filters section
                  UserFilters(
                    searchController: _searchController,
                    searchQuery: searchQuery,
                    selectedRoleFilter: selectedRoleFilter,
                    onSearchChanged: (value) =>
                        setState(() => searchQuery = value),
                    onRoleFilterChanged: (role) =>
                        setState(() => selectedRoleFilter = role),
                  ),

                  // Users list
                  Expanded(child: _buildUsersList(l10n)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAddUserFab(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      title: Text(
        l10n.manageUsers,
        style: AppTheme.heading2.copyWith(
          color: AppTheme.background,
          fontSize: 22,
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          boxShadow: AppTheme.cardShadow,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppTheme.background, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.background, size: 22),
            onPressed: () => setState(() {}),
            tooltip: l10n.refresh,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(AppLocalizations l10n) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('organizations')
          .doc(OrganizationContext.currentOrgId)
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        // Count stats
        int totalUsers = 0;
        int coaches = 0;
        int receptionists = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final users = snapshot.data!.docs;
          totalUsers = users.length;

          for (var doc in users) {
            final role = doc.data() as Map<String, dynamic>?;
            final userRole = role?['role']?.toString().toLowerCase() ?? '';

            if (userRole.contains('coach')) coaches++;
            if (userRole.contains('receptionist')) receptionists++;
          }
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: ScreenConfig.cardPadding,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: Row(
            children: [
              // Main stat
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Users',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.background.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedCounter(
                      target: totalUsers,
                      style: AppTheme.heading1.copyWith(
                        color: AppTheme.background,
                        fontSize: ScreenConfig.fontXXL,
                      ),
                    ),
                  ],
                ),
              ),

              // Role breakdown
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleStatChip(
                        'Coaches', coaches.toString(), Icons.sports),
                    _buildRoleStatChip(
                        'Staff', receptionists.toString(), Icons.badge),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.background.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.background, size: 18),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.background,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.background.withValues(alpha: 0.8),
              fontSize: ScreenConfig.fontS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isMobile = size.width < 480;

    return StreamBuilder<QuerySnapshot>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget();
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            error: snapshot.error.toString(),
            onRetry: () => setState(() {}),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            searchQuery: '',
            entityName: 'users',
          );
        }

        // Filter out current admin
        final currentAdminUid = _auth.currentUser?.uid;
        final users = snapshot.data!.docs
            .where((doc) => doc.id != currentAdminUid)
            .toList();

        if (users.isEmpty) {
          return EmptyStateWidget(
            searchQuery: searchQuery,
            entityName: 'users',
          );
        }

        if (isTablet) {
          // Grid layout for tablets
          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return UserCard(
                  userDoc: users[index],
                  onEdit: () => _editUser(users[index], l10n),
                  onDelete: () => _deleteUser(users[index], l10n),
                );
              },
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          itemCount: users.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: isMobile ? 8 : 12),
          itemBuilder: (context, index) {
            return UserCard(
              userDoc: users[index],
              onEdit: () => _editUser(users[index], l10n),
              onDelete: () => _deleteUser(users[index], l10n),
            );
          },
        );
      },
    );
  }

  Widget _buildAddUserFab(AppLocalizations l10n) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 480;

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.primaryShadow,
        ),
        child: FloatingActionButton(
          onPressed: () => _addUser(l10n),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.background,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.person_add_rounded, size: 24),
          tooltip: l10n.add,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _addUser(l10n),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.person_add_rounded, size: 22),
        label: Text(
          l10n.add,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // Action methods
  void _editUser(DocumentSnapshot userDoc, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => EditUserDialog(
        userDoc: userDoc,
        l10n: l10n,
        onUserUpdated: () => setState(() {}),
      ),
    );
  }

  void _deleteUser(DocumentSnapshot userDoc, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => DeleteUserDialog(
        userDoc: userDoc,
        onUserDeleted: () => setState(() {}),
      ),
    );
  }

  void _addUser(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AddUserDialog(
        l10n: l10n,
        onUserAdded: () => setState(() {}),
        organizationId: OrganizationContext.currentOrgId,
      ),
    );
  }
}
