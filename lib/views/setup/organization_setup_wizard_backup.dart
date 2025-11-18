import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/organization_model.dart';
import '../../services/organization_setup_service.dart';
import '../../services/logging_service.dart';
import '../login/login_page.dart';
import '../dashboard/dashboard_screen.dart';

/// Multi-step organization setup wizard for first-time users
class OrganizationSetupWizard extends StatefulWidget {
  const OrganizationSetupWizard({super.key});

  @override
  State<OrganizationSetupWizard> createState() =>
      _OrganizationSetupWizardState();
}

class _OrganizationSetupWizardState extends State<OrganizationSetupWizard>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OrganizationSetupService _setupService = OrganizationSetupService();

  // Animation Controllers
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;

  // Current state
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Setup data
  Organization? _organization;
  String? _adminEmail;
  String? _adminPassword;

  // Form controllers
  final _orgFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _receptionistFormKey = GlobalKey<FormState>();
  final _teamFormKey = GlobalKey<FormState>();

  final _orgNameController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  final _orgWebsiteController = TextEditingController();

  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();

  final _receptionistNameController = TextEditingController();
  final _receptionistEmailController = TextEditingController();
  final _receptionistPasswordController = TextEditingController();
  final _receptionistConfirmPasswordController = TextEditingController();

  final _teamNamesControllers = <TextEditingController>[];
  final _monthlyFeeController = TextEditingController(text: '10000');

  OrganizationType _selectedOrgType = OrganizationType.club;
  String _selectedCurrency = 'HUF';
  int _teamCount = 3;
  bool _createSamplePlayers = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize team name controllers
    for (int i = 0; i < 5; i++) {
      _teamNamesControllers.add(TextEditingController(
        text: i < 3 ? 'Team ${i + 1}' : '',
      ));
    }
  }

  void _disposeControllers() {
    _pageController.dispose();
    _orgNameController.dispose();
    _orgAddressController.dispose();
    _orgPhoneController.dispose();
    _orgEmailController.dispose();
    _orgWebsiteController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    _receptionistNameController.dispose();
    _receptionistEmailController.dispose();
    _receptionistPasswordController.dispose();
    _receptionistConfirmPasswordController.dispose();
    _monthlyFeeController.dispose();
    for (final controller in _teamNamesControllers) {
      controller.dispose();
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(l10n, isTablet),
            _buildProgressIndicator(isTablet),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildWelcomeStep(l10n, isTablet),
                    _buildOrganizationInfoStep(l10n, isTablet),
                    _buildAdminAccountStep(l10n, isTablet),
                    _buildReceptionistAccountStep(l10n, isTablet),
                    _buildTeamsStep(l10n, isTablet),
                    _buildPaymentSettingsStep(l10n, isTablet),
                    _buildCompletionStep(l10n, isTablet),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(l10n, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 60 : 48,
            height: isTablet ? 60 : 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF27121), Color(0xFFE94560)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: isTablet ? 32 : 24,
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Football Training Manager',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  'Setup Wizard',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isTablet) {
    final steps = [
      'Welcome',
      'Organization',
      'Admin',
      'Receptionist',
      'Teams',
      'Payments',
      'Complete'
    ];

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? const Color(0xFFF27121)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < steps.length - 1) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeStep(AppLocalizations l10n, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waving_hand_rounded,
            size: isTablet ? 120 : 80,
            color: const Color(0xFFF27121),
          ),
          SizedBox(height: isTablet ? 48 : 32),
          Text(
            'Welcome to Football Training Manager!',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 24 : 16),
          Text(
            'Let\'s get your football organization set up in just a few minutes. '
            'We\'ll guide you through creating your organization profile, '
            'admin account, teams, and payment settings.',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 48 : 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue.shade600,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'This setup wizard will help you:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ...[
                  '• Create your organization profile',
                  '• Set up your administrator account',
                  '• Add your teams and players',
                  '• Configure payment settings',
                ].map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Continuing with other step widgets...
  Widget _buildOrganizationInfoStep(AppLocalizations l10n, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Form(
        key: _orgFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organization Information',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tell us about your football organization',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Organization Name
            _buildFormField(
              controller: _orgNameController,
              label: 'Organization Name *',
              hint: 'e.g., Chelsea Football Club',
              icon: Icons.business_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Organization name is required';
                if (value!.length < 3)
                  return 'Name must be at least 3 characters';
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Organization Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organization Type *',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: OrganizationType.values.map((type) {
                    final isSelected = _selectedOrgType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedOrgType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF27121)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF27121)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          type.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Address
            _buildFormField(
              controller: _orgAddressController,
              label: 'Address *',
              hint: 'Full address of your organization',
              icon: Icons.location_on_rounded,
              maxLines: 2,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Address is required';
                if (value!.length < 5)
                  return 'Address must be at least 5 characters';
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Phone Number
            _buildFormField(
              controller: _orgPhoneController,
              label: 'Phone Number',
              hint: '+36 20 123 4567',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,}$');
                  if (!phoneRegex.hasMatch(value!)) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Email
            _buildFormField(
              controller: _orgEmailController,
              label: 'Email Address',
              hint: 'info@yourclub.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Website
            _buildFormField(
              controller: _orgWebsiteController,
              label: 'Website',
              hint: 'https://yourclub.com',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
              isTablet: isTablet,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isTablet,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: isTablet ? 16 : 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFFF27121)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF27121)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminAccountStep(AppLocalizations l10n, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Administrator Account',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your administrator account to manage the system',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Name
            _buildFormField(
              controller: _adminNameController,
              label: 'Full Name *',
              hint: 'Your full name',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Name is required';
                if (value!.length < 2)
                  return 'Name must be at least 2 characters';
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Email
            _buildFormField(
              controller: _adminEmailController,
              label: 'Email Address *',
              hint: 'admin@yourclub.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email is required';
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value!)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Password
            _buildFormField(
              controller: _adminPasswordController,
              label: 'Password *',
              hint: 'At least 6 characters',
              icon: Icons.lock_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password is required';
                if (value!.length < 6)
                  return 'Password must be at least 6 characters';
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Confirm Password
            _buildFormField(
              controller: _adminConfirmPasswordController,
              label: 'Confirm Password *',
              hint: 'Confirm your password',
              icon: Icons.lock_outline_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Please confirm your password';
                if (value != _adminPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This account will have full administrative privileges. '
                      'Keep your credentials secure!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistAccountStep(AppLocalizations l10n, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Form(
        key: _receptionistFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receptionist Account',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create a receptionist account for daily operations (optional)',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Name
            _buildFormField(
              controller: _receptionistNameController,
              label: 'Full Name',
              hint: 'Receptionist full name',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value?.isNotEmpty == true && value!.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Email
            _buildFormField(
              controller: _receptionistEmailController,
              label: 'Email Address',
              hint: 'receptionist@yourclub.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Password
            _buildFormField(
              controller: _receptionistPasswordController,
              label: 'Password',
              hint: 'At least 6 characters',
              icon: Icons.lock_rounded,
              validator: (value) {
                if (value?.isNotEmpty == true && value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            // Confirm Password
            _buildFormField(
              controller: _receptionistConfirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              validator: (value) {
                if (_receptionistPasswordController.text.isNotEmpty) {
                  if (value?.isEmpty == true) {
                    return 'Please confirm your password';
                  }
                  if (value != _receptionistPasswordController.text) {
                    return 'Passwords do not match';
                  }
                }
                return null;
              },
              isTablet: isTablet,
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This account will handle day-to-day operations like attendance tracking and player management. You can skip this step and create it later.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsStep(AppLocalizations l10n, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Form(
        key: _teamFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Teams',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set up your teams and configure basic settings',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // Number of teams
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How many teams do you want to create?',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final count = index + 1;
                    final isSelected = _teamCount == count;
                    return GestureDetector(
                      onTap: () => setState(() => _teamCount = count),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF27121)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF27121)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            count.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Team names
            Text(
              'Team Names',
              style: GoogleFonts.poppins(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(_teamCount, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _teamNamesControllers[index],
                  style: GoogleFonts.poppins(fontSize: isTablet ? 16 : 14),
                  decoration: InputDecoration(
                    labelText: 'Team ${index + 1} Name',
                    prefixIcon: const Icon(Icons.groups_rounded,
                        color: Color(0xFFF27121)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Team name is required';
                    return null;
                  },
                ),
              );
            }),

            const SizedBox(height: 24),

            // Sample players option
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _createSamplePlayers,
                    onChanged: (value) =>
                        setState(() => _createSamplePlayers = value ?? false),
                    activeColor: const Color(0xFFF27121),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create sample players',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We\'ll add 5 sample players to each team to help you get started',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSettingsStep(AppLocalizations l10n, bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Settings',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Configure payment settings for your teams',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Currency selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency',
                style: GoogleFonts.poppins(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.attach_money_rounded,
                      color: Color(0xFFF27121)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'HUF', child: Text('Hungarian Forint (HUF)')),
                  DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                  DropdownMenuItem(
                      value: 'USD', child: Text('US Dollar (USD)')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedCurrency = value!),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly fee
          _buildFormField(
            controller: _monthlyFeeController,
            label: 'Default Monthly Fee',
            hint: '10000',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Monthly fee is required';
              final fee = double.tryParse(value!);
              if (fee == null || fee < 0) return 'Please enter a valid amount';
              return null;
            },
            isTablet: isTablet,
          ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.blue.shade600, size: 32),
                const SizedBox(height: 16),
                Text(
                  'Payment Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can adjust individual team fees later. '
                  'The payment system will track monthly payments for all players.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep(AppLocalizations l10n, bool isTablet) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 48 : 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isTablet ? 120 : 80,
            height: isTablet ? 120 : 80,
            decoration: const BoxDecoration(
              color: Color(0xFFF27121),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: isTablet ? 60 : 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            'Setup Complete!',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Your football organization is now ready to use. '
            'You can start managing teams, players, training sessions, and payments.',
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 48 : 32),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Setup Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryItem('Organization', _orgNameController.text),
                _buildSummaryItem('Type', _selectedOrgType.displayName),
                _buildSummaryItem('Admin', _adminNameController.text),
                _buildSummaryItem('Teams', _teamCount.toString()),
                _buildSummaryItem('Currency', _selectedCurrency),
                _buildSummaryItem('Monthly Fee',
                    '${_monthlyFeeController.text} $_selectedCurrency'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalizations l10n, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFFF27121)),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF27121),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF27121),
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _getNextButtonText(),
                      style: GoogleFonts.poppins(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Get Started';
      case 6:
        return 'Complete Setup';
      default:
        return 'Next';
    }
  }

  void _nextStep() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Validate current step
      bool canProceed = false;

      switch (_currentStep) {
        case 0:
          canProceed = true; // Welcome step
          break;
        case 1:
          canProceed = _orgFormKey.currentState?.validate() ?? false;
          if (canProceed) {
            // Create organization
            _organization = await _setupService.createOrganization(
              name: _orgNameController.text.trim(),
              address: _orgAddressController.text.trim(),
              type: _selectedOrgType,
              phoneNumber: _orgPhoneController.text.trim().isEmpty
                  ? null
                  : _orgPhoneController.text.trim(),
              email: _orgEmailController.text.trim().isEmpty
                  ? null
                  : _orgEmailController.text.trim(),
              website: _orgWebsiteController.text.trim().isEmpty
                  ? null
                  : _orgWebsiteController.text.trim(),
            );
          }
          break;
        case 2:
          canProceed = _adminFormKey.currentState?.validate() ?? false;
          if (canProceed && _organization != null) {
            // Store admin credentials for auto-login
            _adminEmail = _adminEmailController.text.trim();
            _adminPassword = _adminPasswordController.text.trim();

            // Create admin user
            await _setupService.createAdminUser(
              organizationId: _organization!.id,
              name: _adminNameController.text.trim(),
              email: _adminEmail!,
              password: _adminPassword!,
            );
          }
          break;
        case 3:
          canProceed = _receptionistFormKey.currentState?.validate() ?? false;
          if (canProceed && _organization != null) {
            // Create receptionist user (optional)
            if (_receptionistEmailController.text.trim().isNotEmpty) {
              await _setupService.createReceptionistUser(
                organizationId: _organization!.id,
                name: _receptionistNameController.text.trim(),
                email: _receptionistEmailController.text.trim(),
                password: _receptionistPasswordController.text.trim(),
              );
            }
          }
          break;
        case 4:
          canProceed = _teamFormKey.currentState?.validate() ?? false;
          if (canProceed && _organization != null) {
            // Create teams
            final teamNames = _teamNamesControllers
                .take(_teamCount)
                .map((controller) => controller.text.trim())
                .where((name) => name.isNotEmpty)
                .toList();

            await _setupService.createInitialTeams(
              organizationId: _organization!.id,
              teamNames: teamNames,
              defaultMonthlyFee: double.parse(_monthlyFeeController.text),
            );

            // Create sample players if requested
            if (_createSamplePlayers) {
              for (final teamName in teamNames) {
                await _setupService.createSamplePlayers(
                  organizationId: _organization!.id,
                  teamName: teamName,
                  playerCount: 5,
                );
              }
            }
          }
          break;
        case 5:
          canProceed = true;
          if (_organization != null) {
            // Configure payment settings
            await _setupService.configurePaymentSettings(
              organizationId: _organization!.id,
              defaultMonthlyFee: double.parse(_monthlyFeeController.text),
              currency: _selectedCurrency,
            );
          }
          break;
        case 6:
          // Complete setup and auto-login admin user
          if (_organization != null) {
            await _setupService.completeSetup(_organization!.id);

            // Auto-login the admin user
            if (_adminEmail != null && _adminPassword != null) {
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _adminEmail!,
                  password: _adminPassword!,
                );

                LoggingService.info('Admin user auto-logged in successfully');

                if (mounted) {
                  // Navigate directly to dashboard
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const DashboardScreen()),
                  );
                }
              } catch (e) {
                LoggingService.error(
                    'Auto-login failed, redirecting to login', e);

                if (mounted) {
                  // Fallback to login screen
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const Loginpage()),
                  );
                }
              }
            } else {
              if (mounted) {
                // Fallback to login screen if no admin credentials
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const Loginpage()),
                );
              }
            }
          }
          return;
      }

      if (canProceed) {
        setState(() {
          _currentStep++;
        });

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );

        // Update progress animation
        _progressController.animateTo(_currentStep / 6);
      }
    } catch (e, stackTrace) {
      LoggingService.error('Setup step failed', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });

      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Update progress animation
      _progressController.animateTo(_currentStep / 6);
    }
  }
}
