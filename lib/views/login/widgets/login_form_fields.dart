import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmailField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFieldSubmitted;

  const EmailField({
    super.key,
    required this.controller,
    this.onFieldSubmitted,
  });

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? const Color(0xFF667eea) : Colors.grey.shade300,
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        onChanged: (_) => setState(() {}),
        onTap: () => setState(() => _focused = true),
        onFieldSubmitted: (_) {
          setState(() => _focused = false);
          widget.onFieldSubmitted?.call();
        },
        onEditingComplete: () => setState(() => _focused = false),
        validator: (value) {
          if (value?.isEmpty ?? true) return l10n.pleaseEnterEmail;
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
            return l10n.pleaseEnterValidEmail;
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: l10n.email,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: _focused ? const Color(0xFF667eea) : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFieldSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _focused = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? const Color(0xFF667eea) : Colors.grey.shade300,
          width: _focused ? 2 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onChanged: (_) => setState(() {}),
        onTap: () => setState(() => _focused = true),
        onFieldSubmitted: (_) {
          setState(() => _focused = false);
          widget.onFieldSubmitted?.call();
        },
        onEditingComplete: () => setState(() => _focused = false),
        validator: (value) {
          if (value?.isEmpty ?? true) return l10n.pleaseEnterPassword;
          if (value!.length < 6) return l10n.passwordMinLength;
          return null;
        },
        decoration: InputDecoration(
          hintText: l10n.password,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: _focused ? const Color(0xFF667eea) : Colors.grey.shade500,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade500,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}