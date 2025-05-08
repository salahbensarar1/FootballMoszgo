import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/coach/session_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For formatting dates
// Import SessionDetailsScreen if you want to navigate from recent sessions list

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables to hold fetched counts
  int playerCount = 0;
  int teamCount = 0;
  int coachCount = 0;
  bool isLoadingStats = true;

  // State variable for recent sessions stream
  Stream<QuerySnapshot>? recentSessionsStream;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
    _setupRecentSessionsStream();
  }

  // Fetch counts for players, teams, coaches
  Future<void> _fetchCounts() async {
    try {
      // Use aggregate query for efficiency (counts documents without downloading them)
      AggregateQuerySnapshot playerSnap =
          await _firestore.collection('players').count().get();
      AggregateQuerySnapshot teamSnap =
          await _firestore.collection('teams').count().get();
      // Count users where role is 'coach'
      AggregateQuerySnapshot coachSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'coach')
          .count()
          .get();

      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          playerCount = playerSnap.count ?? 0;
          teamCount = teamSnap.count ?? 0;
          coachCount = coachSnap.count ?? 0;
          isLoadingStats = false;
        });
      }
    } catch (e) {
      print("Error fetching counts: $e");
      if (mounted) {
        setState(() => isLoadingStats = false); // Stop loading even on error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error loading statistics.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Setup the stream for recent sessions
  void _setupRecentSessionsStream() {
    // Get the last 5 sessions based on start_time
    recentSessionsStream = _firestore
        .collection('training_sessions')
        .orderBy('start_time', descending: true)
        .limit(5) // Limit to the 5 most recent
        .snapshots(); // Get a stream of updates
  }

  // Helper function to format Timestamps safely
  String _formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMM, HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        flexibleSpace: Container(
          // Optional Gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFF27121), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
        ),
      ),
      body: RefreshIndicator(
        // Add pull-to-refresh
        onRefresh: _fetchCounts, // Re-fetch stats on pull
        child: ListView(
          // Use ListView for scrollability
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Statistics Section ---
            Text(
              "Key Statistics",
              style:
                  GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            isLoadingStats
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()))
                : Wrap(
                    // Use Wrap for responsive layout of stat cards
                    spacing: 16.0, // Horizontal space between cards
                    runSpacing: 16.0, // Vertical space between rows of cards
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Total Players", playerCount.toString(),
                          Icons.person, Colors.blue),
                      _buildStatCard("Total Teams", teamCount.toString(),
                          Icons.group, Colors.green),
                      _buildStatCard("Active Coaches", coachCount.toString(),
                          Icons.sports, Colors.orange),
                      // Add more stats here if needed (e.g., sessions this month)
                    ],
                  ),
            const SizedBox(height: 30),

            // --- Recent Sessions Section ---
            Text(
              "Recent Training Sessions",
              style:
                  GoogleFonts.ubuntu(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildRecentSessionsList(), // Build the list using the StreamBuilder
          ],
        ),
      ),
    );
  }

  // Helper Widget for Stat Cards (Corrected Color Usage)
  Widget _buildStatCard(
      String title, String count, IconData icon, MaterialColor color) {
    // Use MaterialColor type
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 48) / 2;
    cardWidth = cardWidth < 140 ? 140 : cardWidth;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Use the provided MaterialColor directly for background opacity
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 30,
                  color: color), // Use the base MaterialColor for icon
              const SizedBox(height: 10),
              Text(
                count,
                // Access a specific darker shade (e.g., 700 or 900) from the MaterialColor swatch
                style: GoogleFonts.ubuntu(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color.shade700), // Corrected: Use shade property
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: GoogleFonts.ubuntu(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget to build the Recent Sessions List
  Widget _buildRecentSessionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: recentSessionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          print("Error loading recent sessions: ${snapshot.error}");
          return const Center(
              child: Text("Error loading recent sessions.",
                  style: TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No recent sessions found.")));
        }

        // Data available
        var sessions = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true, // Important inside the parent ListView
          physics:
              const NeverScrollableScrollPhysics(), // Disable inner list scroll
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final sessionDoc = sessions[index];
            final data = sessionDoc.data() as Map<String, dynamic>? ?? {};

            // Extract data for the list tile
            String teamName = data['team'] ?? 'N/A';
            String trainingType = data['training_type'] ?? 'N/A';
            Timestamp? startTime = data['start_time'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.event_note,
                      size: 20, color: Colors.indigo),
                ),
                title: Text(
                  "$teamName - $trainingType",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(_formatTimestamp(startTime)), // Format date/time
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey),
                onTap: () {
                  // Navigate to SessionDetailsScreen when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SessionDetailsScreen(sessionDoc: sessionDoc),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
