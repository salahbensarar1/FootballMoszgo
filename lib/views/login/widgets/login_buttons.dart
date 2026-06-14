import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/views/setup/organization_setup_wizard.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginButton extends StatelessWidget {
  final bool isSmallScreen;
  final bool isLoading;
  final VoidCallback onPressed;

  const LoginButton({
    super.key,
    required this.isSmallScreen,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 54),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.login,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.loginButton,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AdminButton extends StatelessWidget {
  const AdminButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrganizationSetupWizard(),
          ),
        );
      },
      icon: const Icon(
        Icons.business_outlined,
        color: AppTheme.primary,
        size: 20,
      ),
      label: Text(
        l10n.createNewOrganization,
        style: GoogleFonts.poppins(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 54),
      ),
    );
  }
}

class MigrationButton extends StatelessWidget {
  const MigrationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data migration tools not available in production'),
            backgroundColor: Colors.orange,
          ),
        );
      },
      icon: const Icon(
        Icons.transform,
        color: Color(0xFFff9800),
        size: 20,
      ),
      label: const Text(
        'Migrate Existing Data',
        style: TextStyle(
          color: Color(0xFFff9800),
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
