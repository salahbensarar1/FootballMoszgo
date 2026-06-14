import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:footballtraining/utils/role_helper.dart';

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
    final size = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: size.width > 600 ? 500 : size.width - 32,
          maxHeight: size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppTheme.background,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.l10n.editUser,
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.background,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name Field
                        PremiumTextField(
                          controller: _nameController,
                          labelText: widget.l10n.name,
                          hintText: 'Enter full name',
                          leadingIcon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return widget.l10n.pleaseEnterName;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Email Field (Read-only)
                        PremiumTextField(
                          controller: _emailController,
                          labelText: widget.l10n.email,
                          hintText: 'Email address',
                          leadingIcon: Icons.email_outlined,
                          enabled: false,
                        ),

                        const SizedBox(height: 20),

                        // Role Selection Card
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.work_outline_rounded,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.l10n.role,
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: roleOptions.map((role) {
                                  final isSelected = selectedRole == role;
                                  final roleColor =
                                      RoleHelper.getRoleColor(role);
                                  final roleIcon = RoleHelper.getRoleIcon(role);

                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => selectedRole = role),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? roleColor.withValues(alpha: 0.1)
                                            : AppTheme.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? roleColor
                                              : AppTheme.border,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            roleIcon,
                                            color: roleColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _getRoleDisplayName(role),
                                            style: AppTheme.bodyMedium.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? roleColor
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Role Description Field
                        PremiumTextField(
                          controller: _roleDescriptionController,
                          labelText: widget.l10n.roleDescription,
                          hintText: widget.l10n.enterRoleDescription,
                          leadingIcon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedPrimaryButton(
                    label: widget.l10n.cancel,
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    compact: true,
                  ),
                  const SizedBox(width: 12),
                  GradientButton(
                    label: widget.l10n.save,
                    onPressed: isLoading ? null : _updateUser,
                    isLoading: isLoading,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return widget.l10n.admin;
      case 'coach':
        return widget.l10n.coach;
      case 'receptionist':
        return widget.l10n.receptionist;
      default:
        return role.toUpperCase();
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

      if (mounted) {
        Navigator.pop(context);
        widget.onUserUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppTheme.background, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.l10n.successfullyUpdated,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.background,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppTheme.background, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.l10n.failedToUpdate(e.toString()),
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.background,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
}
