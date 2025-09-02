import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/config/firebase_config.dart';
import 'package:footballtraining/config/environment.dart';
import 'package:footballtraining/services/logging_service.dart';
import 'package:footballtraining/services/global_messenger_service.dart';
import 'package:footballtraining/views/login/login_page.dart';
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

    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Football Training',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),

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
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF27121), Color(0xFF654ea3), Color(0xFFeaafc8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.language,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              const Text(
                'Select Language\nVálasszon nyelvet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),

              // English Button
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF27121),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🇺🇸', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text('English',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  onPressed: () => _setLanguage(context, 'en'),
                ),
              ),

              const SizedBox(height: 20),

              // Hungarian Button
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFF27121),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🇭🇺', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 10),
                      Text('Magyar',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  onPressed: () => _setLanguage(context, 'hu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setLanguage(BuildContext context, String languageCode) {
    // Set the language in the app
    MyApp.setLocale(context, Locale(languageCode));

    // Always navigate to login page after language selection
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
    );
  }
}
