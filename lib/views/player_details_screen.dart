import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import PDF and Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// No longer need path_provider here unless saving locally first

class PlayerDetailsScreen extends StatefulWidget {
  final DocumentSnapshot playerDoc; // Receive the player document

  const PlayerDetailsScreen({super.key, required this.playerDoc});

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> {
  late Map<String, dynamic> playerData; // To store player data

  @override
  void initState() {
    super.initState();
    // Extract data when the widget is initialized
    playerData = widget.playerDoc.data() as Map<String, dynamic>;
  }

  // --- PDF Report Generation (Moved from AdminScreen) ---
  Future<void> _generatePlayerReport() async {
    final pdf = pw.Document();

    // Use the locally stored playerData
    final String name = playerData['name'] ?? 'N/A';
    final String position = playerData['position'] ?? 'N/A';
    final String teamName = playerData['team'] ?? 'No Team Assigned';
    final String? pictureUrl = playerData['picture'] as String?;

    // Fetch Network Image for PDF
    pw.Widget playerImageWidget = pw.Container(
        width: 80, height: 80, color: PdfColors.grey200, child: pw.Center(child: pw.Text('No Image'))
    );
    if (pictureUrl != null && pictureUrl.isNotEmpty) {
      try {
        final netImage = await networkImage(pictureUrl);
        playerImageWidget = pw.ClipOval(child: pw.Image(netImage, width: 80, height: 80, fit: pw.BoxFit.cover));
      } catch (e) {
        print("Error loading player network image for PDF: $e");
        playerImageWidget = pw.Container(width: 80, height: 80, color: PdfColors.red100, child: pw.Center(child: pw.Text('Load\nError', textAlign: pw.TextAlign.center)));
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Player Report', textStyle: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    playerImageWidget,
                    pw.SizedBox(width: 30),
                    pw.Expanded( // Allow text to wrap if needed
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text('Name: $name', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 12),
                            pw.Text('Position: $position', style: const pw.TextStyle(fontSize: 16)),
                            pw.SizedBox(height: 8),
                            pw.Text('Assigned Team: $teamName', style: const pw.TextStyle(fontSize: 16)),
                          ]
                      ),
                    )
                  ]
              ),
              pw.SizedBox(height: 40),
              pw.Header(level: 1, text: 'Additional Information (Placeholder)'),
              pw.Paragraph(text: 'Contact: [Fetch if available]'),
              pw.Paragraph(text: 'Emergency Contact: [Fetch if available]'),
              // Add more sections (e.g., fetch attendance records for this player)
            ],
          );
        },
      ),
    );

    // Use Printing package
    try {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Player_Report_${name.replaceAll(' ', '_')}.pdf'
      );
    } catch (e) {
      print("Error generating/sharing player PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error generating PDF report.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data safely within the build method too, in case initState didn't run yet (though unlikely)
    final name = playerData['name'] ?? 'Player Details';
    final position = playerData['position'] ?? 'N/A';
    final teamName = playerData['team'] ?? 'No Team Assigned';
    final pictureUrl = playerData['picture'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        flexibleSpace: Container( // Optional Gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient( colors: [Color(0xFFF27121), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
        actions: [
          // Add PDF generation button to AppBar
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: _generatePlayerReport,
          ),
        ],
      ),
      body: SingleChildScrollView( // Allow scrolling if content overflows
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty)
                    ? NetworkImage(pictureUrl)
                    : const AssetImage("assets/images/default_profile.jpeg") as ImageProvider,
                onBackgroundImageError: (exception, stackTrace) {
                  print("Error loading image on details screen: $exception");
                  // Optionally show an error icon or placeholder in the CircleAvatar itself
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                name,
                style: GoogleFonts.ubuntu(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Divider(),
            const SizedBox(height: 10),

            // Use ListTile for consistent styling of details
            _buildDetailItem(Icons.sports_soccer, "Position", position),
            _buildDetailItem(Icons.group_work, "Team", teamName),

            // Add more details if available in your 'players' collection
            // _buildDetailItem(Icons.calendar_today, "Joined Date", playerData['joinDate'] ?? 'N/A'),
            //_buildDetailItem(Icons.phone, "Contact", playerData['phone'] ?? 'N/A'),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Generate Player Report'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27121), // Theme color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                onPressed: _generatePlayerReport,
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper widget to build detail list items
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Text(
            "$label:",
            style: GoogleFonts.ubuntu(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded( // Allow value text to wrap
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