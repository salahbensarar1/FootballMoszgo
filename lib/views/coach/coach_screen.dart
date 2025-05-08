import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:intl/intl.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? coachUid = FirebaseAuth.instance.currentUser?.uid;
  String? selectedTeam;
  String? trainingType;
  String? pitchLocation;
  DateTime? trainingStart;
  DateTime? trainingEnd;
  String? selectedPitch; // NEW: selected pitch location
  TextEditingController notesController = TextEditingController(); // optional

  Map<String, bool> attendance = {};
  Map<String, String> notes = {};
  User? currentUser;
  List<String> trainingTypes = [
    "game",
    "fitness",
    "training match",
    "technical",
    "tactical",
    "theoretical",
    "survey",
    "mixed"
  ];
  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _saveTrainingSession(List<QueryDocumentSnapshot> players) async {
    if (!isTrainingActive) return;

    final sessionData = {
      "coach_uid": coachUid,
      "coach_name": currentUser?.displayName ?? "Unknown",
      "team": selectedTeam,
      "training_type": trainingType,
      "pitch_location": selectedPitch ?? "Not specified",
      "start_time": Timestamp.fromDate(trainingStart!),
      "end_time": Timestamp.fromDate(trainingEnd!),
      "note": notesController.text,
      "players": players.map((player) {
        final playerId = player.id;
        final wasPresent = attendance[playerId] ?? false;
        return {
          "player_id": playerId,
          "name": player['name'],
          "present": wasPresent,
          "minutes": wasPresent ? 120 : 0,
        };
      }).toList(),
    };

    await _firestore.collection("training_sessions").add(sessionData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Training session saved")),
    );
  }

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  void _startTraining() {
    setState(() {
      trainingStart = DateTime.now();
      trainingEnd = trainingStart!.add(const Duration(hours: 2));
    });
  }

  bool get isTrainingActive {
    if (trainingStart == null || trainingEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(trainingStart!) && now.isBefore(trainingEnd!);
  }

  void _saveAttendance(String playerId, String playerName) {
    if (!isTrainingActive) return;
    _firestore.collection('players').doc(playerId).update({
      'Attendance.Presence': attendance[playerId],
      'Attendance.Start_training': Timestamp.fromDate(trainingStart!),
      'Attendance.Finish_training': Timestamp.fromDate(trainingEnd!),
      'Attendance.Training_type': trainingType ?? 'Not specified',
      'Attendance.Notes': notes[playerId] ?? '',
      'Attendance.Pitch': pitchLocation ?? 'Not specified',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance saved for $playerName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coach Screen"),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout), onPressed: () => _logout(context))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .where('coach', isEqualTo: coachUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                List<DropdownMenuItem<String>> teamItems =
                    snapshot.data!.docs.map((doc) {
                  final teamName = doc['team_name'];
                  return DropdownMenuItem<String>(
                    value: teamName,
                    child: Text(teamName),
                  );
                }).toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Team"),
                  value: selectedTeam,
                  items: teamItems,
                  onChanged: (value) {
                    setState(() {
                      selectedTeam = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Training Type"),
              value: trainingType,
              items: trainingTypes
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => trainingType = val),
            ),
            const SizedBox(height: 10),
            TextFormField(
              decoration: const InputDecoration(labelText: "Pitch Location"),
              onChanged: (val) => pitchLocation = val,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedTeam != null &&
                      trainingType != null &&
                      !isTrainingActive
                  ? _startTraining
                  : null,
              child: const Text("Start Training (2-hour window)"),
            ),
            const SizedBox(height: 10),
            if (isTrainingActive)
              Text(
                "Training ends at ${DateFormat('HH:mm').format(trainingEnd!)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            if (selectedTeam != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('players')
                      .where('team', isEqualTo: selectedTeam)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    final players = snapshot.data!.docs;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Players in team: ${players.length}",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: players.length,
                            itemBuilder: (context, index) {
                              final player = players[index];
                              final playerId = player.id;
                              final playerName = player['name'];

                              attendance[playerId] ??= false;
                              notes[playerId] ??= '';

                              return Card(
                                child: ListTile(
                                  title: Text(playerName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Present"),
                                      TextField(
                                        decoration: const InputDecoration(
                                            labelText: "Notes (optional)"),
                                        onChanged: (value) =>
                                            notes[playerId] = value,
                                      ),
                                    ],
                                  ),
                                  trailing: isTrainingActive
                                      ? Switch(
                                          value: attendance[playerId]!,
                                          onChanged: (val) {
                                            setState(() =>
                                                attendance[playerId] = val);
                                          },
                                        )
                                      : const Text("Closed"),
                                  onTap: isTrainingActive
                                      ? () =>
                                          _saveAttendance(playerId, playerName)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () async {
                              final playerSnapshot = await _firestore
                                  .collection('players')
                                  .where('team', isEqualTo: selectedTeam)
                                  .get();

                              await _saveTrainingSession(playerSnapshot.docs);
                            },
                            child: const Text("Save Session"),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
