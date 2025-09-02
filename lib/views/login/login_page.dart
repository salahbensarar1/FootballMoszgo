import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/views/admin/admin_screen.dart';
import 'package:footballtraining/views/coach/coach_screen.dart';
import 'package:footballtraining/views/receptionist/receptionist_screen.dart';
import 'package:footballtraining/views/setup/organization_setup_wizard.dart';
import 'package:footballtraining/views/setup/data_migration_screen.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:footballtraining/utils/responsive_utils.dart';
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
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Animation Controllers
  late AnimationController _animationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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

    try {
      // Sign in with Firebase Auth
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Authentication failed");

      // Find user in organization-scoped collections
      String? userRole;
      String? organizationId;

      // Get all organizations and search for user
      final organizationsSnapshot =
          await FirebaseFirestore.instance.collection('organizations').get();

      for (final orgDoc in organizationsSnapshot.docs) {
        final userQuery = await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgDoc.id)
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          userRole = userData['role'];
          organizationId = orgDoc.id;
          break;
        }
      }

      if (userRole == null || organizationId == null) {
        throw Exception("User not found in any organization");
      }

      // Initialize organization context
      await OrganizationContext.initialize(specificOrgId: organizationId);

      // Navigate based on role
      Widget destination;
      switch (userRole) {
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
          throw Exception("Unauthorized role: $userRole");
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
    if (error.contains('user-not-found')) return l10n.userNotFound;
    if (error.contains('wrong-password')) return l10n.wrongPassword;
    if (error.contains('invalid-email')) return l10n.invalidEmail;
    if (error.contains('user-disabled')) return l10n.userDisabled;
    if (error.contains('too-many-requests')) return l10n.tooManyRequests;
    if (error.contains('network-request-failed')) return l10n.networkError;
    if (error.contains('User not found in any organization'))
      return 'User not registered in any organization.';
    if (error.contains('Unauthorized role'))
      return 'Access denied. Contact your administrator.';
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
        // MozGo Club Logo - STUNNING Championship Design
        Container(
          width: isSmallScreen ? 320 : 380,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFE31E24).withValues(alpha: 0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 50,
                spreadRadius: 8,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: const Color(0xFFE31E24).withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 35 : 45),
          child: Column(
            children: [
              // Championship Badge Background
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 25 : 35,
                  vertical: isSmallScreen ? 20 : 25,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                      Colors.grey.shade100,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Enhanced "moz" with shadow
                    Container(
                      child: Text(
                        'moz',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 42 : 52,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1a1a1a),
                          letterSpacing: -3,
                          height: 0.95,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    // STUNNING "GO" circle with multiple effects
                    Container(
                      width: isSmallScreen ? 75 : 85,
                      height: isSmallScreen ? 75 : 85,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFFF4757), // Bright red
                            const Color(0xFFE31E24), // Main red
                            const Color(0xFFC41E3A), // Deep red
                            const Color(0xFF8B1538), // Darker red
                          ],
                          stops: const [0.0, 0.3, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE31E24).withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFE31E24).withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(47),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                            center: const Alignment(-0.3, -0.3),
                            radius: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'GO',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 26 : 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1.5,
                              height: 0.9,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: const Color(0xFF8B1538).withValues(alpha: 0.5),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: isSmallScreen ? 25 : 35),
              
              // Enhanced Club Info Section
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 25,
                  vertical: isSmallScreen ? 12 : 15,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE31E24).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Main club name
                    Text(
                      'NAGYKŐRÖS',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1a1a1a),
                        letterSpacing: 2.5,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Football Club subtitle
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LABDARÚGÓ KLUB',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFE31E24),
                          letterSpacing: 1.5,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Subtle decorative line
              Container(
                margin: EdgeInsets.only(top: isSmallScreen ? 20 : 25),
                width: isSmallScreen ? 60 : 80,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFE31E24).withValues(alpha: 0.3),
                      const Color(0xFFE31E24),
                      const Color(0xFFE31E24).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
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
              const SizedBox(height: 12),

              // Migration Button (commented out for production)
              // _buildMigrationButton(l10n),
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
          if (value!.length < 6) return l10n.passwordMinLength;
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
        // Navigate to organization setup wizard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const OrganizationSetupWizard(),
          ),
        );
      },
      icon: const Icon(
        Icons.business_outlined,
        color: Color(0xFF667eea),
        size: 20,
      ),
      label: Text(
        l10n.createNewOrganization,
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

  Widget _buildMigrationButton(AppLocalizations l10n) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        // Navigate to data migration screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DataMigrationScreen(),
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
