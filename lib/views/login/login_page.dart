import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:footballtraining/views/admin/admin_screen.dart';
import 'package:footballtraining/views/coach/coach_screen.dart';
import 'package:footballtraining/views/receptionist/receptionist_screen.dart';
import 'package:footballtraining/services/auth_service.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
import 'package:footballtraining/views/login/widgets/mozgo_logo.dart';
import 'package:footballtraining/views/login/widgets/login_form_fields.dart';
import 'package:footballtraining/views/login/widgets/login_buttons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.9, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
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
            pageBuilder: (context, animation, secondaryAnimation) => destination,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveUtils.getScreenSize(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: ResponsiveUtils.getPadding(
                      context,
                      mobile: 20.0,
                      tablet: 40.0,
                      desktop: 60.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildHeader(isMobile, l10n),
                        ),
                        SizedBox(
                            height: ResponsiveUtils.getSpacing(
                          context,
                          mobile: 40.0,
                          tablet: 60.0,
                          desktop: 80.0,
                        )),
                        ResponsiveUtils.responsiveLayout(
                          context,
                          mobile: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildLoginForm(isMobile, l10n),
                            ),
                          ),
                          tablet: Container(
                            width: ResponsiveUtils.getWidthPercentage(context,
                                tablet: 0.6),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildLoginForm(false, l10n),
                              ),
                            ),
                          ),
                          desktop: Container(
                            width: ResponsiveUtils.getWidthPercentage(context,
                                desktop: 0.4),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildLoginForm(false, l10n),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, AppLocalizations l10n) {
    return Column(
      children: [
        MozGoLogo(isSmallScreen: isSmallScreen),
        SizedBox(height: isSmallScreen ? 20 : 30),
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          l10n.welcomeBack,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallScreen, AppLocalizations l10n) {
    return Container(
      constraints: BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.login,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: isSmallScreen ? 30 : 40),
              EmailField(
                controller: emailController,
                onFieldSubmitted: () => FocusScope.of(context).nextFocus(),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              PasswordField(
                controller: passwordController,
                onFieldSubmitted: _loginUser,
              ),
              SizedBox(height: isSmallScreen ? 30 : 40),
              LoginButton(
                isSmallScreen: isSmallScreen,
                isLoading: isLoading,
                onPressed: _loginUser,
              ),
              SizedBox(height: isSmallScreen ? 20 : 24),
              const AdminButton(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

}
