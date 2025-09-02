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
        // MozGo Club Logo - Artistic Football Design
        Container(
          width: isSmallScreen ? 300 : 340,
          height: isSmallScreen ? 160 : 180,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 25,
                spreadRadius: 3,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Abstract Background Shapes
              Positioned(
                top: -20,
                left: -15,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Positioned(
                bottom: -25,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 20,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Main Content
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Row with Football Elements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left football accent
                          Transform.rotate(
                            angle: -0.3,
                            child: Container(
                              width: 4,
                              height: isSmallScreen ? 16 : 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // "moz" text
                          Text(
                            'moz',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2D3748),
                              letterSpacing: -1,
                              height: 1.0,
                            ),
                          ),
                          
                          // "GO" in dynamic style
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background red circles
                                Container(
                                  width: isSmallScreen ? 44 : 50,
                                  height: isSmallScreen ? 44 : 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE31E24),
                                        Color(0xFFC41E3A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                // "GO" text
                                Text(
                                  'GO',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Football player silhouette icon
                          Transform.rotate(
                            angle: 0.2,
                            child: Icon(
                              Icons.sports_soccer,
                              size: isSmallScreen ? 18 : 22,
                              color: const Color(0xFF2D3748).withValues(alpha: 0.7),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          // Right football accent
                          Transform.rotate(
                            angle: 0.4,
                            child: Container(
                              width: 4,
                              height: isSmallScreen ? 12 : 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE31E24).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Club Info with Style
                      Column(
                        children: [
                          // Dynamic underline
                          Container(
                            width: isSmallScreen ? 60 : 80,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFE31E24),
                                  Colors.transparent,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          
                          // Club name
                          Text(
                            'NAGYKŐRÖS',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                              letterSpacing: 1.5,
                              height: 1.0,
                            ),
                          ),
                          
                          SizedBox(height: 2),
                          
                          // Subtitle
                          Text(
                            'LABDARÚGÓ KLUB',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF718096),
                              letterSpacing: 1.2,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Additional decorative elements
              Positioned(
                bottom: 15,
                left: 20,
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              
              Positioned(
                top: 25,
                left: 60,
                child: Transform.rotate(
                  angle: 0.5,
                  child: Container(
                    width: 2,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE31E24).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
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
