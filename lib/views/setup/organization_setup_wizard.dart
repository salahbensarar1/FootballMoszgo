import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/organization_model.dart';
import '../../services/organization_setup_service.dart';
import '../../services/logging_service.dart';
import '../../utils/responsive_design.dart';
import '../login/login_page.dart';
import '../dashboard/dashboard_screen.dart';

/// Fully responsive and optimized organization setup wizard
class OrganizationSetupWizard extends StatefulWidget {
  const OrganizationSetupWizard({super.key});

  @override
  State<OrganizationSetupWizard> createState() => _OrganizationSetupWizardState();
}

class _OrganizationSetupWizardState extends State<OrganizationSetupWizard>
    with TickerProviderStateMixin {
  
  // Controllers and state
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
  
  // Form keys
  final _orgFormKey = GlobalKey<FormState>();
  final _adminFormKey = GlobalKey<FormState>();
  final _receptionistFormKey = GlobalKey<FormState>();
  final _teamFormKey = GlobalKey<FormState>();
  
  // Organization controllers
  final _orgNameController = TextEditingController();
  final _orgAddressController = TextEditingController();
  final _orgPhoneController = TextEditingController();
  final _orgEmailController = TextEditingController();
  final _orgWebsiteController = TextEditingController();
  
  // Admin controllers
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _adminConfirmPasswordController = TextEditingController();
  
  // Receptionist controllers
  final _receptionistNameController = TextEditingController();
  final _receptionistEmailController = TextEditingController();
  final _receptionistPasswordController = TextEditingController();
  final _receptionistConfirmPasswordController = TextEditingController();
  
  // Team controllers
  final _teamNamesControllers = <TextEditingController>[];
  final _monthlyFeeController = TextEditingController(text: '10000');
  
  // Selection state
  OrganizationType _selectedOrgType = OrganizationType.club;
  String _selectedCurrency = 'HUF';
  int _teamCount = 3;
  bool _createSamplePlayers = true;

  static const List<String> _stepTitles = [
    'Welcome', 'Organization', 'Admin', 'Receptionist', 'Teams', 'Payments', 'Complete'
  ];

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
    
    // Organization controllers
    _orgNameController.dispose();
    _orgAddressController.dispose();
    _orgPhoneController.dispose();
    _orgEmailController.dispose();
    _orgWebsiteController.dispose();
    
    // Admin controllers
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _adminConfirmPasswordController.dispose();
    
    // Receptionist controllers
    _receptionistNameController.dispose();
    _receptionistEmailController.dispose();
    _receptionistPasswordController.dispose();
    _receptionistConfirmPasswordController.dispose();
    
    // Team controllers
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
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                _buildHeader(l10n),
                _buildProgressIndicator(),
                Expanded(
                  child: _buildContent(l10n, constraints),
                ),
                _buildNavigationButtons(l10n),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: context.iconSize * 1.5,
            height: context.iconSize * 1.5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF27121), Color(0xFFE94560)],
              ),
              borderRadius: BorderRadius.circular(context.borderRadius),
            ),
            child: Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: context.iconSize,
            ),
          ),
          SizedBox(width: context.spacing()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Football Training Manager',
                  style: GoogleFonts.poppins(
                    fontSize: context.titleFontSize * 0.9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Setup Wizard',
                  style: GoogleFonts.poppins(
                    fontSize: context.captionFontSize,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: context.responsiveHorizontalPadding.copyWith(
        top: context.spacing(factor: 0.5),
        bottom: context.spacing(factor: 0.5),
      ),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
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
                if (index < _stepTitles.length - 1) SizedBox(width: context.spacing(factor: 0.25)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, BoxConstraints constraints) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.maxContentWidth,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildWelcomeStep(l10n),
              _buildOrganizationInfoStep(l10n),
              _buildAdminAccountStep(l10n),
              _buildReceptionistAccountStep(l10n),
              _buildTeamsStep(l10n),
              _buildPaymentSettingsStep(l10n),
              _buildCompletionStep(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: context.spacing(factor: 2)),
          Icon(
            Icons.waving_hand_rounded,
            size: context.isMobile ? 80 : 120,
            color: const Color(0xFFF27121),
          ),
          SizedBox(height: context.spacing(factor: 2)),
          Text(
            'Welcome to Football Training Manager!',
            style: GoogleFonts.poppins(
              fontSize: context.titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.spacing()),
          Text(
            'Let\'s get your football organization set up in just a few minutes. '
            'We\'ll guide you through creating your organization profile, '
            'admin account, teams, and payment settings.',
            style: GoogleFonts.poppins(
              fontSize: context.bodyFontSize,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.spacing(factor: 2)),
          _buildInfoCard(
            icon: Icons.sports_soccer_rounded,
            title: 'Professional Management',
            subtitle: 'Complete solution for football training organizations',
          ),
          SizedBox(height: context.spacing(factor: 2)),
        ],
      ),
    );
  }

  Widget _buildOrganizationInfoStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Form(
        key: _orgFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.spacing()),
            _buildStepTitle('Organization Information'),
            _buildStepSubtitle('Tell us about your football organization'),
            SizedBox(height: context.spacing(factor: 2)),
            
            _buildFormField(
              controller: _orgNameController,
              label: 'Organization Name *',
              hint: 'e.g., Manchester United FC',
              icon: Icons.business_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Organization name is required';
                if (value!.length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _orgAddressController,
              label: 'Address *',
              hint: 'Full address of your organization',
              icon: Icons.location_on_rounded,
              maxLines: 2,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Address is required';
                if (value!.length < 10) return 'Please provide a complete address';
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            Text(
              'Organization Type *',
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.spacing(factor: 0.5)),
            
            _buildOrganizationTypeSelector(),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _orgPhoneController,
              label: 'Phone Number',
              hint: '+36 20 123 4567',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s\(\)]')),
              ],
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{8,}$');
                  if (!phoneRegex.hasMatch(value!)) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _orgEmailController,
              label: 'Email Address',
              hint: 'info@yourclub.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _orgWebsiteController,
              label: 'Website',
              hint: 'https://yourclub.com',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: context.spacing()),
              _buildErrorMessage(_errorMessage!),
            ],
            
            SizedBox(height: context.spacing(factor: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminAccountStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Form(
        key: _adminFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.spacing()),
            _buildStepTitle('Administrator Account'),
            _buildStepSubtitle('Create your administrator account to manage the system'),
            SizedBox(height: context.spacing(factor: 2)),
            
            _buildFormField(
              controller: _adminNameController,
              label: 'Full Name *',
              hint: 'Your full name',
              icon: Icons.person_rounded,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Name is required';
                if (value!.length < 2) return 'Name must be at least 2 characters';
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
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
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _adminPasswordController,
              label: 'Password *',
              hint: 'At least 6 characters',
              icon: Icons.lock_rounded,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password is required';
                if (value!.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _adminConfirmPasswordController,
              label: 'Confirm Password *',
              hint: 'Confirm your password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please confirm your password';
                if (value != _adminPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            
            SizedBox(height: context.spacing(factor: 2)),
            
            _buildInfoCard(
              icon: Icons.security_rounded,
              title: 'Security Notice',
              subtitle: 'This account will have full administrative privileges. '
                       'Keep your credentials secure!',
              color: Colors.amber.shade50,
              borderColor: Colors.amber.shade200,
              iconColor: Colors.amber.shade700,
              textColor: Colors.amber.shade800,
            ),
            
            SizedBox(height: context.spacing(factor: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistAccountStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Form(
        key: _receptionistFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.spacing()),
            _buildStepTitle('Receptionist Account'),
            _buildStepSubtitle('Create a receptionist account for daily operations (optional)'),
            SizedBox(height: context.spacing(factor: 2)),
            
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
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _receptionistEmailController,
              label: 'Email Address',
              hint: 'receptionist@yourclub.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isNotEmpty == true) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value!)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _receptionistPasswordController,
              label: 'Password',
              hint: 'At least 6 characters',
              icon: Icons.lock_rounded,
              obscureText: true,
              validator: (value) {
                if (value?.isNotEmpty == true && value!.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            
            SizedBox(height: context.spacing()),
            
            _buildFormField(
              controller: _receptionistConfirmPasswordController,
              label: 'Confirm Password',
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
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
            ),
            
            SizedBox(height: context.spacing(factor: 2)),
            
            _buildInfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Optional Step',
              subtitle: 'This account will handle day-to-day operations like attendance tracking and player management. You can skip this step and create it later.',
              color: Colors.blue.shade50,
              borderColor: Colors.blue.shade200,
              iconColor: Colors.blue.shade600,
              textColor: Colors.blue.shade800,
            ),
            
            SizedBox(height: context.spacing(factor: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Form(
        key: _teamFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.spacing()),
            _buildStepTitle('Teams Setup'),
            _buildStepSubtitle('Configure your teams and initial settings'),
            SizedBox(height: context.spacing(factor: 2)),
            
            Text(
              'Number of Teams *',
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.spacing(factor: 0.5)),
            
            _buildTeamCountSelector(),
            
            SizedBox(height: context.spacing(factor: 2)),
            
            Text(
              'Team Names *',
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: context.spacing()),
            
            ...List.generate(_teamCount, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: context.spacing()),
                child: _buildFormField(
                  controller: _teamNamesControllers[index],
                  label: 'Team ${index + 1}',
                  hint: 'Enter team name',
                  icon: Icons.groups_rounded,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Team name is required';
                    return null;
                  },
                ),
              );
            }),
            
            SizedBox(height: context.spacing()),
            
            _buildSamplePlayersToggle(),
            
            SizedBox(height: context.spacing(factor: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSettingsStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.spacing()),
          _buildStepTitle('Payment Settings'),
          _buildStepSubtitle('Configure default payment settings for your organization'),
          SizedBox(height: context.spacing(factor: 2)),
          
          Text(
            'Monthly Training Fee *',
            style: GoogleFonts.poppins(
              fontSize: context.captionFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: context.spacing()),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isVerySmall = constraints.maxWidth < 320;
              if (isVerySmall) {
                // Stack vertically on very small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFormField(
                      controller: _monthlyFeeController,
                      label: 'Amount',
                      hint: '10000',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Fee is required';
                        final fee = double.tryParse(value!);
                        if (fee == null || fee < 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: context.spacing()),
                    _buildCurrencySelector(),
                  ],
                );
              } else {
                // Side by side layout with constrained flex ratios for small screens
                return Row(
                  children: [
                    Expanded(
                      flex: context.isMobile ? 2 : 3,
                      child: _buildFormField(
                        controller: _monthlyFeeController,
                        label: 'Amount',
                        hint: '10000',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Fee is required';
                          final fee = double.tryParse(value!);
                          if (fee == null || fee < 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: context.spacing(factor: 0.5)),
                    Expanded(
                      flex: 1,
                      child: _buildCurrencySelector(),
                    ),
                  ],
                );
              }
            },
          ),
          
          SizedBox(height: context.spacing(factor: 2)),
          
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Payment Configuration',
            subtitle: 'You can modify these settings later from the admin panel. This is just the default fee structure.',
            color: Colors.blue.shade50,
            borderColor: Colors.blue.shade200,
            iconColor: Colors.blue.shade600,
            textColor: Colors.blue.shade700,
          ),
          
          SizedBox(height: context.spacing(factor: 2)),
        ],
      ),
    );
  }

  Widget _buildCompletionStep(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: context.spacing(factor: 2)),
          Container(
            width: context.isMobile ? 80 : 120,
            height: context.isMobile ? 80 : 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF27121),
              borderRadius: BorderRadius.circular(context.borderRadius * 2),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: context.isMobile ? 40 : 60,
            ),
          ),
          SizedBox(height: context.spacing(factor: 2)),
          Text(
            'Setup Complete!',
            style: GoogleFonts.poppins(
              fontSize: context.titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: context.spacing()),
          Text(
            'Your football training organization is ready to go! '
            'You can now start managing teams, players, and training sessions.',
            style: GoogleFonts.poppins(
              fontSize: context.bodyFontSize,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.spacing(factor: 3)),
          _buildCompletionSummary(),
          SizedBox(height: context.spacing(factor: 2)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalizations l10n) {
    return Container(
      padding: context.responsivePadding.copyWith(
        bottom: context.responsivePadding.bottom + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, context.buttonHeight),
                  side: const BorderSide(color: Color(0xFFF27121)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF27121),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacing()),
          ],
          
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF27121),
                minimumSize: Size(double.infinity, context.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.borderRadius),
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
                        fontSize: context.captionFontSize,
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

  // Helper widgets
  Widget _buildStepTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: context.titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStepSubtitle(String subtitle) {
    return Padding(
      padding: EdgeInsets.only(top: context.spacing(factor: 0.5)),
      child: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: context.captionFontSize,
          color: Colors.grey.shade600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.spacing(factor: 0.25)),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: context.bodyFontSize),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFFF27121)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.borderRadius),
              borderSide: const BorderSide(color: Color(0xFFF27121)),
            ),
            contentPadding: EdgeInsets.all(context.spacing()),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    Color? borderColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      padding: EdgeInsets.all(context.spacing()),
      decoration: BoxDecoration(
        color: color ?? Colors.blue.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: borderColor ?? Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            color: iconColor ?? Colors.blue.shade600,
            size: context.iconSize,
          ),
          SizedBox(width: context.spacing(factor: 0.75)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: context.spacing(factor: 0.25)),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: context.captionFontSize,
                    color: textColor ?? Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationTypeSelector() {
    return Wrap(
      spacing: context.spacing(factor: 0.5),
      runSpacing: context.spacing(factor: 0.5),
      children: OrganizationType.values.map((type) {
        final isSelected = _selectedOrgType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedOrgType = type),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing(),
              vertical: context.spacing(factor: 0.5),
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF27121) : Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(
                color: isSelected ? const Color(0xFFF27121) : Colors.grey.shade300,
              ),
            ),
            child: Text(
              type.name.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamCountSelector() {
    return Wrap(
      spacing: context.spacing(factor: 0.5),
      children: List.generate(5, (index) {
        final count = index + 1;
        final isSelected = _teamCount == count;
        return GestureDetector(
          onTap: () => setState(() => _teamCount = count),
          child: Container(
            width: context.buttonHeight,
            height: context.buttonHeight,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF27121) : Colors.white,
              borderRadius: BorderRadius.circular(context.borderRadius),
              border: Border.all(
                color: isSelected ? const Color(0xFFF27121) : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: GoogleFonts.poppins(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSamplePlayersToggle() {
    return Row(
      children: [
        Switch.adaptive(
          value: _createSamplePlayers,
          onChanged: (value) => setState(() => _createSamplePlayers = value),
          activeColor: const Color(0xFFF27121),
        ),
        SizedBox(width: context.spacing(factor: 0.5)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create sample players',
                style: GoogleFonts.poppins(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              Text(
                'Add 5 sample players to each team for testing',
                style: GoogleFonts.poppins(
                  fontSize: context.captionFontSize,
                  color: Colors.green.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    const currencies = ['HUF', 'EUR', 'USD', 'GBP'];
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.borderRadius),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing(factor: 0.75),
          vertical: context.spacing(factor: 0.75),
        ),
      ),
      style: TextStyle(
        fontSize: context.bodyFontSize * 0.9,
        color: Colors.grey.shade700,
      ),
      items: currencies.map((currency) => DropdownMenuItem(
        value: currency,
        child: Text(
          currency,
          style: TextStyle(
            fontSize: context.bodyFontSize * 0.9,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (value) => setState(() => _selectedCurrency = value!),
      isExpanded: true, // This prevents overflow in dropdown items
    );
  }

  Widget _buildCompletionSummary() {
    return Container(
      padding: EdgeInsets.all(context.spacing()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setup Summary',
            style: GoogleFonts.poppins(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: context.spacing()),
          _buildSummaryRow('Organization', _orgNameController.text),
          _buildSummaryRow('Admin Email', _adminEmailController.text),
          if (_receptionistEmailController.text.isNotEmpty)
            _buildSummaryRow('Receptionist', _receptionistEmailController.text),
          _buildSummaryRow('Teams', '$_teamCount teams configured'),
          _buildSummaryRow('Monthly Fee', '${_monthlyFeeController.text} $_selectedCurrency'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacing(factor: 0.25)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: EdgeInsets.all(context.spacing()),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          SizedBox(width: context.spacing(factor: 0.5)),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: context.captionFontSize,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
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
      bool canProceed = false;
      
      switch (_currentStep) {
        case 0:
          canProceed = true;
          break;
        case 1:
          canProceed = _orgFormKey.currentState?.validate() ?? false;
          if (canProceed) {
            _organization = await _setupService.createOrganization(
              name: _orgNameController.text.trim(),
              address: _orgAddressController.text.trim(),
              type: _selectedOrgType,
              phoneNumber: _orgPhoneController.text.trim().isEmpty 
                  ? null : _orgPhoneController.text.trim(),
              email: _orgEmailController.text.trim().isEmpty 
                  ? null : _orgEmailController.text.trim(),
              website: _orgWebsiteController.text.trim().isEmpty 
                  ? null : _orgWebsiteController.text.trim(),
            );
          }
          break;
        case 2:
          canProceed = _adminFormKey.currentState?.validate() ?? false;
          if (canProceed && _organization != null) {
            _adminEmail = _adminEmailController.text.trim();
            _adminPassword = _adminPasswordController.text.trim();
            
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
            await _setupService.configurePaymentSettings(
              organizationId: _organization!.id,
              defaultMonthlyFee: double.parse(_monthlyFeeController.text),
              currency: _selectedCurrency,
            );
          }
          break;
        case 6:
          if (_organization != null) {
            await _setupService.completeSetup(_organization!.id);
            
            if (_adminEmail != null && _adminPassword != null) {
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: _adminEmail!,
                  password: _adminPassword!,
                );
                
                LoggingService.info('Admin user auto-logged in successfully');
                
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  );
                }
              } catch (e) {
                LoggingService.error('Auto-login failed, redirecting to login', e);
                
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const Loginpage()),
                  );
                }
              }
            } else {
              if (mounted) {
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
      
      _progressController.animateTo(_currentStep / 6);
    }
  }
}