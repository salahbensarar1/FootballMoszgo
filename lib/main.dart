import 'package:flutter/material.dart';
import 'package:footballtraining/config/firebase_config.dart';

import 'package:footballtraining/views/login/login_page.dart';
// ✅ Ensure FirebaseAuth is imported

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // ✅ Ensures Flutter bindings are ready
  await FirebaseConfig.initializeFirebase(); // ✅ Firebase initializes only once
// ✅ Run this once, then comment it out to prevent duplicate entries

  //await addSamplePlayers();
  //await _addSampleTrainingSession();

  runApp(const MyApp());
}

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        useMaterial3: true,
      ),
      home: Loginpage(),
    );
  }
}
