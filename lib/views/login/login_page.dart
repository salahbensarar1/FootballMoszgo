import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/views/admin/admin_screen.dart';
import 'package:footballtraining/views/coach/coach_screen.dart';
import 'package:footballtraining/views/receptionist/receptionist_screen.dart';
import 'package:footballtraining/services/auth_service.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/widgets/app_widgets.dart';
import 'package:footballtraining/core/painters/pitch_painter.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/views/login/widgets/login_form_fields.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Keep the old name for backwards compatibility
class Loginpage extends LoginPage {
  const Loginpage({super.key});
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.elasticOut,
    ));

    _logoController.forward();
    _formController.forward();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    HapticFeedback.lightImpact();

    final result = await AuthService.loginUser(
      emailController.text,
      passwordController.text,
    );

    if (result.isSuccess) {
      Widget destination;
      switch (result.userRole) {
        case 'admin':
          destination = const AdminScreen();
          break;
        case 'receptionist':
          destination = const ReceptionistScreen();
          break;
        case 'coach':
          destination = const CoachScreen();
          break;
        default:
          throw Exception("Unauthorized role: ${result.userRole}");
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorMessage(AuthService.getErrorMessage(result.error!, l10n));
      }
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.textPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTheme.bodyMedium,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Layer 1 - Background art
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            width: double.infinity,
            height: double.infinity,
          ),

          // Diagonal lines pattern
          CustomPaint(
            painter: PitchLinePainter(
              lineColor: AppTheme.primary.withValues(alpha: 0.04),
            ),
            size: Size.infinite,
          ),

          // Layer 2 - Content
          SafeArea(
            child: Column(
              children: [
                // Top 38% - Logo section
                Expanded(
                  flex: 2,
                  child: FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: _buildTopSection(screenWidth < 400, AppLocalizations.of(context)!),
                  ),
                ),

                // Bottom 62% - Form section
                Expanded(
                  flex: 3,
                  child: SlideTransition(
                    position: _formSlideAnimation,
                    child: _buildBottomSection(screenWidth < 400, AppLocalizations.of(context)!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(bool isSmallScreen, AppLocalizations l10n) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topSectionHeight = screenHeight * (isSmallScreen ? 0.22 : 0.26);

    return SizedBox(
      height: topSectionHeight,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ScreenConfig.spaceL,
          vertical: ScreenConfig.spaceS,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(ScreenConfig.radiusL),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(ScreenConfig.spaceL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_soccer,
                    size: ScreenConfig.iconXL,
                    color: AppTheme.background,
                  ),
                  SizedBox(height: ScreenConfig.spaceS),
                  Text(
                    'FootballMoszgo',
                    style: GoogleFonts.syne(
                      fontSize: ScreenConfig.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.background,
                    ),
                  ),
                  SizedBox(height: ScreenConfig.spaceXS),
                  Text(
                    'Professional Club Management',
                    style: GoogleFonts.poppins(
                      fontSize: ScreenConfig.fontXS,
                      color: AppTheme.background.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isSmallScreen, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          ScreenConfig.spaceL,
          ScreenConfig.spaceL,
          ScreenConfig.spaceL,
          ScreenConfig.spaceL + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.syne(
                fontSize: ScreenConfig.fontXXL,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenConfig.spaceXS),
            Text(
              'Sign in to continue managing your club',
              style: GoogleFonts.poppins(
                fontSize: ScreenConfig.fontS,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ScreenConfig.spaceXL),
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmailField(
                    controller: emailController,
                    onFieldSubmitted: () => FocusScope.of(context).nextFocus(),
                  ),
                  SizedBox(height: ScreenConfig.spaceM),
                  PasswordField(
                    controller: passwordController,
                    onFieldSubmitted: _loginUser,
                  ),
                  SizedBox(height: ScreenConfig.spaceXS),
                  const ForgotPasswordLink(),
                  SizedBox(height: ScreenConfig.spaceL),
                  GradientButton(
                    label: 'Login',
                    onPressed: _loginUser,
                    isLoading: isLoading,
                  ),
                  SizedBox(height: ScreenConfig.spaceM),
                  OutlinedPrimaryButton(
                    label: 'Create New Organization',
                    leadingIcon: Icons.add_business,
                    onPressed: () {
                      // Navigate to organization creation
                    },
                  ),
                  SizedBox(height: ScreenConfig.spaceM),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
