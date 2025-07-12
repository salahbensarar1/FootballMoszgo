import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:footballtraining/views/login/login_page.dart';
import 'package:intl/intl.dart';
import 'package:footballtraining/data/models/team_model.dart';

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
  TextEditingController notesController = TextEditingController();
  TextEditingController pitchController = TextEditingController();

  Map<String, bool> attendance = {};
  Map<String, String> notes = {};
  User? currentUser;
  String? currentSessionId;
  bool hasEditedSession = false;

  // Training types with icons and colors
  final List<Map<String, dynamic>> trainingTypes = [
    {
      'value': 'game',
      'icon': Icons.sports_soccer,
      'color': Colors.red,
      'gradient': [Colors.red.shade400, Colors.red.shade600]
    },
    {
      'value': 'training',
      'icon': Icons.sports,
      'color': Colors.blue,
      'gradient': [Colors.blue.shade400, Colors.blue.shade600]
    },
    {
      'value': 'tactical',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'gradient': [Colors.purple.shade400, Colors.purple.shade600]
    },
    {
      'value': 'survey',
      'icon': Icons.quiz,
      'color': Colors.teal,
      'gradient': [Colors.teal.shade400, Colors.teal.shade600]
    },
    {
      'value': 'fitness',
      'icon': Icons.fitness_center,
      'color': Colors.orange,
      'gradient': [Colors.orange.shade400, Colors.orange.shade600]
    },
    {
      'value': 'technical',
      'icon': Icons.precision_manufacturing,
      'color': Colors.green,
      'gradient': [Colors.green.shade400, Colors.green.shade600]
    },
    {
      'value': 'theoretical',
      'icon': Icons.school,
      'color': Colors.indigo,
      'gradient': [Colors.indigo.shade400, Colors.indigo.shade600]
    },
    {
      'value': 'mixed',
      'icon': Icons.shuffle,
      'color': Colors.amber,
      'gradient': [Colors.amber.shade400, Colors.amber.shade600]
    },
  ];

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Loginpage()),
      (Route<dynamic> route) => false,
    );
  }

  void _startTraining() {
    setState(() {
      trainingStart = DateTime.now();
      trainingEnd = trainingStart!.add(const Duration(hours: 2));
      hasEditedSession = false;
      currentSessionId = null;
    });
  }

  bool get isTrainingActive {
    if (trainingStart == null || trainingEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(trainingStart!) && now.isBefore(trainingEnd!);
  }

  Future<void> _saveTrainingSession(List<QueryDocumentSnapshot> players,
      {bool isEdit = false}) async {
    final l10n = AppLocalizations.of(context)!;

    if (!isTrainingActive && !isEdit) return;

    String coachName = "Unknown Coach";
    try {
      if (coachUid != null) {
        final coachDoc =
            await _firestore.collection('users').doc(coachUid).get();
        if (coachDoc.exists) {
          coachName = coachDoc.data()?['name'] ??
              currentUser?.displayName ??
              "Unknown Coach";
        }
      }
    } catch (e) {
      print("Error fetching coach name: $e");
    }
    final sessionData = {
      "coach_uid": coachUid,
      "coach_name": coachName,
      "team": selectedTeam,
      "training_type": trainingType,
      "pitch_location": pitchController.text.isNotEmpty
          ? pitchController.text
          : "Not specified",
      "start_time": Timestamp.fromDate(trainingStart!),
      "end_time": Timestamp.fromDate(trainingEnd!),
      "note": notesController.text,
      "created_at": Timestamp.now(),
      "players": players.map((player) {
        final playerId = player.id;
        final wasPresent = attendance[playerId] ?? false;
        return {
          "player_id": playerId,
          "name": player['name'],
          "present": wasPresent,
          "minutes": wasPresent ? 120 : 0,
          "notes": notes[playerId] ?? '',
        };
      }).toList(),
    };

    try {
      if (isEdit && currentSessionId != null) {
        await _firestore
            .collection("training_sessions")
            .doc(currentSessionId)
            .update(sessionData);

        setState(() {
          hasEditedSession = true;
          trainingStart = null;
          trainingEnd = null;
          currentSessionId = null;
          attendance.clear();
          notes.clear();
          selectedTeam = null;
          trainingType = null;
          pitchController.clear();
          notesController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.successfullyUpdated),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final docRef =
            await _firestore.collection("training_sessions").add(sessionData);
        setState(() {
          currentSessionId = docRef.id;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Training session saved! You can edit it once more."),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToUpdate(e.toString())),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildTrainingTypeGrid(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive grid
        double screenWidth = constraints.maxWidth;
        int crossAxisCount =
            screenWidth > 600 ? 4 : 4; // Always 4 columns for mobile
        double itemWidth =
            (screenWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
        double itemHeight = itemWidth * 0.85; // Responsive height

        return SizedBox(
          height: (itemHeight * 2) + 8, // Height for 2 rows plus spacing
          child: GridView.builder(
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: itemWidth / itemHeight,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: trainingTypes.length,
            itemBuilder: (context, index) {
              final type = trainingTypes[index];
              final isSelected = trainingType == type['value'];

              return GestureDetector(
                onTap: () => setState(() => trainingType = type['value']),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: type['gradient'])
                        : LinearGradient(colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade300
                          ]),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: type['color'], width: 2)
                        : Border.all(color: Colors.transparent),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: type['color'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type['icon'],
                        size:
                            screenWidth > 400 ? 20 : 16, // Responsive icon size
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          type['value'],
                          style: TextStyle(
                            fontSize: screenWidth > 400
                                ? 10
                                : 8, // Responsive text size
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimerCard(AppLocalizations l10n) {
    if (!isTrainingActive) return SizedBox.shrink();

    return Card(
      elevation: 8,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.timer, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Training Active",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Ends at ${DateFormat('HH:mm').format(trainingEnd!)}",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${DateTime.now().difference(trainingStart!).inMinutes} min",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF27121), Colors.orange.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          l10n.coachScreen,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth > 400 ? 20 : 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth > 400 ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Selection Card
              Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group, color: Color(0xFFF27121), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.selectTeam,
                              style: TextStyle(
                                fontSize: screenWidth > 400 ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('teams')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();
                          final myTeams = snapshot.data!.docs.where((doc) {
                            try {
                              final team =
                                  Team.fromFirestore(doc); // Use new model
                              return team.activeCoachIds
                                  .contains(coachUid); // Multi-coach support
                            } catch (e) {
                              // Fallback to old structure if team model fails
                              final data = doc.data() as Map<String, dynamic>;
                              return data['coach'] == coachUid;
                            }
                          }).toList();
                          List<DropdownMenuItem<String>> teamItems =
                              myTeams.map((doc) {
                            final data = doc.data()
                                as Map<String, dynamic>; // Convert to Map first
                            final teamName = data['team_name'] ??
                                'Unknown Team'; // Get team name safely
                            return DropdownMenuItem<String>(
                              value: teamName,
                              child: Text(
                                teamName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList();

                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: l10n.team,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.sports_soccer, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            value: selectedTeam,
                            items: teamItems,
                            isExpanded: true,
                            onChanged: isTrainingActive
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedTeam = value;
                                      attendance.clear();
                                      notes.clear();
                                    });
                                  },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Training Type Selection Card
              Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fitness_center,
                              color: Color(0xFFF27121), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.trainingType,
                              style: TextStyle(
                                fontSize: screenWidth > 400 ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildTrainingTypeGrid(l10n),
                    ],
                  ),
                ),
              ),

              // Pitch Location Card
              Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              color: Color(0xFFF27121), size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              l10n.pitchLocation,
                              style: TextStyle(
                                fontSize: screenWidth > 400 ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: pitchController,
                        enabled: !isTrainingActive || currentSessionId != null,
                        decoration: InputDecoration(
                          labelText: l10n.pitchLocation,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.stadium, size: 20),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Start Training Button
              if (!isTrainingActive)
                Container(
                  width: double.infinity,
                  height: screenWidth > 400 ? 56 : 48,
                  margin: EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: selectedTeam != null && trainingType != null
                        ? _startTraining
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFF27121),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill, size: 24),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.startTraining,
                            style: TextStyle(
                              fontSize: screenWidth > 400 ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Timer Card
              _buildTimerCard(l10n),

              // Players List
              if (selectedTeam != null)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('players')
                      .where('team', isEqualTo: selectedTeam)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final players = snapshot.data!.docs;

                    if (players.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                "No players found in this team",
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Initialize attendance for all players
                    for (var player in players) {
                      attendance[player.id] ??= false;
                      notes[player.id] ??= '';
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people,
                                    color: Color(0xFFF27121), size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "${l10n.players}: ${players.length}",
                                    style: TextStyle(
                                      fontSize: screenWidth > 400 ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Players List
                            ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: players.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final player = players[index];
                                final playerId = player.id;
                                final playerName = player['name'];
                                final isPresent = attendance[playerId] ?? false;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isPresent
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: ListTile(
                                    dense: screenWidth < 400,
                                    leading: CircleAvatar(
                                      radius: screenWidth > 400 ? 20 : 16,
                                      backgroundColor: isPresent
                                          ? Colors.green
                                          : Colors.red.shade300,
                                      child: Text(
                                        playerName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth > 400 ? 14 : 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      playerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: screenWidth > 400 ? 16 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: TextField(
                                      decoration: InputDecoration(
                                        labelText: "Notes (optional)",
                                        border: InputBorder.none,
                                        isDense: true,
                                        labelStyle: TextStyle(
                                          fontSize: screenWidth > 400 ? 12 : 10,
                                        ),
                                      ),
                                      onChanged: (value) =>
                                          notes[playerId] = value,
                                      enabled: isTrainingActive,
                                      style: TextStyle(
                                          fontSize:
                                              screenWidth > 400 ? 12 : 10),
                                    ),
                                    trailing: isTrainingActive
                                        ? Switch(
                                            value: isPresent,
                                            onChanged: (val) {
                                              setState(() =>
                                                  attendance[playerId] = val);
                                            },
                                            activeColor: Colors.green,
                                          )
                                        : Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade300,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "Closed",
                                              style: TextStyle(
                                                  fontSize: screenWidth > 400
                                                      ? 12
                                                      : 10),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 20),

                            // Save/Update Session Button
                            if (isTrainingActive)
                              Container(
                                width: double.infinity,
                                height: screenWidth > 400 ? 48 : 44,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final playerSnapshot = await _firestore
                                        .collection('players')
                                        .where('team', isEqualTo: selectedTeam)
                                        .get();

                                    await _saveTrainingSession(
                                      playerSnapshot.docs,
                                      isEdit: currentSessionId != null,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentSessionId != null
                                        ? Colors.orange
                                        : Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(
                                    currentSessionId != null
                                        ? Icons.edit
                                        : Icons.save,
                                    size: screenWidth > 400 ? 20 : 18,
                                  ),
                                  label: Flexible(
                                    child: Text(
                                      currentSessionId != null
                                          ? "Update & Close Session"
                                          : l10n.saveSession,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth > 400 ? 14 : 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
