// File: lib/views/admin/components/user_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/utils/role_helper.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';

class UserCard extends StatelessWidget {
  final DocumentSnapshot userDoc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.userDoc,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 480;
    final isTablet = size.width > 768;

    final data = userDoc.data() as Map<String, dynamic>? ?? {};

    final name = data['name'] ?? 'N/A';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'No Role';
    final pictureUrl = data['picture'] as String?;

    final roleColor = RoleHelper.getRoleColor(role);
    final roleIcon = RoleHelper.getRoleIcon(role);

    return AppCard(
      padding: EdgeInsets.all(isMobile ? 12 : (isTablet ? 20 : 16)),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(context, l10n),
        borderRadius: BorderRadius.circular(16),
        child: isMobile
            ? _buildMobileLayout(name, email, role, roleColor, roleIcon,
                pictureUrl, context, l10n)
            : _buildDesktopLayout(name, email, role, roleColor, roleIcon,
                pictureUrl, context, l10n, isTablet),
      ),
    );
  }

  Widget _buildUserAvatar(String? pictureUrl, Color roleColor, {double? size}) {
    final avatarSize = size ?? 60;

    return Hero(
      tag: 'user_${userDoc.id}',
      child: GradientAvatar(
        size: avatarSize,
        imageUrl: pictureUrl,
        defaultAsset: "assets/images/default_profile.jpeg",
        borderColor: roleColor,
      ),
    );
  }

  Widget _buildUserInfo(String name, String email, String role, Color roleColor,
      IconData roleIcon,
      {bool isMobile = false, bool isTablet = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: (isTablet
                    ? AppTheme.bodyLarge
                    : (isMobile ? AppTheme.bodyMedium : AppTheme.bodyLarge))
                .copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            email,
            style: (isTablet
                    ? AppTheme.bodyMedium
                    : (isMobile ? AppTheme.caption : AppTheme.bodyMedium))
                .copyWith(
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          StatusBadge(
            label: role.toUpperCase(),
            color: roleColor,
            icon: roleIcon,
            compact: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, AppLocalizations l10n,
      {bool isMobile = false}) {
    final iconSize = isMobile ? 16.0 : 20.0;
    final buttonSize = isMobile ? 32.0 : 40.0;

    return PopupMenuButton<String>(
      icon: Container(
        width: buttonSize,
        height: buttonSize,
        padding: EdgeInsets.all(isMobile ? 6 : 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border, width: 1),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: AppTheme.textSecondary,
          size: iconSize,
        ),
      ),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.border),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, color: AppTheme.primary, size: iconSize),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                l10n.edit,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primary,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: AppTheme.error, size: iconSize),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                l10n.delete,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.error,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      String name,
      String email,
      String role,
      Color roleColor,
      IconData roleIcon,
      String? pictureUrl,
      BuildContext context,
      AppLocalizations l10n) {
    return Row(
      children: [
        _buildUserAvatar(pictureUrl, roleColor, size: 48),
        const SizedBox(width: 12),
        _buildUserInfo(name, email, role, roleColor, roleIcon, isMobile: true),
        _buildPopupMenu(context, l10n, isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout(
      String name,
      String email,
      String role,
      Color roleColor,
      IconData roleIcon,
      String? pictureUrl,
      BuildContext context,
      AppLocalizations l10n,
      bool isTablet) {
    return Row(
      children: [
        _buildUserAvatar(pictureUrl, roleColor, size: isTablet ? 70 : 60),
        SizedBox(width: isTablet ? 20 : 16),
        _buildUserInfo(name, email, role, roleColor, roleIcon,
            isTablet: isTablet),
        _buildPopupMenu(context, l10n),
      ],
    );
  }

  void _showUserDetailsDialog(BuildContext context, AppLocalizations l10n) {
    final data = userDoc.data() as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar
              Row(
                children: [
                  GradientAvatar(
                    size: 56,
                    imageUrl: data['picture'],
                    defaultAsset: "assets/images/default_profile.jpeg",
                    borderColor: AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'User Details',
                          style: AppTheme.heading3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['email'] ?? 'No email',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Details section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Role', (data['role'] ?? 'Unknown').toUpperCase()),
                    if (data['role_description']?.isNotEmpty == true)
                      _buildDetailRow('Description', data['role_description']),
                    if (data['team']?.isNotEmpty == true)
                      _buildDetailRow('Team', data['team']),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedPrimaryButton(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
                    compact: true,
                  ),
                  const SizedBox(width: 12),
                  GradientButton(
                    label: l10n.edit,
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.caption.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
