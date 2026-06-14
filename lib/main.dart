import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:footballtraining/l10n/app_localizations.dart';
import 'package:footballtraining/config/firebase_config.dart';
import 'package:footballtraining/config/environment.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/services/global_messenger_service.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:footballtraining/core/theme/app_theme.dart';
import 'package:footballtraining/core/painters/pitch_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize environment configuration
    await Environment.initialize();

    // Initialize logging service
    LoggingService.initialize();
    LoggingService.info(
        '🚀 Football Training App Starting - Environment: ${Environment.environment}');

    // Initialize Firebase with environment-based configuration
    await FirebaseConfig.initializeFirebase();

    // Load saved language preference
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');

    LoggingService.info('✅ App initialization completed successfully');

    runApp(MyApp(initialLanguage: savedLanguage));
  } catch (error, stackTrace) {
    LoggingService.fatal('💥 App initialization failed', error, stackTrace);

    // Run app with error handling even if initialization fails
    runApp(ErrorApp(error: error.toString()));
  }
}

/// Error app shown when initialization fails
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your configuration and try again.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    // In production, you might want to implement proper restart logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27121),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final String? initialLanguage;

  const MyApp({super.key, this.initialLanguage});

  @override
  State<MyApp> createState() => _MyAppState();

  // Static method to change language from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguage != null) {
      _locale = Locale(widget.initialLanguage!);
    }
  }

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _saveLanguagePreference(locale.languageCode);
  }

  _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize global messenger key
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    GlobalMessengerService.instance.initialize(messengerKey);

    return Builder(
      builder: (context) {
        ScreenConfig.init(context);
        return MaterialApp(
          scaffoldMessengerKey: messengerKey,
          debugShowCheckedModeBanner: false,
          title: 'Football Training',
          theme: AppTheme.darkTheme(),

          // Add localization support
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('hu', ''), // Hungarian
          ],

          // Set the current locale
          locale: _locale,

          // ALWAYS start with language selection screen
          home: const LanguageSelectionScreen(),
        );
      },
    );
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  String? selectedLanguage;
  late AnimationController _logoController;
  late AnimationController _buttonsController;
  late Animation<double> _logoFadeAnimation;
  late Animation<Offset> _buttonsSlideAnimation;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    ));

    _buttonsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutCubic,
    ));

    // Start logo animation immediately
    _logoController.forward();

    // Start button animation with delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _buttonsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            width: double.infinity,
            height: double.infinity,
          ),

          // Pitch pattern overlay
          CustomPaint(
            painter: PitchLinePainter(
              lineColor: AppTheme.textPrimary.withValues(alpha: 0.03),
            ),
            size: Size.infinite,
          ),

          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Section - Logo with Animation
                    FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: Column(
                        children: [
                          // Logo Container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: AppTheme.primaryShadow,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.sports_soccer,
                                size: 56,
                                color: AppTheme.background,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // App Name
                          Text(
                            'FootballMoszgo',
                            style: AppTheme.heading1,
                          ),
                          const SizedBox(height: 8),

                          // Subtitle
                          Text(
                            'CLUB MANAGEMENT',
                            style: AppTheme.overline.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Language Buttons with Animation
                    SlideTransition(
                      position: _buttonsSlideAnimation,
                      child: Row(
                        children: [
                          // English Button
                          Expanded(
                            child: _buildLanguageButton(
                              context,
                              language: 'en',
                              flag: '🇺🇸',
                              label: 'English',
                              width: (screenWidth - 48 - 16) / 2,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Hungarian Button
                          Expanded(
                            child: _buildLanguageButton(
                              context,
                              language: 'hu',
                              flag: '🇭🇺',
                              label: 'Magyar',
                              width: (screenWidth - 48 - 16) / 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Version Text
                    Text(
                      'v1.0.0',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, {
    required String language,
    required String flag,
    required String label,
    required double width,
  }) {
    final isSelected = selectedLanguage == language;

    return GestureDetector(
      onTap: () => _setLanguage(context, language),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setLanguage(BuildContext context, String languageCode) async {
    // Set visual selection
    setState(() {
      selectedLanguage = languageCode;
    });

    // Add small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    // Get context again to avoid async gap warning
    final currentContext = context;

    // Set the language in the app
    MyApp.setLocale(currentContext, Locale(languageCode));

    // Always navigate to login page after language selection
    if (mounted) {
      Navigator.pushReplacement(
        currentContext,
        MaterialPageRoute(builder: (context) => const Loginpage()),
      );
    }
  }
}
