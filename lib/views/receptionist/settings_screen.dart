import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceptionistSettingsScreen extends StatefulWidget {
  const ReceptionistSettingsScreen({super.key});

  @override
  State<ReceptionistSettingsScreen> createState() => _ReceptionistSettingsScreenState();
}

class _ReceptionistSettingsScreenState extends State<ReceptionistSettingsScreen> with TickerProviderStateMixin {
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
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _paymentReminders = true;
  bool _newPlayerAlerts = false;
  bool _systemUpdates = true;
  bool _marketingEmails = false;
  String _reminderFrequency = 'weekly';
  bool _autoBackup = true;
  String _dateFormat = 'dd/MM/yyyy';
  String _timeFormat = '24';
  
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
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _userName = data['name'] ?? 'Receptionist';
            _userEmail = data['email'] ?? user.email;
            _profileImageUrl = data['picture'];
            _selectedLanguage = data['language'] ?? 'en';
            _emailNotifications = data['emailNotifications'] ?? true;
            _pushNotifications = data['pushNotifications'] ?? true;
            _paymentReminders = data['paymentReminders'] ?? true;
            _newPlayerAlerts = data['newPlayerAlerts'] ?? false;
            _systemUpdates = data['systemUpdates'] ?? true;
            _marketingEmails = data['marketingEmails'] ?? false;
            _reminderFrequency = data['reminderFrequency'] ?? 'weekly';
            _autoBackup = data['autoBackup'] ?? true;
            _dateFormat = data['dateFormat'] ?? 'dd/MM/yyyy';
            _timeFormat = data['timeFormat'] ?? '24';
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
        await _firestore.collection('users').doc(user.uid).update(updates);
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(l10n),
      body: _isLoading ? _buildLoadingState() : _buildBody(l10n, isTablet),
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
          color: Colors.white,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
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
              color: Color(0xFFF27121).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: CircularProgressIndicator(
              color: Color(0xFFF27121),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading settings...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
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
                SizedBox(height: 20),
                _buildAppPreferencesSection(l10n),
                SizedBox(height: 20),
                _buildNotificationSection(l10n),
                SizedBox(height: 20),
                _buildPaymentPreferencesSection(l10n),
                SizedBox(height: 20),
                _buildSecuritySection(l10n),
                SizedBox(height: 20),
                _buildHelpSupportSection(l10n),
                SizedBox(height: 20),
                _buildAboutSection(l10n),
                SizedBox(height: 20),
                _buildDangerZoneSection(l10n),
                SizedBox(height: 32),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'receptionist_avatar',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFF27121), Color(0xFFFF8A50)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFF27121).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundColor: Colors.transparent,
                backgroundImage: _profileImageUrl?.isNotEmpty == true
                    ? NetworkImage(_profileImageUrl!)
                    : AssetImage('assets/images/receptionist.jpeg') as ImageProvider,
              ),
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName ?? l10n.receptionist,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userEmail ?? 'receptionist@example.com',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Online',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfileDialog(l10n),
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF27121).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.edit,
                color: Color(0xFFF27121),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Account Settings',
      icon: Icons.account_circle,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      children: [
        _buildSettingsItem(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Update your password',
          onTap: () => _showChangePasswordDialog(l10n),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () => _showEditProfileDialog(l10n),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.camera_alt_outlined,
          title: 'Update Profile Picture',
          subtitle: 'Change your profile picture',
          onTap: () => _showComingSoon(),
        ),
      ],
    );
  }

  Widget _buildAppPreferencesSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'App Preferences',
      icon: Icons.settings,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      children: [
        _buildLanguageSelector(l10n),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildDateFormatSelector(l10n),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildTimeFormatSelector(l10n),
      ],
    );
  }

  Widget _buildNotificationSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Notification Settings',
      icon: Icons.notifications_outlined,
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      children: [
        _buildSwitchItem(
          title: 'Email Notifications',
          subtitle: 'Receive notifications via email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() => _emailNotifications = value);
            _updateSettings({'emailNotifications': value});
          },
        ),
        _buildSwitchItem(
          title: 'Push Notifications',
          subtitle: 'Receive push notifications',
          value: _pushNotifications,
          onChanged: (value) {
            setState(() => _pushNotifications = value);
            _updateSettings({'pushNotifications': value});
          },
        ),
        _buildSwitchItem(
          title: 'Payment Reminders',
          subtitle: 'Get notified about payment updates',
          value: _paymentReminders,
          onChanged: (value) {
            setState(() => _paymentReminders = value);
            _updateSettings({'paymentReminders': value});
          },
        ),
        _buildSwitchItem(
          title: 'New Player Alerts',
          subtitle: 'Notifications for new player registrations',
          value: _newPlayerAlerts,
          onChanged: (value) {
            setState(() => _newPlayerAlerts = value);
            _updateSettings({'newPlayerAlerts': value});
          },
        ),
        _buildSwitchItem(
          title: 'System Updates',
          subtitle: 'Important system and app updates',
          value: _systemUpdates,
          onChanged: (value) {
            setState(() => _systemUpdates = value);
            _updateSettings({'systemUpdates': value});
          },
        ),
        _buildSwitchItem(
          title: 'Marketing Emails',
          subtitle: 'Promotional emails and newsletters',
          value: _marketingEmails,
          onChanged: (value) {
            setState(() => _marketingEmails = value);
            _updateSettings({'marketingEmails': value});
          },
        ),
      ],
    );
  }

  Widget _buildPaymentPreferencesSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Payment Preferences',
      icon: Icons.payment,
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      children: [
        _buildSettingsItem(
          icon: Icons.attach_money,
          title: 'Default Currency',
          subtitle: 'Hungarian Forint (HUF)',
          trailing: Text(
            'HUF',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Color(0xFFEC4899),
            ),
          ),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildReminderFrequencySelector(l10n),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSwitchItem(
          title: 'Auto Backup',
          subtitle: 'Automatically backup payment data',
          value: _autoBackup,
          onChanged: (value) {
            setState(() => _autoBackup = value);
            _updateSettings({'autoBackup': value});
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Security & Privacy',
      icon: Icons.security,
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      children: [
        _buildSettingsItem(
          icon: Icons.history,
          title: 'Login History',
          subtitle: 'View your recent login activity',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.verified_user_outlined,
          title: 'Two-Factor Authentication',
          subtitle: 'Add an extra layer of security',
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Soon',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Settings',
          subtitle: 'Control your data privacy',
          onTap: () => _showComingSoon(),
        ),
      ],
    );
  }

  Widget _buildHelpSupportSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Help & Support',
      icon: Icons.help_outline,
      gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      children: [
        _buildSettingsItem(
          icon: Icons.quiz_outlined,
          title: 'FAQ',
          subtitle: 'Frequently asked questions',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.support_agent,
          title: 'Contact Support',
          subtitle: 'Get help from our support team',
          onTap: () => _launchEmail(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.school_outlined,
          title: 'Tutorials',
          subtitle: 'Learn how to use the app',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.bug_report_outlined,
          title: 'Report Bug',
          subtitle: 'Report issues or bugs',
          onTap: () => _launchEmail('Bug Report'),
        ),
      ],
    );
  }

  Widget _buildAboutSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'About App',
      icon: Icons.info_outline,
      gradient: [Color(0xFF64748B), Color(0xFF475569)],
      children: [
        _buildSettingsItem(
          icon: Icons.info,
          title: 'Version',
          subtitle: 'App version and build info',
          trailing: Text(
            'v1.0.0',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.article_outlined,
          title: 'Terms of Service',
          subtitle: 'Read our terms of service',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Our privacy policy',
          onTap: () => _showComingSoon(),
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.code,
          title: 'Licenses',
          subtitle: 'Open source licenses',
          onTap: () => _showComingSoon(),
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(AppLocalizations l10n) {
    return _buildSectionCard(
      title: 'Danger Zone',
      icon: Icons.warning_outlined,
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
      children: [
        _buildSettingsItem(
          icon: Icons.logout,
          title: 'Logout All Devices',
          subtitle: 'Sign out from all devices',
          onTap: () => _showLogoutAllDialog(l10n),
          titleColor: Colors.red.shade700,
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.delete_sweep,
          title: 'Clear Cache',
          subtitle: 'Clear app cache and temporary files',
          onTap: () => _showComingSoon(),
          titleColor: Colors.red.shade700,
        ),
        Divider(height: 32, color: Colors.grey.shade200),
        _buildSettingsItem(
          icon: Icons.restore,
          title: 'Reset Settings',
          subtitle: 'Reset all settings to default',
          onTap: () => _showResetSettingsDialog(l10n),
          titleColor: Colors.red.shade700,
        ),
      ],
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
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (titleColor ?? Color(0xFFF27121)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: titleColor ?? Color(0xFFF27121),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Colors.grey.shade800,
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
            trailing ?? Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
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
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFFF27121),
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
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

  Widget _buildDateFormatSelector(AppLocalizations l10n) {
    final formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
    return _buildSettingsItem(
      icon: Icons.calendar_today,
      title: 'Date Format',
      subtitle: _dateFormat,
      trailing: DropdownButton<String>(
        value: _dateFormat,
        underline: SizedBox(),
        items: formats.map((format) => DropdownMenuItem(
          value: format,
          child: Text(format, style: GoogleFonts.poppins(fontSize: 14)),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _dateFormat = value);
            _updateSettings({'dateFormat': value});
          }
        },
      ),
    );
  }

  Widget _buildTimeFormatSelector(AppLocalizations l10n) {
    return _buildSettingsItem(
      icon: Icons.access_time,
      title: 'Time Format',
      subtitle: _timeFormat == '24' ? '24-hour' : '12-hour',
      trailing: DropdownButton<String>(
        value: _timeFormat,
        underline: SizedBox(),
        items: [
          DropdownMenuItem(
            value: '12',
            child: Text('12-hour', style: GoogleFonts.poppins()),
          ),
          DropdownMenuItem(
            value: '24',
            child: Text('24-hour', style: GoogleFonts.poppins()),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _timeFormat = value);
            _updateSettings({'timeFormat': value});
          }
        },
      ),
    );
  }

  Widget _buildReminderFrequencySelector(AppLocalizations l10n) {
    final frequencies = ['daily', 'weekly', 'monthly'];
    final frequencyLabels = ['Daily', 'Weekly', 'Monthly'];
    
    return _buildSettingsItem(
      icon: Icons.schedule,
      title: 'Reminder Frequency',
      subtitle: frequencyLabels[frequencies.indexOf(_reminderFrequency)],
      trailing: DropdownButton<String>(
        value: _reminderFrequency,
        underline: SizedBox(),
        items: frequencies.asMap().entries.map((entry) => DropdownMenuItem(
          value: entry.value,
          child: Text(frequencyLabels[entry.key], style: GoogleFonts.poppins()),
        )).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _reminderFrequency = value);
            _updateSettings({'reminderFrequency': value});
          }
        },
      ),
    );
  }

  void _showChangePasswordDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Password must be at least 8 characters',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: _isUpdatingPassword ? null : () {
              Navigator.pop(context);
              _changePassword();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF27121),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUpdatingPassword
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: l10n.name,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _userName = nameController.text);
              _updateSettings({'name': nameController.text});
              _showSuccessSnackBar('Profile updated successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF27121),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade600),
            SizedBox(width: 12),
            Text(
              'Logout All Devices',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from all devices?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Logout All'),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.red.shade600),
            SizedBox(width: 12),
            Text(
              'Reset Settings',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all settings to default?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Reset'),
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
        backgroundColor: Color(0xFFF27121),
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