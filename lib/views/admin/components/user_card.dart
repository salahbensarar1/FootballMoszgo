// File: lib/views/admin/components/user_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/utils/role_helper.dart';

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
    final data = userDoc.data() as Map<String, dynamic>? ?? {};

    final name = data['name'] ?? 'N/A';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'No Role';
    final pictureUrl = data['picture'] as String?;

    final roleColor = RoleHelper.getRoleColor(role);
    final roleIcon = RoleHelper.getRoleIcon(role);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showUserDetailsDialog(context, l10n),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              _buildUserAvatar(pictureUrl, roleColor),
              SizedBox(width: 16),
              _buildUserInfo(name, email, role, roleColor, roleIcon),
              _buildPopupMenu(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? pictureUrl, Color roleColor) {
    return Hero(
      tag: 'user_${userDoc.id}',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: roleColor.withOpacity(0.3), width: 2),
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
    );
  }

  Widget _buildUserInfo(String name, String email, String role, Color roleColor,
      IconData roleIcon) {
    return Expanded(
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
          Text(
            email,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  roleIcon,
                  size: 14,
                  color: roleColor,
                ),
                SizedBox(width: 4),
                Text(
                  role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_vert_rounded,
          color: Colors.grey.shade600,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Icon(Icons.edit_rounded, color: Colors.blue.shade600, size: 20),
              SizedBox(width: 12),
              Text(
                l10n.edit,
                style: GoogleFonts.poppins(color: Colors.blue.shade600),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, color: Colors.red.shade600, size: 20),
              SizedBox(width: 12),
              Text(
                l10n.delete,
                style: GoogleFonts.poppins(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUserDetailsDialog(BuildContext context, AppLocalizations l10n) {
    final data = userDoc.data() as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: (data['picture']?.isNotEmpty == true)
                  ? NetworkImage(data['picture'])
                  : AssetImage("assets/images/default_profile.jpeg")
                      as ImageProvider,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                data['name'] ?? 'User Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', data['email'] ?? 'Not available'),
            _buildDetailRow('Role', (data['role'] ?? 'Unknown').toUpperCase()),
            if (data['role_description']?.isNotEmpty == true)
              _buildDetailRow('Description', data['role_description']),
            if (data['team']?.isNotEmpty == true)
              _buildDetailRow('Team', data['team']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF27121),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              l10n.edit,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
