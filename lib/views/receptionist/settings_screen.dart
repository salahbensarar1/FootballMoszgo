import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceptionistSettingsScreen extends StatefulWidget {
  const ReceptionistSettingsScreen({super.key});

  @override
  State<ReceptionistSettingsScreen> createState() =>
      _ReceptionistSettingsScreenState();
}

class _ReceptionistSettingsScreenState extends State<ReceptionistSettingsScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading states
  bool _isLoading = false;
  bool _isUpdatingPassword = false;

  // User data
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;

  // Form controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Settings state
  String _selectedLanguage = 'en';

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('organizations')
            .doc(OrganizationContext.currentOrgId)
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _userName = data['name'] ?? 'Receptionist';
            _userEmail = data['email'] ?? user.email;
            _profileImageUrl = data['picture'];
            _selectedLanguage = data['language'] ?? 'en';
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error loading user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('organizations')
            .doc(OrganizationContext.currentOrgId)
            .collection('users')
            .doc(user.uid)
            .update(updates);
        _showSuccessSnackBar('Settings updated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating settings: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    if (_newPasswordController.text.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters');
      return;
    }

    setState(() => _isUpdatingPassword = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);

        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        _showSuccessSnackBar('Password changed successfully!');
      }
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        _showErrorSnackBar('Current password is incorrect');
      } else {
        _showErrorSnackBar('Error changing password: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPassword = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: GoogleFonts.poppins())),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(l10n),
      body: _isLoading ? _buildLoadingState() : _buildBody(l10n, isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.settings,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppTheme.background,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.background),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(40),
            ),
            child: CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading settings...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader(l10n)),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 16,
              vertical: 8,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAccountSection(l10n),
                _buildAppPreferencesSection(l10n),
                _buildSupportAboutSection(l10n),
                _buildLogoutButton(l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.surface,
              backgroundImage: _profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(_profileImageUrl!)
                  : AssetImage('assets/images/default_profile.jpeg')
                      as ImageProvider,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? l10n.receptionist,
                  style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.background,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userEmail ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.background.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.success,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Online',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.background,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileDialog(l10n),
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.background.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_rounded, color: AppTheme.background, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                left: BorderSide(color: AppTheme.primary, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Account',
      icon: Icons.manage_accounts_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () => _showEditProfileDialog(l10n),
        ),
        Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
        _buildSettingsItem(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password',
          onTap: () => _showChangePasswordDialog(l10n),
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'App Settings',
      icon: Icons.tune_rounded,
      children: [
        _buildLanguageSelector(l10n),
      ],
    );
  }

  Widget _buildSupportAboutSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Support & About',
      icon: Icons.info_outline_rounded,
      children: [
        _buildSettingsItem(
          icon: Icons.support_agent,
          title: 'Contact Support',
          subtitle: 'Get help from our support team',
          onTap: () => _launchEmail(),
        ),
        Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
        _buildSettingsItem(
          icon: Icons.bug_report_outlined,
          title: 'Report a Bug',
          subtitle: 'Report issues or bugs',
          onTap: () => _launchEmail('Bug Report'),
        ),
        Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
        _buildSettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Our privacy policy',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
        _buildSettingsItem(
          icon: Icons.article_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 1, color: AppTheme.border, indent: 20, endIndent: 20),
        _buildSettingsItem(
          icon: Icons.info_outline,
          title: 'Version',
          subtitle: 'App version and build info',
          trailing: Text(
            'v1.0.0',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(l10n),
        icon: Icon(Icons.logout_rounded, color: AppTheme.error),
        label: Text(
          l10n.logout,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppTheme.primary,
                size: 22,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    return _buildSettingsItem(
      icon: Icons.language,
      title: 'Language',
      subtitle: _selectedLanguage == 'en' ? 'English' : 'Hungarian',
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        underline: SizedBox(),
        dropdownColor: AppTheme.surface,
        style: GoogleFonts.poppins(color: AppTheme.textPrimary),
        items: [
          DropdownMenuItem(
            value: 'en',
            child: Text('English', style: GoogleFonts.poppins()),
          ),
          DropdownMenuItem(
            value: 'hu',
            child: Text('Hungarian', style: GoogleFonts.poppins()),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedLanguage = value);
            _updateSettings({'language': value});
            _showSuccessSnackBar('Language changed successfully!');
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _isUpdatingPassword
                ? null
                : () {
                    Navigator.pop(context);
                    _changePassword();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUpdatingPassword
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(AppLocalizations l10n) {
    final nameController = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.poppins(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _userName = nameController.text);
              _updateSettings({'name': nameController.text});
              _showSuccessSnackBar('Profile updated successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.error),
            SizedBox(width: 12),
            Text(
              l10n.logout,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.confirmLogout,
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Text('Coming Soon!', style: GoogleFonts.poppins()),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _launchEmail([String? subject]) async {
    _showComingSoon();
  }
}
