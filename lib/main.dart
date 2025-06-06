import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/config/firebase_config.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initializeFirebase();

  // Load saved language preference
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language_code');

  runApp(MyApp(initialLanguage: savedLanguage));
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
    return MaterialApp(
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

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

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

    // Navigate to login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
    );
  }
}
