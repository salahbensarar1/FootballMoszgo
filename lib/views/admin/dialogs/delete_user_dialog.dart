import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteUserDialog extends StatefulWidget {
  final DocumentSnapshot userDoc;
  final VoidCallback onUserDeleted;

  const DeleteUserDialog({
    super.key,
    required this.userDoc,
    required this.onUserDeleted,
  });

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.userDoc.data() as Map<String, dynamic>? ?? {};
    final userName = data['name'] ?? 'this user';
    final userRole = data['role'] ?? 'user';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red.shade600),
          SizedBox(width: 12),
          Text(
            'Confirm Deletion',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete $userName ($userRole)?',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.red.shade600, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This action cannot be undone',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All associated data will be removed and coach assignments will be cleared.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed:
              isLoading ? null : () => _deleteUser(context, l10n, userRole),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  l10n.delete,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(
      BuildContext context, AppLocalizations l10n, String userRole) async {
    setState(() => isLoading = true);

    try {
      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFF27121)),
                SizedBox(width: 16),
                Text(
                  'Deleting user...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          ),
        ),
      );

      // Handle coach deletion - unassign from teams
      WriteBatch batch = FirebaseFirestore.instance.batch();

      if (userRole == 'coach') {
        final teamsManaged = await FirebaseFirestore.instance
            .collection('teams')
            .where('coach', isEqualTo: widget.userDoc.id)
            .get();

        for (var teamDoc in teamsManaged.docs) {
          batch.update(teamDoc.reference, {'coach': ''});
        }
      }

      // Delete user document
      batch.delete(widget.userDoc.reference);

      // Commit batch operation
      await batch.commit();

      // Close loading overlay
      Navigator.pop(context);
      // Close delete dialog
      Navigator.pop(context);

      widget.onUserDeleted();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.deletedSuccessfully,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      // Close loading overlay if it exists
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.failedToDelete(e.toString()),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
