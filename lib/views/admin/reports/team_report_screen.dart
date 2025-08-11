import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:footballtraining/views/admin/reports/player_report_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TeamReportScreen extends StatefulWidget {
  final DocumentSnapshot teamDoc;

  const TeamReportScreen({super.key, required this.teamDoc});

  @override
  State<TeamReportScreen> createState() => _TeamReportScreenState();
}

class _TeamReportScreenState extends State<TeamReportScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _playersAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _playersAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsAnimation;

  // Data state
  late Map<String, dynamic> teamData;
  List<Map<String, dynamic>> teamPlayers = [];
  Map<String, dynamic> teamStats = {};

  // Loading states
  bool isLoadingPlayers = true;
  bool isLoadingStats = true;
  bool isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadTeamData();
    _loadTeamPlayers();
    // Stats will be calculated after players are loaded
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _playersAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _playersAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _playersAnimationController,
          curve: Curves.easeOutCubic), // Safe curve
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeOutCubic), // Safe curve
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _statsAnimationController,
          curve: Curves.easeOutCubic), // Safe curve
    );

    // Start animations
    _mainAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fabAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _statsAnimationController.forward();
    });
  }

  void _loadTeamData() {
    if (widget.teamDoc.exists && widget.teamDoc.data() != null) {
      teamData = widget.teamDoc.data() as Map<String, dynamic>;
    } else {
      teamData = {};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar('Error loading team data', isError: true);
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _loadTeamPlayers() async {
    setState(() => isLoadingPlayers = true);
    try {
      final teamName = teamData['team_name'] ?? '';
      if (teamName.isNotEmpty) {
        final playersQuery = await _firestore
            .collection('players')
            .where('team', isEqualTo: teamName)
            .get();

        if (mounted) {
          setState(() {
            teamPlayers = playersQuery.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();
            teamPlayers
                .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
            isLoadingPlayers = false;
          });
          _playersAnimationController.forward();
          // Calculate stats AFTER players are loaded
          _calculateTeamStats();
        }
      } else {
        if (mounted) {
          setState(() => isLoadingPlayers = false);
          // Calculate stats even if no team name
          _calculateTeamStats();
        }
      }
    } catch (e) {
      print("Error loading team players: $e");
      if (mounted) {
        setState(() => isLoadingPlayers = false);
        // Calculate stats even on error
        _calculateTeamStats();
      }
    }
  }

  Future<void> _calculateTeamStats() async {
    setState(() => isLoadingStats = true);
    try {
      // Professional position mapping based on database structure
      final positionMapping = _mapPlayerPositions(teamPlayers);

      final stats = {
        'totalPlayers': teamPlayers.length,
        'Goalkeeper': positionMapping['Goalkeeper'] ?? 0,
        'Defender': positionMapping['Defender'] ?? 0,
        'Midfielder': positionMapping['Midfielder'] ?? 0,
        'Forward': positionMapping['Forward'] ?? 0,
        'payment': teamData['payment'] ?? 0,
        'description': teamData['team_description'] ?? 'No description',
        'positionDistribution': positionMapping,
        'averageAge': _calculateAverageAge(),
      };

      if (mounted) {
        setState(() {
          teamStats = stats;
          isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Error calculating team stats: $e");
      if (mounted) {
        setState(() => isLoadingStats = false);
      }
    }
  }

  /// Professional position mapping based on exact database structure
  Map<String, int> _mapPlayerPositions(List<Map<String, dynamic>> players) {
    final Map<String, int> positionCounts = {
      'Goalkeeper': 0,
      'Defender': 0,
      'Midfielder': 0,
      'Forward': 0,
    };

    debugPrint('=== POSITION MAPPING DEBUG ===');
    debugPrint('Total players to map: ${players.length}');

    for (final player in players) {
      final positionRaw = player['position'];
      final position = (positionRaw ?? '').toString().trim();
      final playerName = player['name'] ?? 'Unknown';

      debugPrint(
          'Player: $playerName, Position: "$positionRaw" -> "$position"');

      // Map exact database positions (case-insensitive)
      if (position == 'Goalkeeper' ||
          position.toLowerCase() == 'goalkeeper' ||
          position.toLowerCase() == 'keeper' ||
          position.toLowerCase() == 'gk') {
        positionCounts['Goalkeeper'] = positionCounts['Goalkeeper']! + 1;
        debugPrint('  -> Mapped to Goalkeeper');
      } else if (position == 'Defender' ||
          position.toLowerCase() == 'defender' ||
          position.toLowerCase() == 'defence' ||
          position.toLowerCase() == 'def') {
        positionCounts['Defender'] = positionCounts['Defender']! + 1;
        debugPrint('  -> Mapped to Defender');
      } else if (position == 'Midfielder' ||
          position.toLowerCase() == 'midfielder' ||
          position.toLowerCase() == 'midfield' ||
          position.toLowerCase() == 'mid') {
        positionCounts['Midfielder'] = positionCounts['Midfielder']! + 1;
        debugPrint('  -> Mapped to Midfielder');
      } else if (position == 'Forward' ||
          position.toLowerCase() == 'forward' ||
          position.toLowerCase() == 'striker' ||
          position.toLowerCase() == 'att' ||
          position.toLowerCase() == 'attacker') {
        positionCounts['Forward'] = positionCounts['Forward']! + 1;
        debugPrint('  -> Mapped to Forward');
      } else {
        debugPrint('  -> UNMAPPED POSITION: "$position"');
      }
    }

    debugPrint(
        'Final counts: Goalkeeper:${positionCounts['Goalkeeper']}, Defender:${positionCounts['Defender']}, Midfielder:${positionCounts['Midfielder']}, Forward:${positionCounts['Forward']}');
    debugPrint('=== END DEBUG ===');

    return positionCounts;
  }

  /// Calculate average age of team players
  double _calculateAverageAge() {
    if (teamPlayers.isEmpty) return 0.0;

    final now = DateTime.now();
    double totalAge = 0.0;
    int validBirthDates = 0;

    for (final player in teamPlayers) {
      final birthDate = player['birth_date'];
      if (birthDate != null) {
        try {
          DateTime birth;
          if (birthDate is Timestamp) {
            birth = birthDate.toDate();
          } else if (birthDate is String) {
            birth = DateTime.parse(birthDate);
          } else {
            continue;
          }

          final age = now.difference(birth).inDays / 365.25;
          totalAge += age;
          validBirthDates++;
        } catch (e) {
          debugPrint('Error parsing birth date for player: $e');
        }
      }
    }

    return validBirthDates > 0 ? totalAge / validBirthDates : 0.0;
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _playersAnimationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _generateTeamReport() async {
    setState(() => isGeneratingPdf = true);
    HapticFeedback.lightImpact();

    try {
      final pdf = pw.Document();
      final teamName = teamData['team_name'] ?? 'N/A';
      final teamDescription = teamData['team_description'] ?? 'No description';
      final payment = teamData['payment'] ?? 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // Modern Header
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Team Report',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    teamName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    DateFormat('yyyy. MMMM dd.').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Team Details
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Team Details',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  _buildPdfInfoRow('Team Name:', teamName),
                  pw.SizedBox(height: 8),
                  _buildPdfInfoRow('Description:', teamDescription),
                  pw.SizedBox(height: 8),
                  _buildPdfInfoRow('Payment:', '$payment'),
                  pw.SizedBox(height: 8),
                  _buildPdfInfoRow(
                      'Total Players:', '${teamStats['totalPlayers'] ?? 0}'),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Team Statistics
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Position Distribution',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildPdfStatBox(
                          'Goalkeeper', '${teamStats['Goalkeeper'] ?? 0}'),
                      _buildPdfStatBox(
                          'Defender', '${teamStats['Defender'] ?? 0}'),
                      _buildPdfStatBox(
                          'Midfielder', '${teamStats['Midfielder'] ?? 0}'),
                      _buildPdfStatBox(
                          'Forward', '${teamStats['Forward'] ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Players List
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Team Players (${teamPlayers.length})',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  if (teamPlayers.isEmpty)
                    pw.Text(
                      'No players found for this team.',
                      style:
                          pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.orange300),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(2),
                        2: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        // Header
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.orange100),
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Player Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Position',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Email',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        ),
                        // Player rows
                        ...teamPlayers.map((player) {
                          final String playerName = player['name'] ?? 'Unknown';
                          final String position = player['position'] ?? 'N/A';
                          final String email = player['email'] ?? 'N/A';

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(playerName),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(position,
                                    textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(email,
                                    textAlign: pw.TextAlign.center),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name:
            'Team_Report_${teamData['team_name']?.replaceAll(' ', '_') ?? 'Unknown'}.pdf',
      );

      _showSnackBar('PDF successfully generated!');
      HapticFeedback.selectionClick();
    } catch (e) {
      _showSnackBar('Error generating PDF report', isError: true);
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() => isGeneratingPdf = false);
      }
    }
  }

  pw.Widget _buildPdfStatBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.grey700),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToPlayerDetails(String playerId) async {
    if (playerId.isEmpty) {
      _showSnackBar('Cannot load details: Missing player ID.', isError: true);
      return;
    }

    try {
      HapticFeedback.lightImpact();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Loading player details...',
                    style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        ),
      );

      DocumentSnapshot playerDoc =
          await _firestore.collection('players').doc(playerId).get();

      if (mounted) Navigator.pop(context);

      if (playerDoc.exists && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlayerReportScreen(playerDoc: playerDoc)),
        );
      } else if (mounted) {
        _showSnackBar('Player details not found.', isError: true);
      }
    } catch (e) {
      print("Error fetching player doc $playerId: $e");
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error loading player details.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isMobile = size.width < 480;

    final teamName = teamData['team_name'] ?? 'N/A';
    final teamDescription = teamData['team_description'] ?? 'No description';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(teamName),
      body: teamData.isEmpty
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            20,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildHeroTeamCard(
                                teamName, teamDescription, isTablet, isMobile),
                            const SizedBox(height: 24),
                            if (isTablet)
                              _buildTabletLayout()
                            else
                              _buildMobileLayout(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton:
          teamData.isNotEmpty ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading team details...',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String teamName) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        'Team Report',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: isGeneratingPdf
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                    ),
                  )
                : Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            onPressed: isGeneratingPdf ? null : _generateTeamReport,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTeamCard(
      String teamName, String teamDescription, bool isTablet, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A), Color(0xFF81C784)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.groups,
                color: Colors.white, size: isTablet ? 40 : 32),
          ),
          const SizedBox(height: 20),
          Text(
            teamName,
            style: GoogleFonts.inter(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              teamDescription,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                '${teamStats['totalPlayers'] ?? 0} Players',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                '${teamData['payment'] ?? 0}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildTeamDetailsCard(),
              const SizedBox(height: 24),
              _buildTeamStatsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildPlayersCard()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTeamDetailsCard(),
        const SizedBox(height: 24),
        _buildTeamStatsCard(),
        const SizedBox(height: 24),
        _buildPlayersCard(),
      ],
    );
  }

  Widget _buildTeamDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.info_outline,
                    color: Colors.blue.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Team Details',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.groups, 'Team Name',
              teamData['team_name'] ?? 'N/A', Colors.green),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.description, 'Description',
              teamData['team_description'] ?? 'No description', Colors.orange),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.attach_money, 'Payment',
              '${teamData['payment'] ?? 0}', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.analytics,
                    color: Colors.indigo.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Position Distribution',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isLoadingStats)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Calculating statistics...',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _statsAnimation.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: _statsAnimation.value.clamp(0.0, 1.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'GK',
                                    '${teamStats['Goalkeeper']}',
                                    Icons.sports_soccer,
                                    Colors.blue)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildStatCard(
                                    'DEF',
                                    '${teamStats['Defender']}',
                                    Icons.shield,
                                    Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _buildStatCard(
                                    'MID',
                                    '${teamStats['Midfielder']}',
                                    Icons.swap_horiz,
                                    Colors.orange)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildStatCard(
                                    'FWD',
                                    '${teamStats['Forward']}',
                                    Icons.trending_up,
                                    Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 120;
        return Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: isSmall ? 20 : 24),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: isSmall ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: isSmall ? 10 : 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(Icons.people, color: Colors.green.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Team Players',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${teamPlayers.length}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isLoadingPlayers)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading players...',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else if (teamPlayers.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No players found for this team.',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            AnimatedBuilder(
              animation: _playersAnimation,
              builder: (context, child) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teamPlayers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final player = teamPlayers[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset((1 - value) * 50, 0),
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: _buildPlayerCard(player),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final String playerName = player['name'] ?? 'Unknown Player';
    final String playerId = player['id'] ?? '';
    final String position = player['position'] ?? 'N/A';
    final String email = player['email'] ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToPlayerDetails(playerId),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.person, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          position,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      if (email != 'N/A') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: isGeneratingPdf ? null : _generateTeamReport,
          backgroundColor:
              isGeneratingPdf ? Colors.grey.shade400 : const Color(0xFF4CAF50),
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isGeneratingPdf) ...[
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Generating...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Export PDF',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
