import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/player_details_screen.dart'; // Import player details screen
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date/time formatting

class SessionDetailsScreen extends StatefulWidget {
  final DocumentSnapshot sessionDoc; // The specific training_session document

  const SessionDetailsScreen({super.key, required this.sessionDoc});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Map<String, dynamic> sessionData;
  String coachName = 'Loading...';
  bool isLoadingCoach = true;
  List<Map<String, dynamic>> playerAttendanceList = []; // Store extracted player list

  @override
  void initState() {
    super.initState();
    // Extract data safely
    if (widget.sessionDoc.exists && widget.sessionDoc.data() != null) {
      sessionData = widget.sessionDoc.data() as Map<String, dynamic>;
      _extractPlayerList(); // Extract the nested player list
      _fetchCoachName(); // Start fetching coach name
    } else {
      // Handle error case where document is invalid
      sessionData = {};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Session data not found.'), backgroundColor: Colors.red),
          );
          Navigator.of(context).pop();
        }
      });
    }
  }

  // Extract and parse the nested player list
  void _extractPlayerList() {
    final List<dynamic>? playersRaw = sessionData['players'] as List<dynamic>?;
    if (playersRaw != null) {
      try {
        playerAttendanceList = playersRaw.map((player) {
          // Ensure each element is treated as a Map
          if (player is Map<String, dynamic>) {
            return player;
          } else {
            // Handle unexpected type if necessary, return an empty map or log error
            print("Warning: Unexpected type found in players array for session ${widget.sessionDoc.id}");
            return <String, dynamic>{};
          }
        }).toList();
        // Sort players alphabetically by name for consistent display
        playerAttendanceList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      } catch (e) {
        print("Error parsing players list for session ${widget.sessionDoc.id}: $e");
        playerAttendanceList = []; // Set to empty list on error
      }
    }
  }

  // Fetch coach's name using the coach_uid
  Future<void> _fetchCoachName() async {
    final String? coachId = sessionData['coach_uid'] as String?;
    if (coachId != null && coachId.isNotEmpty) {
      try {
        final coachDoc = await _firestore.collection('users').doc(coachId).get();
        if (mounted) { // Check if widget is still in the tree
          if (coachDoc.exists) {
            setState(() {
              coachName = (coachDoc.data() as Map<String, dynamic>)['name'] ?? 'N/A';
            });
          } else {
            setState(() { coachName = 'Coach Not Found'; });
          }
        }
      } catch (e) {
        print("Error fetching coach name: $e");
        if (mounted) { setState(() { coachName = 'Error Loading Coach'; }); }
      } finally {
        if (mounted) { setState(() => isLoadingCoach = false); }
      }
    } else {
      if (mounted) {
        setState(() {
          coachName = sessionData['coach_name'] ?? 'N/A'; // Fallback to stored name if UID is missing
          isLoadingCoach = false;
        });
      }
    }
  }

  // Helper to format Timestamps
  String _formatTimestamp(Timestamp? timestamp, {String format = 'dd MMM yyyy, HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) { return 'Invalid Date'; }
  }

  // Helper to navigate to player details
  void _navigateToPlayerDetails(String playerId) async {
    if (playerId.isEmpty) return;
    try {
      DocumentSnapshot playerDoc = await _firestore.collection('players').doc(playerId).get();
      if (playerDoc.exists && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerDetailsScreen(playerDoc: playerDoc)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player details not found.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      print("Error fetching player doc $playerId: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading player details.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract main session details safely
    final teamName = sessionData['team'] ?? 'N/A';
    final trainingType = sessionData['training_type'] ?? 'N/A';
    final startTime = sessionData['start_time'] as Timestamp?;
    final endTime = sessionData['end_time'] as Timestamp?;
    final pitchLocation = sessionData['pitch_location'] ?? 'N/A';
    final sessionNote = sessionData['note'] ?? ''; // Use 'note' field

    return Scaffold(
      appBar: AppBar(
        title: Text('Session: $teamName'), // Dynamic title
        flexibleSpace: Container( // Optional Gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient( colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        // Add actions if needed (e.g., Generate Session Report Button)
        // actions: [ IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _generateSessionReport) ],
      ),
      body: ListView( // Use ListView for scrollable content
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Session Details",
            style: GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(Icons.group, "Team:", teamName),
                  _buildDetailRow(Icons.fitness_center, "Type:", trainingType),
                  _buildDetailRow(Icons.timer_outlined, "Starts:", _formatTimestamp(startTime)),
                  _buildDetailRow(Icons.timer_off_outlined, "Ends:", _formatTimestamp(endTime)),
                  _buildDetailRow(Icons.location_on_outlined, "Location:", pitchLocation),
                  _buildDetailRow(Icons.person_outline, "Coach:", isLoadingCoach ? "Loading..." : coachName),
                  if (sessionNote.isNotEmpty) _buildDetailRow(Icons.notes, "Notes:", sessionNote),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            "Player Attendance (${playerAttendanceList.length})",
            style: GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Display Player List
          _buildPlayerAttendanceList(),

          // Optional: Add report generation button here if needed for the session
          const SizedBox(height: 20),
          // Center( child: ElevatedButton.icon( label: Text("Generate Session Report"), icon: Icon(Icons.picture_as_pdf), onPressed: _generateSessionReport)),
        ],
      ),
    );
  }


  // Helper to build the player attendance list
  Widget _buildPlayerAttendanceList() {
    if (playerAttendanceList.isEmpty) {
      // Check if loading or genuinely empty
      if (sessionData['players'] == null || (sessionData['players'] as List).isEmpty) {
        return const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 20), child: Text("No players recorded for this session."),));
      } else {
        // Might still be parsing or error during parsing
        return const Center(child: Padding( padding: EdgeInsets.symmetric(vertical: 20), child: Text("Processing player list..."),));
      }
    }

    return ListView.builder(
      shrinkWrap: true, // Important inside the parent ListView
      physics: const NeverScrollableScrollPhysics(), // Disable inner list scrolling
      itemCount: playerAttendanceList.length,
      itemBuilder: (context, index) {
        final playerMap = playerAttendanceList[index];
        final String playerName = playerMap['name'] ?? 'Unknown Player';
        final String playerId = playerMap['player_id'] ?? '';
        final bool isPresent = playerMap['present'] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              isPresent ? Icons.check_circle : Icons.cancel_outlined,
              color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
            ),
            title: Text(playerName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Allow tapping to navigate to player details screen
              _navigateToPlayerDetails(playerId);
            },
          ),
        );
      },
    );
  }

  // Helper widget to build detail rows (similar to other detail screens)
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items top if value wraps
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.ubuntu(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded( // Allow value text to wrap
            child: Text(
              value,
              style: GoogleFonts.ubuntu(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

// Placeholder for session report generation if needed in the future
// Future<void> _generateSessionReport() async {
//    // 1. Create PDF document (pw.Document)
//    // 2. Add session details (team, coach, date, etc.)
//    // 3. Add player attendance table using playerAttendanceList
//    // 4. Use Printing.layoutPdf to save/share
//    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session report generation not implemented yet.')));
// }

}