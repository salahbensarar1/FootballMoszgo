import 'package:flutter/material.dart';
import 'package:footballtraining/services/organization_setup_service.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/views/setup/organization_setup_wizard.dart';

/// Smart onboarding screen that determines whether to show login or setup
class OrganizationOnboardingScreen extends StatefulWidget {
  const OrganizationOnboardingScreen({super.key});

  @override
  State<OrganizationOnboardingScreen> createState() =>
      _OrganizationOnboardingScreenState();
}

class _OrganizationOnboardingScreenState
    extends State<OrganizationOnboardingScreen> {
  final _setupService = OrganizationSetupService();
  bool _isLoading = true;
  bool _hasExistingOrganizations = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkOrganizationStatus();
  }

  Future<void> _checkOrganizationStatus() async {
    try {
      LoggingService.info('🔍 Checking organization status...');

      final hasOrgs = await _setupService.hasExistingOrganization();

      setState(() {
        _hasExistingOrganizations = hasOrgs;
        _isLoading = false;
      });

      LoggingService.info(hasOrgs
          ? '✅ Found existing organizations - showing login option'
          : '📋 No organizations found - showing setup option');
    } catch (e) {
      LoggingService.error('❌ Failed to check organization status', e);
      setState(() {
        _errorMessage = 'Failed to check system status. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return _buildOnboardingScreen();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/admin.jpeg', // Your app logo
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.sports_soccer,
                  size: 120,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Setting up your experience...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _checkOrganizationStatus();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E88E5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/admin.jpeg',
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.sports_soccer,
                          size: 120,
                          color: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Football Training Manager',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Manage your football club with ease',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Options Section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Existing Organization Option (if organizations exist)
                    if (_hasExistingOrganizations) ...[
                      _buildOptionCard(
                        icon: Icons.login,
                        title: 'Login to Your Club',
                        subtitle: 'Access your existing football club account',
                        onTap: () => _navigateToLogin(),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New Organization Option
                    _buildOptionCard(
                      icon: Icons.add_business,
                      title: _hasExistingOrganizations
                          ? 'Create New Club'
                          : 'Set Up Your Club',
                      subtitle: _hasExistingOrganizations
                          ? 'Start a new football club from scratch'
                          : 'Get started by creating your football club',
                      onTap: () => _navigateToSetup(),
                      isPrimary: !_hasExistingOrganizations,
                    ),

                    const SizedBox(height: 16),

                    // Debug: Generate Sample Data (only show in debug mode)
                    if (const bool.fromEnvironment('dart.vm.product') == false)
                      _buildDebugOptionCard(
                        icon: Icons.bug_report,
                        title: 'Generate Sample Data',
                        subtitle: 'Create multiple clubs for testing',
                        onTap: () => _navigateToSampleDataGenerator(),
                      ),

                    const SizedBox(height: 32),

                    // Info text
                    Text(
                      _hasExistingOrganizations
                          ? 'Choose your option to continue'
                          : 'Welcome! Let\'s set up your first football club',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Footer
              const Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Complete club isolation • Secure data management',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: isPrimary ? Colors.white : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? const Color(0xFF1E88E5)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isPrimary ? Colors.white : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isPrimary
                              ? const Color(0xFF1E88E5)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isPrimary
                              ? const Color(0xFF1E88E5).withOpacity(0.7)
                              : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isPrimary ? const Color(0xFF1E88E5) : Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    LoggingService.info('👤 User chose to login to existing organization');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _navigateToSetup() {
    LoggingService.info('🏢 User chose to set up new organization');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OrganizationSetupWizard()),
    );
  }

  Widget _buildDebugOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.orange.shade600,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSampleDataGenerator() {
    LoggingService.info('🧪 Sample data generator not available in production build');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample data generation not available in production'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
