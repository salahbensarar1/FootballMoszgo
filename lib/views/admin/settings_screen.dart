import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/main.dart'; // For language switching
import 'package:footballtraining/services/team_data_fixer_service.dart';
import 'package:footballtraining/views/admin/widgets/emergency_data_fix_button.dart';
import 'package:footballtraining/views/admin/widgets/coach_count_fix_button.dart';
import 'package:footballtraining/views/admin/widgets/coach_debug_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // User data
  String? userName;
  String? userEmail;
  String? profileImageUrl;
  bool isLoading = true;

  // Settings state
  bool isDarkMode = false;
  bool notificationsEnabled = true;
  String selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName = data['name'] ?? 'Admin';
          userEmail = data['email'] ?? user.email;
          profileImageUrl = data['picture'];
          isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          userName = 'Admin';
          userEmail = user.email ?? 'admin@example.com';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = 'Admin';
          userEmail = user.email ?? 'admin@example.com';
          isLoading = false;
        });
      }
    }
  }

  void _loadSettings() {
    setState(() {
      isDarkMode = Theme.of(context).brightness == Brightness.dark;
      // Load other settings...
    });
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileSection(l10n),
                SizedBox(height: 24),
                _buildAppearanceSection(l10n),
                SizedBox(height: 24),
                _buildNotificationSection(l10n),
                SizedBox(height: 24),
                _buildLanguageSection(l10n),
                SizedBox(height: 24),
                _buildSecuritySection(l10n),
                SizedBox(height: 24),
                _buildDeveloperSection(l10n),
                SizedBox(height: 24),
                _buildEmergencyFixSection(),
                SizedBox(height: 24),
                _buildAboutSection(l10n),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: Text(
        l10n.settings,
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
    );
  }

  Widget _buildProfileSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.account,
      icon: Icons.person_rounded,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Hero(
              tag: 'profile_avatar',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Color(0xFFF27121).withOpacity(0.2), width: 2),
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
                  backgroundImage: profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(profileImageUrl!)
                      : AssetImage('assets/images/admin.jpeg') as ImageProvider,
                ),
              ),
            ),
            title: Text(
              userName ?? l10n.loading,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.grey.shade800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  userEmail ?? l10n.loading,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFF27121).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.administrator,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF27121),
                    ),
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
            onTap: () => _editProfile(l10n),
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.appearance,
      icon: Icons.palette_rounded,
      children: [
        _buildSettingCard(
          icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          title: l10n.darkMode,
          subtitle: l10n.enableDarkModeForApp,
          trailing: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: isDarkMode ? Color(0xFFF27121) : Colors.grey.shade300,
            ),
            child: AnimatedAlign(
              duration: Duration(milliseconds: 200),
              alignment:
                  isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                margin: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 16,
                  color: isDarkMode ? Color(0xFFF27121) : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          onTap: () => _toggleDarkMode(),
        ),
      ],
    );
  }

  Widget _buildNotificationSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.notifications,
      icon: Icons.notifications_rounded,
      children: [
        _buildSettingCard(
          icon: Icons.notifications_active_rounded,
          title: l10n.systemNotifications,
          subtitle: 'Receive notifications about important events',
          trailing: Switch.adaptive(
            value: notificationsEnabled,
            onChanged: (value) => _toggleNotifications(value),
            activeColor: Color(0xFFF27121),
          ),
        ),
        SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.email_rounded,
          title: l10n.emailNotifications,
          subtitle: 'Get email updates about your team',
          onTap: () => _manageEmailNotifications(),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.languageAndRegion,
      icon: Icons.language_rounded,
      children: [
        _buildSettingCard(
          icon: Icons.translate_rounded,
          title: l10n.selectLanguage,
          subtitle: selectedLanguage == 'en' ? l10n.english : l10n.hungarian,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selectedLanguage == 'en' ? '🇺🇸' : '🇭🇺',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
          onTap: () => _showLanguageDialog(l10n),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.security,
      icon: Icons.security_rounded,
      children: [
        _buildSettingCard(
          icon: Icons.lock_rounded,
          title: l10n.changePassword,
          subtitle: l10n.updateAccountPassword,
          onTap: () => _changePassword(),
        ),
        SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.verified_user_rounded,
          title: l10n.twoFactorAuthentication,
          subtitle: l10n.addExtraSecurityLayer,
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.soon,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          onTap: () => _showComingSoon('Two-Factor Authentication'),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection(AppLocalizations l10n) {
    return _buildSection(
      title: "Developer Tools",
      icon: Icons.developer_mode,
      children: [
        _buildSettingCard(
          icon: Icons.build_rounded,
          title: "Team Data Fixer",
          subtitle: "Fix team coach assignment issues",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDataFixerWidget(),
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.bug_report_outlined,
          title: "Debug Information",
          subtitle: "View app and database diagnostics",
          onTap: () => _showComingSoon("Debug Information"),
        ),
      ],
    );
  }

  /// 🚨 EMERGENCY FIX SECTION - Critical data consistency fixes
  Widget _buildEmergencyFixSection() {
    return _buildSection(
      icon: Icons.warning_rounded,
      title: '🚨 EMERGENCY DATA FIX',
      children: [
        const EmergencyDataFixButton(),
        const CoachCountFixButton(),
        const CoachDebugButton(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outlined, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Fix',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fixes coach assignment inconsistencies between teams and users collections. '
                      'Resolves field name mismatches (userId vs coach_id) and ensures bidirectional sync.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return _buildSection(
      title: l10n.aboutThisApp,
      icon: Icons.info_rounded,
      children: [
        _buildSettingCard(
          icon: Icons.info_outline_rounded,
          title: 'App Information',
          subtitle: 'Version, developer info, and more',
          onTap: () => _showAboutDialog(l10n),
        ),
        SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.help_outline_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with using the app',
          onTap: () => _showHelpSupport(),
        ),
        SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          onTap: () => _showPrivacyPolicy(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFF27121).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFFF27121),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.grey.shade600,
                    size: 20,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: 12),
                  trailing,
                ] else if (onTap != null) ...[
                  SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Action methods
  void _editProfile(AppLocalizations l10n) {
    _showComingSoon('Profile editing');
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _showComingSoon('Dark mode switching');
  }

  void _toggleNotifications(bool value) {
    setState(() {
      notificationsEnabled = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notifications ${value ? 'enabled' : 'disabled'}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Color(0xFFF27121),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _manageEmailNotifications() {
    _showComingSoon('Email notification settings');
  }

  void _showLanguageDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Select Language',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('en', '🇺🇸', 'English'),
              SizedBox(height: 12),
              _buildLanguageOption('hu', '🇭🇺', 'Magyar'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String code, String flag, String name) {
    final isSelected = selectedLanguage == code;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFFF27121).withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: Color(0xFFF27121)) : null,
      ),
      child: ListTile(
        leading: Text(flag, style: TextStyle(fontSize: 24)),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Color(0xFFF27121) : Colors.grey.shade800,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Color(0xFFF27121))
            : null,
        onTap: () {
          setState(() {
            selectedLanguage = code;
          });
          Navigator.pop(context);
          MyApp.setLocale(context, Locale(code));
        },
      ),
    );
  }

  void _changePassword() {
    _showComingSoon('Password change');
  }

  void _showAboutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFF27121).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.sports_soccer_rounded,
                color: Color(0xFFF27121),
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'About App',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Football Training Management App',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Developed by Salah Ben Sarar\nKilousi KFT',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'A comprehensive solution for managing football training sessions, tracking player attendance, and organizing team activities.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Color(0xFFF27121)),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFFF27121)),
            SizedBox(width: 12),
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHelpOption(
              Icons.email_rounded,
              'Contact Support',
              'support@footballtraining.com',
              () => _contactSupport(),
            ),
            SizedBox(height: 12),
            _buildHelpOption(
              Icons.book_rounded,
              'User Guide',
              'Learn how to use the app',
              () => _openUserGuide(),
            ),
            SizedBox(height: 12),
            _buildHelpOption(
              Icons.bug_report_rounded,
              'Report a Bug',
              'Help us improve the app',
              () => _reportBug(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Color(0xFFF27121)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: Color(0xFFF27121)),
            SizedBox(width: 12),
            Text(
              'Privacy Policy',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Collection',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'We collect information necessary to provide our football training management services, including player data, training sessions, and attendance records.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'Data Security',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your data is stored securely using Firebase services with industry-standard encryption and security measures.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'Contact Information',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'For privacy concerns, contact us at privacy@footballtraining.com',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Color(0xFFF27121)),
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    Navigator.pop(context);
    _showComingSoon('Email support integration');
  }

  void _openUserGuide() {
    Navigator.pop(context);
    _showComingSoon('User guide');
  }

  void _reportBug() {
    Navigator.pop(context);
    _showComingSoon('Bug reporting');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFFF27121),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}
