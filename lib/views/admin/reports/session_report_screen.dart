import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:footballtraining/views/admin/reports/player_report_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SessionReportScreen extends StatefulWidget {
  final DocumentSnapshot sessionDoc;

  const SessionReportScreen({super.key, required this.sessionDoc});

  @override
  State<SessionReportScreen> createState() => _SessionReportScreenState();
}

class _SessionReportScreenState extends State<SessionReportScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsAnimation;

  // State variables
  late Map<String, dynamic> sessionData;
  String coachName = '';
  bool isLoadingCoach = true;
  bool isGeneratingPdf = false;
  List<Map<String, dynamic>> playerAttendanceList = [];
  Map<String, dynamic> sessionStats = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSessionData();
    _extractPlayerList();
    _fetchCoachName();
    _calculateSessionStats();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _statsAnimationController, curve: Curves.easeOutBack),
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

  void _loadSessionData() {
    if (widget.sessionDoc.exists && widget.sessionDoc.data() != null) {
      sessionData = widget.sessionDoc.data() as Map<String, dynamic>;
    } else {
      sessionData = {};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar('Error: Session data not found.', isError: true);
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _extractPlayerList() {
    final List<dynamic>? playersRaw = sessionData['players'] as List<dynamic>?;
    if (playersRaw != null) {
      try {
        playerAttendanceList = playersRaw
            .map((player) => player is Map<String, dynamic> ? player : null)
            .whereType<Map<String, dynamic>>()
            .toList();

        playerAttendanceList
            .sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
      } catch (e) {
        print("Error parsing players list: $e");
        playerAttendanceList = [];
      }
    } else {
      playerAttendanceList = [];
    }
  }

  Future<void> _fetchCoachName() async {
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
          setState(() {
            coachName = coachDoc.exists
                ? (coachDoc.data() as Map<String, dynamic>)['name'] ?? 'N/A'
                : 'Coach Not Found';
            isLoadingCoach = false;
          });
        }
      } catch (e) {
        print("Error fetching coach name: $e");
        if (mounted) {
          setState(() {
            coachName = 'Error Loading Coach';
            isLoadingCoach = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          coachName = sessionData['coach_name'] ?? 'N/A';
          isLoadingCoach = false;
        });
      }
    }
  }

  Future<void> _calculateSessionStats() async {
    try {
      final presentPlayers =
          playerAttendanceList.where((p) => p['present'] == true).length;
      final absentPlayers = playerAttendanceList.length - presentPlayers;
      final attendanceRate = playerAttendanceList.isNotEmpty
          ? (presentPlayers / playerAttendanceList.length * 100)
          : 0.0;

      int totalMinutes = 0;
      for (var player in playerAttendanceList) {
        if (player['present'] == true) {
          totalMinutes +=
              int.tryParse(player['minutes']?.toString() ?? '0') ?? 0;
        }
      }

      if (mounted) {
        setState(() {
          sessionStats = {
            'totalPlayers': playerAttendanceList.length,
            'presentPlayers': presentPlayers,
            'absentPlayers': absentPlayers,
            'attendanceRate': attendanceRate,
            'totalMinutes': totalMinutes,
            'avgMinutesPerPlayer':
                presentPlayers > 0 ? (totalMinutes / presentPlayers) : 0.0,
          };
        });
      }
    } catch (e) {
      print("Error calculating session stats: $e");
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _fabAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? timestamp,
      {String format = 'dd MMM yyyy, HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      return DateFormat(format).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatDateOnly(Timestamp? timestamp) {
    return _formatTimestamp(timestamp, format: 'yyyy. MMMM dd.');
  }

  String _formatTimeOnly(Timestamp? timestamp) {
    return _formatTimestamp(timestamp, format: 'HH:mm');
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

  Future<void> _generateSessionReport() async {
    setState(() => isGeneratingPdf = true);

    try {
      final pdf = pw.Document();
      final teamName = sessionData['team'] ?? 'N/A';
      final trainingType = sessionData['training_type'] ?? 'N/A';
      final startTime = sessionData['start_time'] as Timestamp?;
      final endTime = sessionData['end_time'] as Timestamp?;
      final pitchLocation = sessionData['pitch_location'] ?? 'N/A';
      final sessionNote = sessionData['note'] ?? '';

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
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Training Session Report',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    teamName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _formatDateOnly(startTime),
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Session Details
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
                    'Session Details',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      _buildPdfTableRow('Date:', _formatDateOnly(startTime)),
                      _buildPdfTableRow('Time:',
                          "${_formatTimeOnly(startTime)} - ${_formatTimeOnly(endTime)}"),
                      _buildPdfTableRow('Training Type:', trainingType),
                      _buildPdfTableRow('Coach:', coachName),
                      _buildPdfTableRow('Location:', pitchLocation),
                      if (sessionNote.isNotEmpty)
                        _buildPdfTableRow('Session Notes:', sessionNote),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Statistics Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Session Statistics',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildPdfStatBox('Total Players',
                          '${sessionStats['totalPlayers'] ?? 0}'),
                      _buildPdfStatBox(
                          'Present', '${sessionStats['presentPlayers'] ?? 0}'),
                      _buildPdfStatBox(
                          'Absent', '${sessionStats['absentPlayers'] ?? 0}'),
                      _buildPdfStatBox('Attendance',
                          '${(sessionStats['attendanceRate'] ?? 0.0).toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Player Attendance
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
                    'Player Attendance (${playerAttendanceList.length})',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  if (playerAttendanceList.isEmpty)
                    pw.Text(
                      'No players recorded for this session.',
                      style:
                          pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.orange300),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(1),
                        2: const pw.FlexColumnWidth(1),
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
                              child: pw.Text('Status',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('Minutes',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.center),
                            ),
                          ],
                        ),
                        // Player rows
                        ...playerAttendanceList.map((playerMap) {
                          final String playerName =
                              playerMap['name'] ?? 'Unknown';
                          final bool isPresent = playerMap['present'] ?? false;
                          final int minutes = int.tryParse(
                                  playerMap['minutes']?.toString() ?? '0') ??
                              0;

                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(playerName),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  isPresent ? 'Present' : 'Absent',
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    color: isPresent
                                        ? PdfColors.green700
                                        : PdfColors.red700,
                                    fontWeight: pw.FontWeight.normal,
                                  ),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  isPresent ? minutes.toString() : '-',
                                  textAlign: pw.TextAlign.center,
                                ),
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
            'Session_Report_${sessionData['team']}_${_formatTimestamp(sessionData['start_time'] as Timestamp?, format: 'yyyyMMdd')}.pdf',
      );

      _showSnackBar('PDF successfully generated!');
    } catch (e) {
      _showSnackBar('Error generating PDF report', isError: true);
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
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.TableRow _buildPdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
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

    final teamName = sessionData['team'] ?? 'N/A';
    final trainingType = sessionData['training_type'] ?? 'N/A';
    final startTime = sessionData['start_time'] as Timestamp?;
    final endTime = sessionData['end_time'] as Timestamp?;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(teamName),
      body: sessionData.isEmpty
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
                            horizontal: isTablet ? 32 : 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildHeroSessionCard(teamName, trainingType,
                                startTime, endTime, isTablet),
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
          sessionData.isNotEmpty ? _buildFloatingActionButton() : null,
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading session details...',
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
        'Session Report',
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
            onPressed: isGeneratingPdf ? null : _generateSessionReport,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSessionCard(String teamName, String trainingType,
      Timestamp? startTime, Timestamp? endTime, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
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
            child: Icon(Icons.event_available,
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
              trainingType,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                _formatDateOnly(startTime),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time,
                  color: Colors.white.withOpacity(0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                "${_formatTimeOnly(startTime)} - ${_formatTimeOnly(endTime)}",
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
            child: Column(children: [
              _buildSessionDetailsCard(),
              const SizedBox(height: 24),
              _buildSessionStatsCard()
            ])),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildPlayersCard()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSessionDetailsCard(),
        const SizedBox(height: 24),
        _buildSessionStatsCard(),
        const SizedBox(height: 24),
        _buildPlayersCard(),
      ],
    );
  }

  Widget _buildSessionDetailsCard() {
    final pitchLocation = sessionData['pitch_location'] ?? 'N/A';
    final sessionNote = sessionData['note'] ?? '';

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
                'Session Details',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.person_outline, 'Coach',
              isLoadingCoach ? 'Loading...' : coachName, Colors.green),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'Location', pitchLocation,
              Colors.orange),
          if (sessionNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow(Icons.notes, 'Notes', sessionNote, Colors.purple),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionStatsCard() {
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
                'Session Statistics',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _statsAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _statsAnimation.value,
                child: Opacity(
                  opacity: _statsAnimation.value,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Total',
                                  '${sessionStats['totalPlayers'] ?? 0}',
                                  Icons.groups,
                                  Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'Present',
                                  '${sessionStats['presentPlayers'] ?? 0}',
                                  Icons.check_circle,
                                  Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildStatCard(
                                  'Absent',
                                  '${sessionStats['absentPlayers'] ?? 0}',
                                  Icons.cancel,
                                  Colors.red)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildStatCard(
                                  'Rate',
                                  '${(sessionStats['attendanceRate'] ?? 0.0).toStringAsFixed(1)}%',
                                  Icons.percent,
                                  Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.indigo.shade50,
                            Colors.purple.shade50
                          ]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${sessionStats['totalMinutes'] ?? 0}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                                Text(
                                  'Total Minutes',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300),
                            Column(
                              children: [
                                Text(
                                  '${(sessionStats['avgMinutesPerPlayer'] ?? 0.0).toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                                Text(
                                  'Avg per Player',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
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
                'Player Attendance',
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
                  '${playerAttendanceList.length}',
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
          if (playerAttendanceList.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No players recorded for this session.',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: playerAttendanceList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final player = playerAttendanceList[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset((1 - value) * 50, 0),
                      child: Opacity(
                        opacity: value,
                        child: _buildPlayerCard(player),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> playerMap) {
    final String playerName = playerMap['name'] ?? 'Unknown Player';
    final String playerId = playerMap['player_id'] ?? '';
    final bool isPresent = playerMap['present'] ?? false;
    final int minutes =
        int.tryParse(playerMap['minutes']?.toString() ?? '0') ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isPresent ? Colors.green.shade50 : Colors.red.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPresent ? Colors.green.shade200 : Colors.red.shade200,
        ),
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
                color: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                size: 24,
              ),
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
                          color: isPresent
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isPresent
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      if (isPresent && minutes > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$minutes min',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
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
          onPressed: isGeneratingPdf ? null : _generateSessionReport,
          backgroundColor:
              isGeneratingPdf ? Colors.grey.shade400 : const Color(0xFF667eea),
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
