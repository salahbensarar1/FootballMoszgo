import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/views/admin/admin_screen.dart';
import 'package:footballtraining/views/coach/coach_screen.dart';
import 'package:footballtraining/views/receptionist/receptionist_screen.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // State
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    HapticFeedback.lightImpact();

    try {
      // Sign in with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Authentication failed");

      // Get user role from Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception("User not found in database");
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final role = userData['role'];

      if (role == null) throw Exception("User role not defined");

      // Navigate based on role
      Widget destination;
      switch (role) {
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
          throw Exception("Unauthorized role: $role");
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
    } catch (e) {
      if (mounted) {
        _showErrorMessage(_getErrorMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getErrorMessage(String error) {
    final l10n = AppLocalizations.of(context)!;
    if (error.contains('user-not-found'))
      return l10n.userNotFound;
    if (error.contains('wrong-password')) return l10n.wrongPassword;
    if (error.contains('invalid-email')) return l10n.invalidEmail;
    if (error.contains('user-disabled')) return l10n.userDisabled;
    if (error.contains('too-many-requests'))
      return l10n.tooManyRequests;
    if (error.contains('network-request-failed'))
      return l10n.networkError;
    return l10n.loginFailed;
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
                    padding: ResponsiveUtils.getPadding(context,
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
                        SizedBox(height: ResponsiveUtils.getSpacing(context,
                          mobile: 40.0,
                          tablet: 60.0,
                          desktop: 80.0,
                        )),
                        ResponsiveUtils.responsiveLayout(
                          context: context,
                          mobile: SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildLoginForm(isMobile, l10n),
                            ),
                          ),
                          tablet: Container(
                            width: ResponsiveUtils.getWidthPercentage(context, tablet: 0.6),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: _buildLoginForm(false, l10n),
                              ),
                            ),
                          ),
                          desktop: Container(
                            width: ResponsiveUtils.getWidthPercentage(context, desktop: 0.4),
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
        // Animated Logo
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: isSmallScreen ? 80 : 100,
                height: isSmallScreen ? 80 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sports_soccer,
                  size: isSmallScreen ? 40 : 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
        SizedBox(height: isSmallScreen ? 20 : 30),

        // App Title
        Text(
          l10n.appTitle,
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
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
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isSmallScreen, AppLocalizations l10n) {
    return Container(
      constraints:
          BoxConstraints(maxWidth: isSmallScreen ? double.infinity : 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              // Form Title
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

              // Email Field
              _buildEmailField(l10n),
              SizedBox(height: isSmallScreen ? 16 : 20),

              // Password Field
              _buildPasswordField(l10n),
              SizedBox(height: isSmallScreen ? 30 : 40),

              // Login Button
              _buildLoginButton(isSmallScreen, l10n),
              SizedBox(height: isSmallScreen ? 20 : 24),

              // Admin Button
              _buildAdminButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _emailFocused ? const Color(0xFF667eea) : Colors.grey.shade300,
          width: _emailFocused ? 2 : 1,
        ),
        boxShadow: _emailFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        onChanged: (_) => setState(() {}),
        onTap: () => setState(() => _emailFocused = true),
        onFieldSubmitted: (_) => setState(() => _emailFocused = false),
        onEditingComplete: () => setState(() => _emailFocused = false),
        validator: (value) {
          final l10n = AppLocalizations.of(context)!;
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
            color:
                _emailFocused ? const Color(0xFF667eea) : Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _passwordFocused ? const Color(0xFF667eea) : Colors.grey.shade300,
          width: _passwordFocused ? 2 : 1,
        ),
        boxShadow: _passwordFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        onChanged: (_) => setState(() {}),
        onTap: () => setState(() => _passwordFocused = true),
        onFieldSubmitted: (_) {
          setState(() => _passwordFocused = false);
          _loginUser();
        },
        onEditingComplete: () => setState(() => _passwordFocused = false),
        validator: (value) {
          final l10n = AppLocalizations.of(context)!;
          if (value?.isEmpty ?? true) return l10n.pleaseEnterPassword;
          if (value!.length < 6)
            return l10n.passwordMinLength;
          return null;
        },
        decoration: InputDecoration(
          hintText: l10n.password,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: _passwordFocused
                ? const Color(0xFF667eea)
                : Colors.grey.shade500,
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallScreen, AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Icon(
                    Icons.login,
                    color: Colors.white,
                    size: isSmallScreen ? 20 : 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.loginButton,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdminButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        // Add admin management navigation if needed
      },
      icon: const Icon(
        Icons.admin_panel_settings_outlined,
        color: Color(0xFF667eea),
        size: 20,
      ),
      label: Text(
        l10n.adminManagement,
        style: const TextStyle(
          color: Color(0xFF667eea),
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
