import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:footballtraining/utils/role_helper.dart';

class AddUserDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final VoidCallback onUserAdded;

  const AddUserDialog({
    super.key,
    required this.l10n,
    required this.onUserAdded,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String selectedRole = 'coach';
  bool isLoading = false;
  bool showPassword = false;

  final List<String> roleOptions = ['coach', 'admin', 'receptionist'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final maxWidth = isMobile ? size.width * 0.95 : 500.0;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: size.height * 0.85,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTitle(isMobile),
            SizedBox(height: isMobile ? 16 : 20),
            Flexible(
              child: SingleChildScrollView(
                child: _buildFormContent(isMobile),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            _buildActionButtons(isMobile),
          ],
        ),
      ),
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

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Create user with Firebase Auth
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': selectedRole,
        'role_description': _getRoleDescription(selectedRole),
        'created_at': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      });

      Navigator.pop(context);

      // Call the onUserAdded callback
      widget.onUserAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.l10n.userAddedSuccessfully,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = widget.l10n.errorAddingUser;

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password too weak';
          break;
        case 'email-already-in-use':
          errorMessage = 'Account already exists';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.l10n.errorAddingUser}: $e',
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

  Widget _buildDialogTitle(bool isMobile) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF27121).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person_add_rounded,
            color: const Color(0xFFF27121),
            size: isMobile ? 20 : 24,
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Text(
            widget.l10n.addNewUser,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 16 : 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameField(isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          _buildEmailField(isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          _buildPasswordField(isMobile),
          SizedBox(height: isMobile ? 12 : 16),
          _buildRoleDropdown(isMobile),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isMobile) {
    return TextFormField(
      controller: _nameController,
      style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: widget.l10n.name,
        labelStyle: GoogleFonts.poppins(fontSize: isMobile ? 13 : 14),
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          size: isMobile ? 20 : 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 16,
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return widget.l10n.nameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildEmailField(bool isMobile) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: widget.l10n.email,
        labelStyle: GoogleFonts.poppins(fontSize: isMobile ? 13 : 14),
        prefixIcon: Icon(
          Icons.email_outlined,
          size: isMobile ? 20 : 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 16,
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return widget.l10n.emailRequired;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return widget.l10n.validEmailRequired;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isMobile) {
    return TextFormField(
      controller: _passwordController,
      obscureText: !showPassword,
      style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: widget.l10n.password,
        labelStyle: GoogleFonts.poppins(fontSize: isMobile ? 13 : 14),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: isMobile ? 20 : 24,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            size: isMobile ? 20 : 24,
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 16,
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return widget.l10n.passwordRequired;
        }
        if (value!.length < 6) {
          return widget.l10n.passwordMinLength;
        }
        return null;
      },
    );
  }

  Widget _buildRoleDropdown(bool isMobile) {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
      decoration: InputDecoration(
        labelText: widget.l10n.role,
        labelStyle: GoogleFonts.poppins(fontSize: isMobile ? 13 : 14),
        prefixIcon: Icon(
          Icons.work_outline_rounded,
          size: isMobile ? 20 : 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 12 : 16,
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
                size: isMobile ? 16 : 20,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Flexible(
                child: Text(
                  role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: isMobile ? 13 : 14,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: Text(
              widget.l10n.cancel,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _createUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF27121),
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 12 : 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: isMobile ? 16 : 20,
                    height: isMobile ? 16 : 20,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.l10n.add,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'coach':
        return 'Responsible for training sessions and player development';
      case 'admin':
        return 'Full system access and management capabilities';
      case 'receptionist':
        return 'Handles player registration and basic administrative tasks';
      default:
        return 'Standard user role';
    }
  }
}
