import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final VoidCallback onUserAdded;
  final String organizationId;

  const AddUserDialog({
    super.key,
    required this.l10n,
    required this.onUserAdded,
    required this.organizationId,
  });

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus nodes for smooth keyboard-aware flow
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String _selectedRole = 'coach';
  bool _isLoading = false;
  bool _showPassword = false;

  // Drives the submit button shimmer/pulse while loading
  late final AnimationController _loadingAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  static const _brand = Color(0xFFF27121);

  static const _roles = <_RoleMeta>[
    _RoleMeta('coach', Icons.sports_rounded, Color(0xFF2196F3)),
    _RoleMeta('admin', Icons.admin_panel_settings_rounded, Color(0xFFE53935)),
    _RoleMeta('receptionist', Icons.desk_rounded, Color(0xFF43A047)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _loadingAnim.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Single breakpoint value used everywhere — no repeated ternaries
    final compact = mq.size.width < 600;
    final hPad = compact ? 20.0 : 28.0;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 48,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(brand: _brand, l10n: widget.l10n, hPad: hPad),
            // Scrollable form — no nested scroll conflict
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: _buildForm(compact),
              ),
            ),
            _buildActions(hPad, compact),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool compact) {
    final gap = compact ? 14.0 : 18.0;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(
            controller: _nameController,
            focusNode: _nameFocus,
            nextFocus: _emailFocus,
            label: widget.l10n.name,
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? widget.l10n.nameRequired
                : null,
          ),
          SizedBox(height: gap),
          _Field(
            controller: _emailController,
            focusNode: _emailFocus,
            nextFocus: _passwordFocus,
            label: widget.l10n.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return widget.l10n.emailRequired;
              if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(s)) {
                return widget.l10n.validEmailRequired;
              }
              return null;
            },
          ),
          SizedBox(height: gap),
          _PasswordField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            showPassword: _showPassword,
            onToggle: () => setState(() => _showPassword = !_showPassword),
            label: widget.l10n.password,
            passwordRequired: widget.l10n.passwordRequired,
            passwordMinLength: widget.l10n.passwordMinLength,
            onSubmit: _submit,
          ),
          SizedBox(height: gap + 2),
          _RoleLabel(l10n: widget.l10n),
          const SizedBox(height: 10),
          _RoleSelector(
            roles: _roles,
            selected: _selectedRole,
            onChanged: (r) => setState(() => _selectedRole = r),
          ),
          SizedBox(height: gap),
        ],
      ),
    );
  }

  Widget _buildActions(double hPad, bool compact) {
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, compact ? 20 : 24),
      child: Row(
        children: [
          Expanded(
            child: _CancelButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              label: widget.l10n.cancel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _SubmitButton(
              isLoading: _isLoading,
              anim: _loadingAnim,
              brand: _brand,
              label: widget.l10n.add,
              onPressed: _isLoading ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logic (unchanged) ────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Failed to create auth user');

      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(widget.organizationId)
          .collection('users')
          .doc(uid)
          .set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'role_description': _roleDescription(_selectedRole),
        'organization_id': widget.organizationId,
        'is_active': true,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onUserAdded();
      _showSnack(widget.l10n.userAddedSuccessfully, Colors.green.shade600);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'weak-password' => 'Password is too weak',
        'email-already-in-use' => 'An account with this email already exists',
        'invalid-email' => 'Invalid email address',
        _ => e.message ?? widget.l10n.errorAddingUser,
      };
      if (mounted) _showSnack(msg, Colors.red.shade600);
    } catch (e) {
      if (mounted)
        _showSnack('${widget.l10n.errorAddingUser}: $e', Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 14)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _roleDescription(String role) => switch (role.toLowerCase()) {
        'coach' => 'Responsible for training sessions and player development',
        'admin' => 'Full system access and management capabilities',
        'receptionist' =>
          'Handles player registration and basic administrative tasks',
        _ => 'Standard user role',
      };
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RoleMeta {
  final String value;
  final IconData icon;
  final Color color;
  const _RoleMeta(this.value, this.icon, this.color);
}

// Gradient header strip — makes the dialog feel premium
class _Header extends StatelessWidget {
  final Color brand;
  final AppLocalizations l10n;
  final double hPad;

  const _Header({required this.brand, required this.l10n, required this.hPad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(hPad, 22, hPad, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            brand.withValues(alpha: 0.12),
            brand.withValues(alpha: 0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: brand.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_add_rounded, color: brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.addNewUser,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Fill in the details to create an account',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Generic text field — eliminates repetition
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const _Field({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => nextFocus.requestFocus(),
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _decor(context, label, icon),
      validator: validator,
    );
  }
}

// Separate widget so obscureText state stays local and doesn't trigger full rebuild
class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showPassword;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;
  final String label;
  final String passwordRequired;
  final String passwordMinLength;

  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.showPassword,
    required this.onToggle,
    required this.onSubmit,
    required this.label,
    required this.passwordRequired,
    required this.passwordMinLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !showPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => onSubmit(),
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: _decor(context, label, Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
            color: Colors.grey.shade500,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (v) {
        final s = v ?? '';
        if (s.isEmpty) return passwordRequired;
        if (s.length < 6) return passwordMinLength;
        return null;
      },
    );
  }
}

class _RoleLabel extends StatelessWidget {
  final AppLocalizations l10n;
  const _RoleLabel({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Text(
      l10n.role,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }
}

// Chip-based role selector — far better UX than a dropdown for 3 options
class _RoleSelector extends StatelessWidget {
  final List<_RoleMeta> roles;
  final String selected;
  final ValueChanged<String> onChanged;

  const _RoleSelector({
    required this.roles,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: roles.map((role) {
        final isSelected = selected == role.value;
        final isLast = role == roles.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected
                    ? role.color.withValues(alpha: 0.12)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? role.color : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => onChanged(role.value),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          role.icon,
                          color: isSelected ? role.color : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        role.value[0].toUpperCase() + role.value.substring(1),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? role.color : Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const _CancelButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final AnimationController anim;
  final Color brand;
  final String label;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.anim,
    required this.brand,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading
                ? Color.lerp(brand, brand.withValues(alpha: 0.7), anim.value)
                : brand,
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: isLoading ? 0 : 2,
            shadowColor: brand.withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child!,
        );
      },
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.2,
              ),
            )
          : Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

// Shared InputDecoration factory — single source of truth for field styling
InputDecoration _decor(BuildContext context, String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
    filled: true,
    fillColor: Colors.grey.shade50,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFF27121), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
