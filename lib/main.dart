import 'package:flutter/material.dart';
import 'package:footballtraining/firebaseConfig.dart'; // Your Firebase config import
import 'package:provider/provider.dart'; // Import Provider package
import 'providers/theme_provider.dart'; // Import your ThemeProvider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core for initializeApp

import 'loginPage.dart'; // Your Login Page

void main() async {
  // Ensure Flutter bindings are initialized *before* using Flutter/Firebase services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using your configuration class
  // Assuming FirebaseConfig.initializeFirebase handles initializeApp()
  await FirebaseConfig.initializeFirebase();

  // Remove or keep sample data functions commented out as needed
  // await addSamplePlayers();
  // await _addSampleTrainingSession();

  runApp(const MyApp()); // Run the main application widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Provide the ThemeProvider to the widget tree ---
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // Create an instance of ThemeProvider
      child: Consumer<ThemeProvider>( // Use Consumer to listen for theme changes
        builder: (context, themeProvider, child) {
          // --- Build MaterialApp based on the provider's state ---
          return MaterialApp(
            debugShowCheckedModeBanner: false, // Hide debug banner
            title: 'Football Training App', // Set your app title

            // --- Light Theme Definition ---
            theme: ThemeData(
                brightness: Brightness.light, // Explicitly set brightness
                // Define your light theme colors and properties
                colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFFF27121), // Use your primary color as seed
                    brightness: Brightness.light // Ensure colors generated are for light theme
                ),
                primarySwatch: Colors.orange, // Keeps some components like sliders themed
                useMaterial3: true, // Enable Material 3 features
                // Add other light theme customizations here (e.g., text themes)
                appBarTheme: const AppBarTheme(
                    backgroundColor: Color(0xFFF27121), // Example light AppBar color
                    foregroundColor: Colors.white // Example light AppBar text/icon color
                )
            ),

            // --- Dark Theme Definition ---
            darkTheme: ThemeData(
              brightness: Brightness.dark, // Explicitly set brightness
              // Define your dark theme colors and properties
              colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFFF27121), // Use same seed for consistency
                  brightness: Brightness.dark // Ensure colors generated are for dark theme
              ),
              primarySwatch: Colors.orange, // Still useful for some components
              scaffoldBackgroundColor: Colors.grey.shade900, // Dark background
              appBarTheme: AppBarTheme(
                  backgroundColor: Colors.grey.shade800, // Darker AppBar
                  foregroundColor: Colors.white // Keep text/icons visible
              ),
              useMaterial3: true,
              // Add other dark theme customizations here
            ),

            // --- Set ThemeMode from Provider ---
            themeMode: themeProvider.themeMode, // Tells MaterialApp which theme to use

            // --- Initial Screen ---
            home: const Loginpage(), // Your app's starting point (Login Page)

            // Define routes if you use named navigation
            // routes: { ... },
          );
        },
      ),
    );
  }
}


// --- Sample Data Functions (Keep commented out or remove if not needed) ---
/*
Future<void> _addSampleTrainingSession() async { ... }
Future<void> addSamplePlayers() async { ... }
*/

// ***********************************************************//
// Future<void> _addSampleTrainingSession() async {
//   FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Sample session data
//   List<Map<String, dynamic>> playerData = [
//     {
//       'player_id': 'player_1_id',
//       'attendance': true,
//       'goals': 2,
//       'assists': 1,
//       'notes': 'Excellent performance, good passing.'
//     },
//     {
//       'player_id': 'player_2_id',
//       'attendance': false,
//       'goals': 0,
//       'assists': 0,
//       'notes': 'Was absent, no performance data.'
//     },
//   ];
//
//   // Create the training session document
//   try {
//     await _firestore.collection('training_sessions').add({
//       'session_date': Timestamp.now(),  // Current date and time
//       'player_data': playerData,  // Player data for the session
//     });
//     print('Sample session added successfully');
//   } catch (e) {
//     print('Error adding sample session: $e');
//   }
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Football Training',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text("Football Training App"),
//         ),
//         body: Center(
//           child: Text('Welcome to the Training App'),
//         ),
//       ),
//     );
//   }
// }

// ***********************************************************//
// ✅ Function to add sample players to Firestore
// Future<void> addSamplePlayers() async {
//   var players = [
//     {"name": "John Doe", "age": 22, "position": "Forward"},
//     {"name": "David Smith", "age": 24, "position": "Midfielder"},
//     {"name": "Mike Johnson", "age": 21, "position": "Defender"},
//   ];
//
//   for (var player in players) {
//     await FirebaseFirestore.instance.collection('players').add({
//       'name': player['name'],
//       'age': player['age'],
//       'position': player['position'],
//       'attendance': false, // Default attendance
//       'stats': {'goals': 0, 'assists': 0},
//       'injuries': [],
//     });
//   }
//   print("✅ Sample players added successfully!");
// }
// ***********************************************************//


