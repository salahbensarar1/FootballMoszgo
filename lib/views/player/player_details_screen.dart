import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting

// Import PDF and Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final DocumentSnapshot playerDoc; // Receive the player document

  const PlayerDetailsScreen({super.key, required this.playerDoc});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late Map<String, dynamic> playerData;

  @override
  void initState() {
    super.initState();
    // Extract data, handle potential errors
    if (widget.playerDoc.exists && widget.playerDoc.data() != null) {
      playerData = widget.playerDoc.data() as Map<String, dynamic>;
    } else {
      playerData = {
        'name': 'Error: Data Missing', /* provide defaults */
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error loading player details.'),
              backgroundColor: Colors.red));
          Navigator.of(context).pop();
        }
      });
    }
  }

  // Helper function to format Timestamps safely
  String _formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMMM yyyy HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      print("Error formatting timestamp: $e");
      return 'Invalid Date';
    }
  }

  String _formatDateOnly(Timestamp? timestamp) {
    return _formatTimestamp(timestamp, format: 'dd MMMM yyyy');
  }

  // --- PDF Report Generation (Now includes confirmed fields) ---
  Future<void> _generatePlayerReport() async {
    final pdf = pw.Document();

    // Extract data safely
    final String name = playerData['name'] ?? 'N/A';
    final String position = playerData['position'] ?? 'N/A';
    final String teamName = playerData['team'] ?? 'No Team Assigned';
    final String? pictureUrl = playerData['picture'] as String?;
    final Timestamp? birthDate = playerData['birth_date'] as Timestamp?;

    // Extract Attendance Map data safely
    final Map<String, dynamic>? attendanceData =
        playerData['Attendance'] as Map<String, dynamic>?;
    final bool? presence = attendanceData?['Presence'] as bool?;
    final Timestamp? startTraining =
        attendanceData?['Start_training'] as Timestamp?;
    final Timestamp? finishTraining =
        attendanceData?['Finish_training'] as Timestamp?;
    final String? trainingType = attendanceData?['Training_type'] as String?;

//For the training records
    final trainingSummary =
        await calculateMinutesByTrainingType(widget.playerDoc.id);

    // Fetch Network Image for PDF
    pw.Widget playerImageWidget = pw.Container(
        width: 80,
        height: 80,
        color: PdfColors.grey200,
        child: pw.Center(child: pw.Text('No Image')));
    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      /* ... image fetching logic ... */
      try {
        final netImage = await networkImage(pictureUrl);
        playerImageWidget = pw.ClipOval(
            child: pw.Image(netImage,
                width: 80, height: 80, fit: pw.BoxFit.cover));
      } catch (e) {
        print("Error loading player network image for PDF: $e");
        playerImageWidget = pw.Container(
            width: 80,
            height: 80,
            color: PdfColors.red100,
            child: pw.Center(
                child: pw.Text('Load\nError', textAlign: pw.TextAlign.center)));
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                  level: 0,
                  text: 'Player Report',
                  textStyle: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              // --- Basic Info Section ---
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    playerImageWidget,
                    pw.SizedBox(width: 30),
                    pw.Expanded(
                        child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                          pw.Text('Name: $name',
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 8),
                          pw.Text('Position: $position',
                              style: const pw.TextStyle(fontSize: 16)),
                          pw.SizedBox(height: 8),
                          pw.Text('Team: $teamName',
                              style: const pw.TextStyle(fontSize: 16)),
                          pw.SizedBox(height: 8),
                          // Add Birth Date
                          pw.Text('Birth Date: ${_formatDateOnly(birthDate)}',
                              style: const pw.TextStyle(fontSize: 16)),
                        ]))
                  ]),
              pw.SizedBox(height: 30),

              // --- Last Recorded Attendance Section (If Available) ---
              if (attendanceData != null) ...[
                pw.Header(level: 1, text: 'Last Recorded Session Status'),
                pw.Bullet(
                    text: 'Status: ${presence == true ? "Present" : "Absent"}'),
                pw.Bullet(text: 'Training Type: ${trainingType ?? 'N/A'}'),
                pw.Bullet(
                    text: 'Session Start: ${_formatTimestamp(startTraining)}'),
                pw.Bullet(
                    text:
                        'Session Finish: ${_formatTimestamp(finishTraining)}'),
                // Add notes if available in this map - currently not in screenshot
                // pw.Bullet(text: 'Notes: ${attendanceData['Notes'] ?? ''}'),
                pw.SizedBox(height: 20),
              ],

              // --- Other Sections ---
              pw.Header(level: 1, text: 'Training Summary'),
              if (trainingSummary.isNotEmpty)
                ...trainingSummary.entries
                    .map((entry) =>
                        pw.Bullet(text: '${entry.key}: ${entry.value} minutes'))
                    .toList()
              else
                pw.Text('No training sessions recorded.',
                    style: const pw.TextStyle(fontSize: 14)),
            ],
          );
        },
      ),
    );

    // Use Printing package
    try {
      /* ... Printing.layoutPdf logic ... */
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Player_Report_${name.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      /* ... Error Handling ... */
      print("Error generating/sharing player PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error generating PDF report.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data safely using the state variable
    final name = playerData['name'] ?? 'Player Details';
    final position = playerData['position'] ?? 'N/A';
    final teamName = playerData['team'] ?? 'No Team Assigned';
    final pictureUrl = playerData['picture'] as String?;
    final Timestamp? birthDate =
        playerData['birth_date'] as Timestamp?; // Get birth date

    // Extract Attendance Map safely
    final Map<String, dynamic>? attendanceData =
        playerData['Attendance'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFF27121), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
        ),
        actions: [
          /* ... PDF Button ... */
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: _generatePlayerReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Player Avatar & Name (Same as before) ---
            Center(
              child: CircleAvatar(
                radius: 60,
                /* ... Avatar properties ... */
                backgroundColor: Colors.grey.shade300,
                backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty)
                    ? NetworkImage(pictureUrl)
                    : const AssetImage("assets/images/default_profile.jpeg")
                        as ImageProvider,
                onBackgroundImageError: (e, s) {
                  print("Error loading image: $e");
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style:
                  GoogleFonts.ubuntu(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Details Card ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.sports_soccer, "Position:", position),
                    const Divider(height: 20),
                    _buildDetailRow(Icons.group_work, "Team:", teamName),
                    const Divider(height: 20),
                    // Display Birth Date
                    _buildDetailRow(Icons.cake_outlined, "Birth Date:",
                        _formatDateOnly(birthDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Last Recorded Attendance Card (Conditionally displayed) ---
            if (attendanceData != null) _buildAttendanceCard(attendanceData),

            const SizedBox(height: 30),

            // --- Report Button (Same as before) ---
            Center(
              child: ElevatedButton.icon(
                /* ... Button properties ... */
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate Player Report'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27121),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                onPressed: _generatePlayerReport,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  // Build detail row (same as before)
  Widget _buildDetailRow(IconData icon, String label, String value) {
    // ... same implementation as before ...
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFF27121), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ]),
          Flexible(
              child: Text(
            value,
            style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  // Build Attendance Card
  Widget _buildAttendanceCard(Map<String, dynamic> attendanceData) {
    final bool? presence = attendanceData['Presence'] as bool?;
    final Timestamp? startTraining =
        attendanceData['Start_training'] as Timestamp?;
    final Timestamp? finishTraining =
        attendanceData['Finish_training'] as Timestamp?;
    final String? trainingType = attendanceData['Training_type'] as String?;
    // final String? notes = attendanceData['Notes'] as String?; // Add if Notes field exists

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last Recorded Session Status",
              style:
                  GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
                presence == true ? Icons.check_circle : Icons.cancel_outlined,
                "Status:",
                presence == true ? "Present" : "Absent"),
            const Divider(height: 20),
            _buildDetailRow(
                Icons.fitness_center, "Training Type:", trainingType ?? 'N/A'),
            const Divider(height: 20),
            _buildDetailRow(Icons.timer_outlined, "Session Start:",
                _formatTimestamp(startTraining)),
            const Divider(height: 20),
            _buildDetailRow(Icons.timer_off_outlined, "Session Finish:",
                _formatTimestamp(finishTraining)),
            // Add notes if available:
            // const Divider(height: 20),
            // _buildDetailRow(Icons.notes, "Coach Notes:", notes ?? ''),
          ],
        ),
      ),
    );
  }

//A function that count minutes trained by player
  Future<Map<String, int>> calculateMinutesByTrainingType(
      String playerId) async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('training_sessions').get();

    Map<String, int> trainingTypeMinutes = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final dynamic playersField = data['players'];

      // ✅ Skip if 'players' field is null or not a list
      if (playersField == null || playersField is! List) continue;

      final players = playersField as List;

      final trainingType = data['training_type'] ?? 'Unknown';

      for (var player in players) {
        if (player is Map &&
            player['player_id'] == playerId &&
            player['present'] == true) {
          final minutes = int.tryParse(player['minutes'].toString()) ?? 0;
          trainingTypeMinutes[trainingType] =
              (trainingTypeMinutes[trainingType] ?? 0) + minutes;
        }
      }
    }

    return trainingTypeMinutes;
  }
}
