import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class EditUserDialog extends StatefulWidget {
  final DocumentSnapshot userDoc;
  final AppLocalizations l10n;
  final VoidCallback onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.userDoc,
    required this.l10n,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleDescriptionController;

  String selectedRole = 'coach';
  bool isLoading = false;

  final List<String> roleOptions = ['coach', 'admin', 'receptionist'];

  @override
  void initState() {
    super.initState();
    final data = widget.userDoc.data() as Map<String, dynamic>? ?? {};

    _nameController = TextEditingController(text: data['name'] ?? '');
    _emailController = TextEditingController(text: data['email'] ?? '');
    _roleDescriptionController =
        TextEditingController(text: data['role_description'] ?? '');
    selectedRole = data['role'] ?? 'coach';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF27121).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_rounded,
              color: Color(0xFFF27121),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Edit User',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: widget.l10n.name,
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Email Field (Read-only)
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: widget.l10n.email,
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),

                SizedBox(height: 16),

                // Role Selection
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: roleOptions.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            color: _getRoleColor(role),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            role.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),

                SizedBox(height: 16),

                // Role Description Field
                TextFormField(
                  controller: _roleDescriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: widget.l10n.roleDescription,
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Enter role description...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(
            widget.l10n.cancel,
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _updateUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF27121),
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
                  widget.l10n.save,
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.shade600;
      case 'coach':
        return Colors.blue.shade600;
      case 'receptionist':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'coach':
        return Icons.sports_rounded;
      case 'receptionist':
        return Icons.desk_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userDoc.id)
          .update({
        'name': _nameController.text.trim(),
        'role': selectedRole,
        'role_description': _roleDescriptionController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': FirebaseAuth.instance.currentUser?.uid,
      });

      Navigator.pop(context);
      widget.onUserUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.l10n.successfullyUpdated,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.l10n.failedToUpdate(e.toString()),
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
