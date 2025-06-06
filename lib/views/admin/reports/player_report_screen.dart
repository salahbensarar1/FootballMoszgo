import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PlayerReportScreen extends StatefulWidget {
  final DocumentSnapshot playerDoc;

  const PlayerReportScreen({super.key, required this.playerDoc});

  @override
  State<PlayerReportScreen> createState() => _PlayerReportScreenState();
}

class _PlayerReportScreenState extends State<PlayerReportScreen>
    with TickerProviderStateMixin {
  late Map<String, dynamic> playerData;
  late AnimationController _mainAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _statsAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _statsAnimation;

  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  Map<String, int> _trainingStats = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPlayerData();
    _loadTrainingStats();
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
      duration: const Duration(milliseconds: 1500),
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
  }

  void _loadPlayerData() {
    if (widget.playerDoc.exists && widget.playerDoc.data() != null) {
      playerData = widget.playerDoc.data() as Map<String, dynamic>;
    } else {
      playerData = {'name': 'Error: Data Missing'};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSnackBar('Error loading player data', isError: true);
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _loadTrainingStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await calculateMinutesByTrainingType(widget.playerDoc.id);
      if (mounted) {
        setState(() {
          _trainingStats = stats;
          _isLoading = false;
        });
        _statsAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      {String format = 'yyyy. MM. dd. HH:mm'}) {
    if (timestamp == null) return 'N/A';
    try {
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat(format, locale).format(timestamp.toDate());
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatDateOnly(Timestamp? timestamp) {
    return _formatTimestamp(timestamp, format: 'yyyy. MMMM dd.');
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

  Future<void> _generatePlayerReport() async {
    setState(() => _isGeneratingPdf = true);
    HapticFeedback.lightImpact();

    try {
      final pdf = pw.Document();
      final name = playerData['name'] ?? 'N/A';
      final position = playerData['position'] ?? 'N/A';
      final teamName = playerData['team'] ?? 'No team assigned';
      final pictureUrl = playerData['picture'] as String?;
      final Timestamp? birthDate = playerData['birth_date'] as Timestamp?;

      final Map<String, dynamic>? attendanceData =
          playerData['Attendance'] as Map<String, dynamic>?;
      final bool? presence = attendanceData?['Presence'] as bool?;
      final Timestamp? startTraining =
          attendanceData?['Start_training'] as Timestamp?;
      final Timestamp? finishTraining =
          attendanceData?['Finish_training'] as Timestamp?;
      final String? trainingType = attendanceData?['Training_type'] as String?;

      // Create professional PDF with modern design
      pw.Widget playerImageWidget = pw.Container(
        width: 100,
        height: 100,
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(50),
          border: pw.Border.all(color: PdfColors.blue300, width: 3),
        ),
        child: pw.Center(
          child: pw.Text(
            'No Image',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

      if (pictureUrl != null && pictureUrl.isNotEmpty) {
        try {
          final netImage = await networkImage(pictureUrl);
          playerImageWidget = pw.Container(
            width: 100,
            height: 100,
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(50),
              border: pw.Border.all(color: PdfColors.blue300, width: 3),
            ),
            child: pw.ClipOval(
              child: pw.Image(netImage, fit: pw.BoxFit.cover),
            ),
          );
        } catch (e) {
          // Keep default widget on error
        }
      }

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
                color: PdfColors.purple50,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.purple200),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Player Report',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    DateFormat('yyyy. MMMM dd.').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Player Profile Section
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  playerImageWidget,
                  pw.SizedBox(width: 32),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          name,
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        _buildPdfInfoRow('Position', position),
                        pw.SizedBox(height: 8),
                        _buildPdfInfoRow('Team', teamName),
                        pw.SizedBox(height: 8),
                        _buildPdfInfoRow(
                            'Birth Date', _formatDateOnly(birthDate)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Last Session Section
            if (attendanceData != null) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: presence == true ? PdfColors.green50 : PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(
                    color: presence == true
                        ? PdfColors.green200
                        : PdfColors.red200,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Last Session',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: presence == true
                            ? PdfColors.green800
                            : PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildPdfInfoRow(
                        'Status', presence == true ? 'Present' : 'Absent'),
                    pw.SizedBox(height: 8),
                    _buildPdfInfoRow('Training Type', trainingType ?? 'N/A'),
                    pw.SizedBox(height: 8),
                    _buildPdfInfoRow(
                        'Session Start', _formatTimestamp(startTraining)),
                    pw.SizedBox(height: 8),
                    _buildPdfInfoRow(
                        'Session End', _formatTimestamp(finishTraining)),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
            ],

            // Training Statistics Section
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
                    'Training Summary',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  if (_trainingStats.isNotEmpty) ...[
                    ..._trainingStats.entries
                        .map(
                          (entry) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(12),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                borderRadius: pw.BorderRadius.circular(8),
                                border:
                                    pw.Border.all(color: PdfColors.orange100),
                              ),
                              child: _buildPdfInfoRow(
                                  entry.key, '${entry.value} minutes'),
                            ),
                          ),
                        )
                        .toList(),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          pw.Column(
                            children: [
                              pw.Text(
                                '${_trainingStats.values.fold(0, (sum, minutes) => sum + minutes)}',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue700,
                                ),
                              ),
                              pw.Text(
                                'Total Minutes',
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.grey600),
                              ),
                            ],
                          ),
                          pw.Container(
                              width: 1, height: 40, color: PdfColors.grey300),
                          pw.Column(
                            children: [
                              pw.Text(
                                '${_trainingStats.length}',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green700,
                                ),
                              ),
                              pw.Text(
                                'Sessions Attended',
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.grey600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else
                    pw.Text(
                      'No training sessions recorded for this player.',
                      style:
                          pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Player_Report_${name.replaceAll(' ', '_')}.pdf',
      );

      _showSnackBar('PDF successfully generated!');
      HapticFeedback.selectionClick();
    } catch (e) {
      _showSnackBar('Error generating PDF report', isError: true);
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
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
            color: PdfColors.grey700,
          ),
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 768;
    final isMobile = size.width < 480;

    final name = playerData['name'] ?? 'Player Details';
    final position = playerData['position'] ?? 'N/A';
    final teamName = playerData['team'] ?? 'No team assigned';
    final pictureUrl = playerData['picture'] as String?;
    final Timestamp? birthDate = playerData['birth_date'] as Timestamp?;
    final Map<String, dynamic>? attendanceData =
        playerData['Attendance'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(name),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).padding.top + kToolbarHeight + 20,
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
                      _buildHeroProfileCard(name, position, teamName,
                          pictureUrl, isTablet, isMobile),
                      const SizedBox(height: 24),
                      if (isTablet)
                        _buildTabletLayout(
                            position, teamName, birthDate, attendanceData)
                      else
                        _buildMobileLayout(
                            position, teamName, birthDate, attendanceData),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(String name) {
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
        'Player Report',
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
            icon: _isGeneratingPdf
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
            onPressed: _isGeneratingPdf ? null : _generatePlayerReport,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroProfileCard(String name, String position, String teamName,
      String? pictureUrl, bool isTablet, bool isMobile) {
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
      child: isMobile
          ? _buildMobileProfileContent(name, position, teamName, pictureUrl)
          : _buildDesktopProfileContent(
              name, position, teamName, pictureUrl, isTablet),
    );
  }

  Widget _buildMobileProfileContent(
      String name, String position, String teamName, String? pictureUrl) {
    return Column(
      children: [
        _buildProfileImage(pictureUrl, 80),
        const SizedBox(height: 20),
        _buildProfileInfo(name, position, teamName, false),
      ],
    );
  }

  Widget _buildDesktopProfileContent(String name, String position,
      String teamName, String? pictureUrl, bool isTablet) {
    return Row(
      children: [
        _buildProfileImage(pictureUrl, isTablet ? 120 : 100),
        SizedBox(width: isTablet ? 32 : 24),
        Expanded(child: _buildProfileInfo(name, position, teamName, true)),
      ],
    );
  }

  Widget _buildProfileImage(String? pictureUrl, double size) {
    return Hero(
      tag: 'player_avatar_${widget.playerDoc.id}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.white,
          backgroundImage: (pictureUrl != null && pictureUrl.isNotEmpty)
              ? NetworkImage(pictureUrl)
              : const AssetImage("assets/images/default_profile.jpeg")
                  as ImageProvider,
          onBackgroundImageError: (e, s) =>
              debugPrint("Error loading image: $e"),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(
      String name, String position, String teamName, bool isRow) {
    return Column(
      crossAxisAlignment:
          isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: isRow ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            position,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          teamName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
          textAlign: isRow ? TextAlign.start : TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabletLayout(String position, String teamName,
      Timestamp? birthDate, Map<String, dynamic>? attendanceData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildBasicInfoCard(position, teamName, birthDate),
              if (attendanceData != null) ...[
                const SizedBox(height: 24),
                _buildAttendanceCard(attendanceData),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: _buildTrainingStatsCard()),
      ],
    );
  }

  Widget _buildMobileLayout(String position, String teamName,
      Timestamp? birthDate, Map<String, dynamic>? attendanceData) {
    return Column(
      children: [
        _buildBasicInfoCard(position, teamName, birthDate),
        if (attendanceData != null) ...[
          const SizedBox(height: 24),
          _buildAttendanceCard(attendanceData),
        ],
        const SizedBox(height: 24),
        _buildTrainingStatsCard(),
      ],
    );
  }

  Widget _buildBasicInfoCard(
      String position, String teamName, Timestamp? birthDate) {
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
                'Basic Information',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(
              Icons.sports_soccer, 'Position', position, Colors.orange),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.group_work, 'Team', teamName, Colors.green),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.cake_outlined, 'Birth Date',
              _formatDateOnly(birthDate), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> attendanceData) {
    final bool? presence = attendanceData['Presence'] as bool?;
    final Timestamp? startTraining =
        attendanceData['Start_training'] as Timestamp?;
    final Timestamp? finishTraining =
        attendanceData['Finish_training'] as Timestamp?;
    final String? trainingType = attendanceData['Training_type'] as String?;

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
                  color: presence == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  presence == true ? Icons.check_circle : Icons.cancel,
                  color: presence == true
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Session',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: presence == true
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        presence == true ? 'Present' : 'Absent',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: presence == true
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.fitness_center, 'Training Type',
              trainingType ?? 'N/A', Colors.blue),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.timer_outlined, 'Session Start',
              _formatTimestamp(startTraining), Colors.indigo),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.timer_off_outlined, 'Session End',
              _formatTimestamp(finishTraining), Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildTrainingStatsCard() {
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart,
                    color: Colors.orange.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'Training Summary',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading statistics...',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else if (_trainingStats.isNotEmpty) ...[
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _statsAnimation.value,
                  child: Opacity(
                    opacity: _statsAnimation.value,
                    child: Column(
                      children: [
                        ..._trainingStats.entries.map((entry) {
                          final index =
                              _trainingStats.keys.toList().indexOf(entry.key);
                          return TweenAnimationBuilder<double>(
                            duration:
                                Duration(milliseconds: 800 + (index * 200)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset((1 - value) * 50, 0),
                                child: Opacity(
                                  opacity: value,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade50,
                                          Colors.grey.shade100
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade600,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '${entry.value} minutes',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        _buildSummaryStats(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ] else
            Center(
              child: Column(
                children: [
                  Icon(Icons.sports_soccer,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No training sessions recorded for this player.',
                    style: GoogleFonts.inter(
                        fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalMinutes =
        _trainingStats.values.fold(0, (sum, minutes) => sum + minutes);
    final totalSessions = _trainingStats.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Total Minutes', totalMinutes.toString(),
                Icons.timer, Colors.blue),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          Expanded(
            child: _buildStatItem('Sessions Attended', totalSessions.toString(),
                Icons.event, Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
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
          onPressed: _isGeneratingPdf ? null : _generatePlayerReport,
          backgroundColor:
              _isGeneratingPdf ? Colors.grey.shade400 : const Color(0xFF667eea),
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGeneratingPdf) ...[
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

  // Training minutes calculation function - optimized for performance
  Future<Map<String, int>> calculateMinutesByTrainingType(
      String playerId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('training_sessions')
          .get();

      final Map<String, int> trainingTypeMinutes = {};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final dynamic playersField = data['players'];

        if (playersField == null || playersField is! List) continue;

        final players = playersField;
        final trainingType = data['training_type'] ?? 'Unknown';

        for (final player in players) {
          if (player is Map<String, dynamic> &&
              player['player_id'] == playerId &&
              player['present'] == true) {
            final minutes =
                int.tryParse(player['minutes']?.toString() ?? '0') ?? 0;
            trainingTypeMinutes[trainingType] =
                (trainingTypeMinutes[trainingType] ?? 0) + minutes;
          }
        }
      }

      return trainingTypeMinutes;
    } catch (e) {
      debugPrint('Error calculating training minutes: $e');
      return {};
    }
  }
}
