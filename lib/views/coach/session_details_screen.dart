import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/player/player_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SessionDetailsScreen extends StatefulWidget {
  final DocumentSnapshot sessionDoc; // The specific training_session document

  const SessionDetailsScreen({super.key, required this.sessionDoc});

  @override
  State<SessionDetailsScreen> createState() => _SessionDetailsScreenState();
}

class _SessionDetailsScreenState extends State<SessionDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  late Map<String, dynamic> sessionData;
  String coachName = 'Loading...';
  bool isLoadingCoach = true;
  List<Map<String, dynamic>> playerAttendanceList =
      []; // Store extracted player list

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
      sessionData = {}; // Initialize with empty map to avoid null errors later
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Error: Session data not found.'),
                backgroundColor: Colors.red),
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
        // Use map and whereType to handle potential non-map elements safely
        playerAttendanceList = playersRaw
            .map((player) => player is Map<String, dynamic> ? player : null)
            .whereType<Map<String, dynamic>>() // Filter out nulls
            .toList();

        // Sort players alphabetically by name
        playerAttendanceList
            .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      } catch (e) {
        print(
            "Error parsing players list for session ${widget.sessionDoc.id}: $e");
        playerAttendanceList = []; // Set to empty list on error
      }
    } else {
      playerAttendanceList = []; // Ensure it's empty if playersRaw is null
    }
  }

  // Fetch coach's name using the coach_uid
  Future<void> _fetchCoachName() async {
    // Ensure sessionData is initialized before accessing it
    if (sessionData.isEmpty) {
      setState(() => isLoadingCoach = false);
      return;
    }

    final String? coachId = sessionData['coach_uid'] as String?;
    if (coachId != null && coachId.isNotEmpty) {
      try {
        final coachDoc =
            await _firestore.collection('users').doc(coachId).get();
        if (mounted) {
          // Check if widget is still in the tree
          if (coachDoc.exists) {
            setState(() {
              coachName =
                  (coachDoc.data() as Map<String, dynamic>)['name'] ?? 'N/A';
            });
          } else {
            setState(() {
              coachName = 'Coach Not Found';
            });
          }
        }
      } catch (e) {
        print("Error fetching coach name: $e");
        if (mounted) {
          setState(() {
            coachName = 'Error Loading Coach';
          });
        }
      } finally {
        if (mounted) {
          setState(() => isLoadingCoach = false);
        }
      }
    } else {
      if (mounted) {
        setState(() {
          // Fallback to potentially stored coach_name if UID is missing
          coachName = sessionData['coach_name'] ?? 'N/A';
          isLoadingCoach = false;
        });
      }
    }
  }

  // --- Session Report Generation ---
  Future<void> _generateSessionReport() async {
    final pdf = pw.Document();

    // Extract data from state safely
    final String teamName = sessionData['team'] ?? 'N/A';
    final String trainingType = sessionData['training_type'] ?? 'N/A';
    final Timestamp? startTime = sessionData['start_time'] as Timestamp?;
    final Timestamp? endTime = sessionData['end_time'] as Timestamp?;
    final String pitchLocation = sessionData['pitch_location'] ?? 'N/A';
    final String sessionNote = sessionData['note'] ?? '';
    final String currentCoachName =
        coachName; // Use the fetched/state coach name

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) => pw.Header(
          level: 0,
          child: pw.Text('Training Session Report: $teamName',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        build: (pw.Context context) => [
          // Session Details Table
          pw.Header(level: 1, text: 'Session Details'),
          pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(100),
                1: const pw.FlexColumnWidth(),
              },
              children: [
                _buildPdfTableRow('Date:',
                    _formatTimestamp(startTime, format: 'EEE, dd MMM yyyy')),
                _buildPdfTableRow('Time:',
                    "${_formatTimestamp(startTime, format: 'HH:mm')} - ${_formatTimestamp(endTime, format: 'HH:mm')}"),
                _buildPdfTableRow('Team:', teamName),
                _buildPdfTableRow('Training Type:', trainingType),
                _buildPdfTableRow('Coach:', currentCoachName),
                _buildPdfTableRow('Location:', pitchLocation),
                if (sessionNote.isNotEmpty)
                  _buildPdfTableRow('Session Notes:', sessionNote),
              ]),
          pw.SizedBox(height: 25),

          // Player Attendance Table
          pw.Header(
              level: 1,
              text: 'Player Attendance (${playerAttendanceList.length})'),
          if (playerAttendanceList.isEmpty)
            pw.Center(child: pw.Text('No players recorded for this session.'))
          else
            pw.TableHelper.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {1: pw.Alignment.center}, // Center align status
              headers: ['Player Name', 'Status'],
              data: playerAttendanceList.map((playerMap) {
                final String playerName = playerMap['name'] ?? 'Unknown';
                final bool isPresent = playerMap['present'] ?? false;
                return [playerName, isPresent ? 'Present' : 'Absent'];
              }).toList(),
            ),
        ],
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(color: PdfColors.grey)),
        ),
      ),
    );

    // Use Printing Package
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Session_Report_${teamName}_${_formatTimestamp(startTime, format: 'yyyyMMdd')}.pdf',
      );
    } catch (e) {
      print("Error generating/sharing session PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error generating PDF report.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper for PDF table rows
  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child:
            pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value),
      ),
    ]);
  }

  // Helper to format Timestamps
  String _formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMM yyyy, HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Helper to navigate to player details
  void _navigateToPlayerDetails(String playerId) async {
    if (playerId.isEmpty) {
      print("Player ID is empty, cannot navigate.");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cannot load details: Missing player ID.'),
            backgroundColor: Colors.orange));
      return;
    }
    try {
      // Show loading indicator while fetching
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()));

      DocumentSnapshot playerDoc =
          await _firestore.collection('players').doc(playerId).get();

      if (mounted) Navigator.pop(context); // Dismiss loading indicator

      if (playerDoc.exists && mounted) {
        // Use the imported PlayerDetailsScreen
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PlayerDetailsScreen(playerDoc: playerDoc)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Player details not found.'),
            backgroundColor: Colors.orange));
      }
    } catch (e) {
      print("Error fetching player doc $playerId: $e");
      if (mounted) {
        Navigator.pop(context); // Dismiss loading indicator on error too
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error loading player details.'),
            backgroundColor: Colors.red));
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
    final sessionNote = sessionData['note'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Session: $teamName'),
        flexibleSpace: Container(
          // Optional Gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFF27121), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
        ),
        actions: [
          // --- Report Button Action ---
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Generate Session Report',
            onPressed: sessionData.isEmpty
                ? null
                : _generateSessionReport, // Disable if data is empty
          ),
          // --------------------------
        ],
      ),
      body: sessionData.isEmpty // Show loading or error if sessionData is empty
          ? const Center(child: Text("Loading session details..."))
          : ListView(
              // Use ListView for scrollable content
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  "Session Details",
                  style: GoogleFonts.ubuntu(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.group, "Team:", teamName),
                        _buildDetailRow(
                            Icons.fitness_center, "Type:", trainingType),
                        _buildDetailRow(Icons.timer_outlined, "Starts:",
                            _formatTimestamp(startTime)),
                        _buildDetailRow(Icons.timer_off_outlined, "Ends:",
                            _formatTimestamp(endTime)),
                        _buildDetailRow(Icons.location_on_outlined, "Location:",
                            pitchLocation),
                        _buildDetailRow(Icons.person_outline, "Coach:",
                            isLoadingCoach ? "Loading..." : coachName),
                        if (sessionNote.isNotEmpty)
                          _buildDetailRow(Icons.notes, "Notes:", sessionNote),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text(
                  "Player Attendance (${playerAttendanceList.length})",
                  style: GoogleFonts.ubuntu(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Display Player List Section
                _buildPlayerAttendanceList(),

                const SizedBox(height: 20), // Add space at the bottom
              ],
            ),
    );
  }

  // Helper to build the player attendance list
  Widget _buildPlayerAttendanceList() {
    if (playerAttendanceList.isEmpty) {
      if (sessionData['players'] == null ||
          (sessionData['players'] as List).isEmpty) {
        return const Center(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("No players recorded for this session."),
        ));
      } else {
        return const Center(
            child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("Processing player list..."),
        ));
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playerAttendanceList.length,
      itemBuilder: (context, index) {
        final playerMap = playerAttendanceList[index];
        final String playerName = playerMap['name'] ?? 'Unknown Player';
        final String playerId = playerMap['player_id'] ?? '';
        final bool isPresent = playerMap['present'] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1, // Subtle elevation
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)), // Rounded corners
          child: ListTile(
            leading: Icon(
              isPresent ? Icons.check_circle : Icons.cancel_outlined,
              color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
            ),
            title: Text(playerName),
            trailing:
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            onTap: () {
              _navigateToPlayerDetails(playerId); // Navigate on tap
            },
          ),
        );
      },
    );
  }

  // Helper widget to build detail rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.ubuntu(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
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
} // End of _SessionDetailsScreenState
