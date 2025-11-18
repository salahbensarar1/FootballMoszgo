import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CoachAppBarExtracted extends StatelessWidget implements PreferredSizeWidget {
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
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFF27121).withOpacity(0.9),
              const Color(0xFFE94057).withOpacity(0.9),
              Colors.purple.shade400.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      titleSpacing: 0, // Remove title spacing
      title: Padding(
        padding: EdgeInsets.only(right: verySmallScreen ? 4.0 : 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Important to prevent overflow
          children: [
            Container(
              padding: EdgeInsets.all(verySmallScreen ? 4 : 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(verySmallScreen ? 8 : 10),
              ),
              child: Icon(
                Icons.sports_soccer,
                color: Colors.white,
                size: verySmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: verySmallScreen ? 4 : 8),
            Flexible(
              child: Text(
                l10n.coachScreen,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: verySmallScreen ? 14 : (isSmallScreen ? 16 : 18),
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Status indicator for active training
        if (isTrainingActive)
          Container(
            margin: EdgeInsets.symmetric(
                vertical: verySmallScreen ? 10 : 12,
                horizontal: verySmallScreen ? 2 : 4),
            padding: EdgeInsets.symmetric(
                horizontal: verySmallScreen ? 6 : 8,
                vertical: verySmallScreen ? 2 : 4),
            decoration: BoxDecoration(
              color: Colors.green.shade400,
              borderRadius: BorderRadius.circular(verySmallScreen ? 16 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: verySmallScreen ? 4 : 6,
                  height: verySmallScreen ? 4 : 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: verySmallScreen ? 2 : 4),
                Text(
                  "Live",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: verySmallScreen ? 8 : 10,
                  ),
                ),
              ],
            ),
          ),

        // User profile picture - only show on larger screens
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
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Hero(
                  tag: 'profile_image',
                  child: buildProfileAvatar(14),
                ),
              ),
            ),
          ),

        // Logout button - make it more compact
        IconButton(
          constraints: BoxConstraints(
            minWidth: verySmallScreen ? 32 : 36,
            minHeight: verySmallScreen ? 32 : 36,
          ),
          padding: EdgeInsets.zero,
          icon: Container(
            padding: EdgeInsets.all(verySmallScreen ? 3 : 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(verySmallScreen ? 4 : 6),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: Colors.white,
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