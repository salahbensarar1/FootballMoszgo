// File: lib/views/admin/user_management_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/admin/components/user_card.dart';
import 'package:footballtraining/views/admin/components/user_filters.dart';
import 'package:footballtraining/views/shared/widgets/empty_state_widget.dart';
import 'package:footballtraining/views/shared/widgets/error_state_widget.dart';
import 'package:footballtraining/views/shared/widgets/loading_state_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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
    Query query = _firestore.collection('users').orderBy('name');

    // Filter by role if selected
    if (selectedRoleFilter != null &&
        selectedRoleFilter!.isNotEmpty &&
        selectedRoleFilter != 'all') {
      query = query.where('role', isEqualTo: selectedRoleFilter);
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              UserFilters(
                searchController: _searchController,
                searchQuery: searchQuery,
                selectedRoleFilter: selectedRoleFilter,
                onSearchChanged: (value) => setState(() => searchQuery = value),
                onRoleFilterChanged: (role) =>
                    setState(() => selectedRoleFilter = role),
              ),
              Expanded(child: _buildUsersList(l10n)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildAddUserFab(l10n),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.manageUsers,
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
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: () => setState(() {}),
          tooltip: l10n.refresh,
        ),
      ],
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
          separatorBuilder: (context, index) => SizedBox(height: isMobile ? 8 : 12),
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
      return FloatingActionButton(
        onPressed: () => _addUser(l10n),
        backgroundColor: const Color(0xFFF27121),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_rounded),
        tooltip: l10n.add,
      );
    }
    
    return FloatingActionButton.extended(
      onPressed: () => _addUser(l10n),
      backgroundColor: const Color(0xFFF27121),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.person_add_rounded),
      label: Text(
        l10n.add,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ),
    );
  }
}
