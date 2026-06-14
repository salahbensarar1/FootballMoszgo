import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CoachAppBarExtracted extends StatelessWidget
    implements PreferredSizeWidget {
  final bool isSmallScreen;
  final bool isTrainingActive;
  final String? userProfileImageUrl;
  final VoidCallback onProfilePressed;
  final VoidCallback onLogoutPressed;
  final Widget Function(double radius) buildProfileAvatar;

  const CoachAppBarExtracted({
    super.key,
    required this.isSmallScreen,
    required this.isTrainingActive,
    this.userProfileImageUrl,
    required this.onProfilePressed,
    required this.onLogoutPressed,
    required this.buildProfileAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Use even smaller sizes for very small screens
    final verySmallScreen = MediaQuery.of(context).size.width < 350;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
      ),
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(right: verySmallScreen ? 4.0 : 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(verySmallScreen ? 4 : 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(verySmallScreen ? 8 : 10),
              ),
              child: Icon(
                Icons.sports_soccer,
                color: AppTheme.primary,
                size: verySmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: verySmallScreen ? 4 : 8),
            Flexible(
              child: Text(
                l10n.coachScreen,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: verySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isTrainingActive)
          Container(
            margin: EdgeInsets.symmetric(
              vertical: verySmallScreen ? 10 : 12,
              horizontal: verySmallScreen ? 2 : 4,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: verySmallScreen ? 6 : 8,
              vertical: verySmallScreen ? 2 : 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.success, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: verySmallScreen ? 4 : 6,
                  height: verySmallScreen ? 4 : 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: verySmallScreen ? 2 : 4),
                Text(
                  "Live",
                  style: GoogleFonts.poppins(
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: verySmallScreen ? 8 : 10,
                  ),
                ),
              ],
            ),
          ),
        if (!isSmallScreen && !verySmallScreen)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              onTap: onProfilePressed,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: Hero(
                  tag: 'profile_image',
                  child: buildProfileAvatar(14),
                ),
              ),
            ),
          ),
        IconButton(
          constraints: BoxConstraints(
            minWidth: verySmallScreen ? 32 : 36,
            minHeight: verySmallScreen ? 32 : 36,
          ),
          padding: EdgeInsets.zero,
          icon: Container(
            padding: EdgeInsets.all(verySmallScreen ? 3 : 4),
            decoration: BoxDecoration(
              color: AppTheme.surface2,
              borderRadius: BorderRadius.circular(verySmallScreen ? 4 : 6),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppTheme.textSecondary,
              size: verySmallScreen ? 14 : 16,
            ),
          ),
          onPressed: onLogoutPressed,
          tooltip: l10n.logout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
