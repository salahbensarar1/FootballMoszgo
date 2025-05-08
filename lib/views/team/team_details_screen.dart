import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/player/player_details_screen.dart';

import 'package:google_fonts/google_fonts.dart';

// Import PDF and Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TeamDetailsScreen extends StatefulWidget {
  final DocumentSnapshot teamDoc; // Receive the team document

  const TeamDetailsScreen({super.key, required this.teamDoc});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for fetched data
  late Map<String, dynamic> teamData;
  String coachName = 'Loading...';
  List<DocumentSnapshot> teamPlayers = [];
  bool isLoadingCoach = true;
  bool isLoadingPlayers = true;
  String? teamPictureUrl; // Store picture URL

  @override
  void initState() {
    super.initState();
    teamData = widget.teamDoc.data() as Map<String, dynamic>;
    teamPictureUrl = teamData['picture'] as String?; // Get picture url
    _fetchCoachName();
    _fetchPlayers();
  }

  // Fetch coach's name using the ID stored in the team document
  Future<void> _fetchCoachName() async {
    final String? coachId = teamData['coach'] as String?; // Coach's document ID
    if (coachId != null && coachId.isNotEmpty) {
      try {
        final coachDoc =
            await _firestore.collection('users').doc(coachId).get();
        if (mounted && coachDoc.exists) {
          setState(() {
            coachName =
                (coachDoc.data() as Map<String, dynamic>)['name'] ?? 'N/A';
          });
        } else if (mounted) {
          setState(() {
            coachName = 'Coach Not Found';
          });
        }
      } catch (e) {
        print("Error fetching coach name: $e");
        if (mounted) {
          setState(() {
            coachName = 'Error';
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
          coachName = 'Not Assigned';
          isLoadingCoach = false;
        });
      }
    }
  }

  // Fetch players assigned to this team (using team NAME)
  Future<void> _fetchPlayers() async {
    final String teamName = teamData['team_name'] ?? '';
    if (teamName.isEmpty) {
      if (mounted) setState(() => isLoadingPlayers = false);
      return;
    }

    try {
      final playerSnapshot = await _firestore
          .collection('players')
          .where('team', isEqualTo: teamName) // Query by team NAME
          .orderBy('name')
          .get();

      if (mounted) {
        setState(() {
          teamPlayers = playerSnapshot.docs;
          isLoadingPlayers = false;
        });
      }
    } catch (e) {
      print("Error fetching players for team: $e");
      if (mounted) {
        setState(() => isLoadingPlayers = false);
        // Optionally show an error message on the UI
      }
    }
  }

  // --- PDF Report Generation (Moved from AdminScreen) ---
  Future<void> _generateTeamReport() async {
    final pdf = pw.Document();

    // Use local state variables (teamData, coachName, teamPlayers)
    final String teamName = teamData['team_name'] ?? 'N/A';
    final String teamDescription =
        teamData['team_desciption'] ?? 'No Description Provided';
    final int storedPlayerCount = teamData['number_of_players'] ?? 0;

    // --- Fetch Team Image for PDF (Optional) ---
    pw.Widget teamImageWidget = pw.Container(width: 1, height: 1);
    if (teamPictureUrl != null && teamPictureUrl!.isNotEmpty) {
      try {
        final netImage = await networkImage(teamPictureUrl!);
        teamImageWidget = pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(netImage,
                width: 100, height: 70, fit: pw.BoxFit.cover));
      } catch (e) {
        print("Error loading team network image for PDF: $e");
        teamImageWidget = pw.Container(
            width: 100,
            height: 70,
            color: PdfColors.red100,
            child: pw.Center(
                child: pw.Text('Load\nError', textAlign: pw.TextAlign.center)));
      }
    }

    pdf.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => pw.Header(
              level: 0,
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Team Report: $teamName',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    if (teamPictureUrl != null && teamPictureUrl!.isNotEmpty)
                      teamImageWidget,
                  ])),
          build: (pw.Context context) => [
                pw.Paragraph(
                    text: 'Description: $teamDescription',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.Paragraph(
                    text: 'Assigned Coach: $coachName',
                    style: const pw.TextStyle(
                        fontSize: 14)), // Use fetched coach name
                pw.Paragraph(
                    text:
                        'Registered Players: $storedPlayerCount (Found: ${teamPlayers.length})',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey600)),
                pw.Divider(height: 20),
                pw.Header(
                    level: 1,
                    text: 'Team Roster',
                    textStyle: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                // Display Player List (already fetched into teamPlayers)
                if (isLoadingPlayers)
                  pw.Center(
                      child: pw.Text(
                          'Loading player list...')) // Should already be loaded, but safe check
                else if (teamPlayers.isEmpty)
                  pw.Center(
                      child: pw.Text(
                          'No players currently assigned to this team.'))
                else
                  pw.TableHelper.fromTextArray(
                    context: context,
                    cellPadding: const pw.EdgeInsets.all(5),
                    headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    border: pw.TableBorder.all(color: PdfColors.grey500),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft
                    },
                    headers: ['Player Name', 'Position'],
                    data: teamPlayers.map((player) {
                      final pData = player.data() as Map<String, dynamic>;
                      return [
                        pData['name'] ?? 'N/A',
                        pData['position'] ?? 'N/A',
                      ];
                    }).toList(),
                  ),
              ],
          footer: (pw.Context context) => pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.Theme.of(context)
                      .defaultTextStyle
                      .copyWith(color: PdfColors.grey)))),
    );

    // Use Printing package
    try {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Team_Report_${teamName.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      print("Error generating/sharing team PDF: $e");
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
    final teamName = teamData['team_name'] ?? 'Team Details';
    final teamDescription = teamData['team_desciption'] ?? 'No Description';
    final playerCount = teamData['number_of_players'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(teamName),
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
          // Add PDF generation button to AppBar
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: _generateTeamReport, // Call the local function
          ),
        ],
      ),
      body: ListView(
        // Use ListView to combine static details and dynamic player list
        padding: const EdgeInsets.all(16.0),
        children: [
          // Display Team Picture if available
          if (teamPictureUrl != null && teamPictureUrl!.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  teamPictureUrl!,
                  height: 150, // Adjust height as needed
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stack) => const Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey),
                ),
              ),
            ),
          if (teamPictureUrl != null && teamPictureUrl!.isNotEmpty)
            const SizedBox(height: 20),

          // Team Name (larger)
          Text(
            teamName,
            style:
                GoogleFonts.ubuntu(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Team Description
          if (teamDescription.isNotEmpty)
            Text(
              teamDescription,
              style:
                  GoogleFonts.ubuntu(fontSize: 15, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          if (teamDescription.isNotEmpty) const SizedBox(height: 10),

          Divider(),
          const SizedBox(height: 10),

          // Coach and Player Count Info
          _buildDetailItem(Icons.person_outline, "Coach",
              isLoadingCoach ? "Loading..." : coachName),
          _buildDetailItem(
              Icons.groups, "Registered Players", playerCount.toString()),

          const SizedBox(height: 20),
          Text(
            "Player Roster",
            style:
                GoogleFonts.ubuntu(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),

          // Display Player List Section
          _buildPlayerListSection(),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Generate Team Report'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27121),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: _generateTeamReport,
            ),
          )
        ],
      ),
    );
  }

  // Helper to build the player list section with loading/empty states
  Widget _buildPlayerListSection() {
    if (isLoadingPlayers) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: Color(0xFFF27121)),
      ));
    }
    if (teamPlayers.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No players assigned to this team yet."),
      ));
    }

    return ListView.builder(
      shrinkWrap: true, // Important inside another scroll view (ListView)
      physics:
          const NeverScrollableScrollPhysics(), // Disable scrolling for this inner list
      itemCount: teamPlayers.length,
      itemBuilder: (context, index) {
        final playerDoc = teamPlayers[index];
        final playerData = playerDoc.data() as Map<String, dynamic>;
        final playerName = playerData['name'] ?? 'N/A';
        final playerPosition = playerData['position'] ?? 'N/A';
        final playerPicUrl = playerData['picture'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: (playerPicUrl != null && playerPicUrl.isNotEmpty)
                  ? NetworkImage(playerPicUrl)
                  : const AssetImage("assets/images/default_profile.jpeg")
                      as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            title: Text(playerName),
            subtitle: Text(playerPosition),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to player details when a player in the list is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlayerDetailsScreen(playerDoc: playerDoc),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper widget to build detail list items (same as in PlayerDetailsScreen)
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text(
            "$label:",
            style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            // Allow value text to wrap
            child: Text(
              value,
              style: GoogleFonts.ubuntu(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
