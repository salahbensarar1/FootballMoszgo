import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:footballtraining/core/theme/app_theme.dart';

class CoachDrawerExtracted extends StatelessWidget {
  final String? userDisplayName;
  final String? userProfileImageUrl;
  final Function() showProfileSettings;
  final Function() showLanguageDialog;
  final Function() showThemeSettings;
  final Function(String) makePhoneCall;
  final Function(String) sendEmail;
  final Function() showHelpDialog;
  final Function() logoutUser;
  final String Function() getCurrentLanguageName;
  final String Function() getCurrentLanguageFlag;

  const CoachDrawerExtracted({
    super.key,
    this.userDisplayName,
    this.userProfileImageUrl,
    required this.showProfileSettings,
    required this.showLanguageDialog,
    required this.showThemeSettings,
    required this.makePhoneCall,
    required this.sendEmail,
    required this.showHelpDialog,
    required this.logoutUser,
    required this.getCurrentLanguageName,
    required this.getCurrentLanguageFlag,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Drawer(
      backgroundColor: AppTheme.surface,
      elevation: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Header with flexible height
              Flexible(
                flex: 0,
                child: _buildDrawerHeader(l10n, isSmallScreen),
              ),
              // Content with scrollable body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          200, // Ensure content fills remaining space
                    ),
                    child: Column(
                      children: [
                        _buildDrawerSection(
                          title: l10n.account,
                          items: [
                            DrawerItemData(
                              icon: Icons.person_outline,
                              activeIcon: Icons.person,
                              title: l10n.profile,
                              subtitle: 'Profil kezelése',
                              onTap: showProfileSettings,
                              color: const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: l10n.settings,
                          items: [
                            DrawerItemData(
                              icon: Icons.language_outlined,
                              activeIcon: Icons.language,
                              title: l10n.language,
                              subtitle: getCurrentLanguageName(),
                              onTap: showLanguageDialog,
                              color: const Color(0xFF2196F3),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  getCurrentLanguageFlag(),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            DrawerItemData(
                              icon: Icons.dark_mode_outlined,
                              activeIcon: Icons.dark_mode,
                              title: l10n.theme,
                              subtitle: l10n.lightMode,
                              onTap: showThemeSettings,
                              color: const Color(0xFF9C27B0),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: l10n.contact,
                          items: [
                            DrawerItemData(
                              icon: Icons.phone_outlined,
                              activeIcon: Icons.phone,
                              title: 'Phone Support',
                              subtitle: '+36 30 5754 174',
                              onTap: () => makePhoneCall('+36305754174'),
                              color: const Color(0xFF4CAF50),
                            ),
                            DrawerItemData(
                              icon: Icons.email_outlined,
                              activeIcon: Icons.email,
                              title: l10n.emailSupport,
                              subtitle: 'sa.bensarar@gmail.com',
                              onTap: () => sendEmail('sa.bensarar@gmail.com'),
                              color: const Color(0xFF2196F3),
                            ),
                          ],
                        ),
                        _buildDrawerSection(
                          title: l10n.support,
                          items: [
                            DrawerItemData(
                              icon: Icons.help_outline,
                              activeIcon: Icons.help,
                              title: l10n.help,
                              subtitle: 'This is should be the match page ',
                              onTap: showHelpDialog,
                              color: const Color(0xFFFF9800),
                            ),
                            DrawerItemData(
                              icon: Icons.logout_outlined,
                              activeIcon: Icons.logout,
                              title: l10n.logout,
                              subtitle: 'Kijelentkezés',
                              onTap: logoutUser,
                              color: const Color(0xFFF44336),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(AppLocalizations l10n, bool isSmallScreen) {
    final user = FirebaseAuth.instance.currentUser;
    // Make avatar even smaller on very small screens
    final avatarRadius = isSmallScreen ? 28.0 : 34.0;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          // Reduce padding on small screens
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min, // Prevent row overflow
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced Avatar with CachedNetworkImage
                Hero(
                  tag: 'coach_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildProfileAvatar(avatarRadius),
                  ),
                ),
                const SizedBox(width: 12), // Reduce spacing
                // User Info with Flexible Layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Prevent column overflow
                    children: [
                      // Name with overflow protection
                      Flexible(
                        child: Text(
                          userDisplayName ??
                              user?.displayName ??
                              user?.email?.split('@').first ??
                              'Coach',
                          style: (isSmallScreen
                                  ? AppTheme.bodyMedium
                                  : AppTheme.bodyLarge)
                              .copyWith(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 3), // Reduce spacing
                        // Email with overflow protection
                        Flexible(
                          child: Text(
                            user!.email!,
                            style: AppTheme.caption.copyWith(
                              color:
                                  AppTheme.background.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6), // Reduce spacing
                      // Role Badge - make it smaller
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 8 : 10,
                            vertical: isSmallScreen ? 3 : 5),
                        decoration: BoxDecoration(
                          color: AppTheme.background.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.background.withValues(alpha: 0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          l10n.coach,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double avatarRadius) {
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: AppTheme.background.withValues(alpha: 0.3),
      child: ClipOval(
        child: userProfileImageUrl != null && userProfileImageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: userProfileImageUrl!,
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  color: AppTheme.surface,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.textMuted),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: avatarRadius,
                  color: AppTheme.background,
                ),
              )
            : Icon(
                Icons.person,
                size: avatarRadius,
                color: AppTheme.background,
              ),
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<DrawerItemData> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTheme.overline.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ...items.map((item) => _buildProfessionalDrawerItem(item)),
        const SizedBox(height: 8),
      ],
    );
  }

  // Enhanced Drawer Item with Modern Design
  Widget _buildProfessionalDrawerItem(DrawerItemData item) {
    return Builder(
      builder: (context) {
        // Get screen size here
        final size = MediaQuery.of(context).size;
        final isSmallScreen = size.width < 400;

        return Container(
          margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 6 : 8,
              vertical: isSmallScreen ? 1 : 2),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                item.onTap();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 10 : 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Prevent row overflow
                  children: [
                    // Icon with background circle - make it more compact
                    Container(
                      width: isSmallScreen ? 36 : 40,
                      height: isSmallScreen ? 36 : 40,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8), // Smaller radius
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size:
                            isSmallScreen ? 18 : 20, // Smaller on small screens
                      ),
                    ),
                    SizedBox(
                        width: isSmallScreen ? 12 : 16), // Adaptive spacing
                    // Title and subtitle with overflow protection
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize:
                            MainAxisSize.min, // Prevent column overflow
                        children: [
                          Text(
                            item.title,
                            style: (isSmallScreen
                                    ? AppTheme.bodyMedium
                                    : AppTheme.bodyLarge)
                                .copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Trailing widget or arrow - make it smaller
                    if (item.trailing != null)
                      item.trailing!
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        size:
                            isSmallScreen ? 12 : 14, // Smaller on small screens
                        color: AppTheme.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class DrawerItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Widget? trailing;

  const DrawerItemData({
    required this.icon,
    this.activeIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
    this.trailing,
  });
}
