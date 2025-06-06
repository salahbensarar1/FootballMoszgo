import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExportReportDialog extends StatefulWidget {
  const ExportReportDialog({super.key});

  @override
  State<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends State<ExportReportDialog> {
  String selectedFormat = 'pdf';
  String selectedType = 'overview';
  String selectedPeriod = 'current_year';
  bool includeCharts = true;
  bool includePlayerDetails = true;
  bool includeTeamSummary = true;
  bool isProcessing = false;

  final Map<String, String> reportTypes = {
    'overview': 'Payment Overview',
    'detailed': 'Detailed Report',
    'unpaid': 'Unpaid Players Only',
    'monthly': 'Monthly Summary',
    'team_wise': 'Team-wise Report',
    'collection_trend': 'Collection Trends',
  };

  final Map<String, String> formatTypes = {
    'pdf': 'PDF Document',
    'excel': 'Excel Spreadsheet',
    'csv': 'CSV File',
    'json': 'JSON Data',
  };

  final Map<String, String> periodTypes = {
    'current_year': 'Current Year',
    'last_year': 'Previous Year',
    'current_month': 'Current Month',
    'last_3_months': 'Last 3 Months',
    'last_6_months': 'Last 6 Months',
    'custom': 'Custom Range',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.file_download_rounded,
                color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Report',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Generate and download payment report',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selection
            _buildSectionTitle('Report Type'),
            const SizedBox(height: 8),
            _buildReportTypeDropdown(),
            const SizedBox(height: 16),

            // Format Selection
            _buildSectionTitle('Export Format'),
            const SizedBox(height: 8),
            _buildFormatDropdown(),
            const SizedBox(height: 16),

            // Period Selection
            _buildSectionTitle('Time Period'),
            const SizedBox(height: 8),
            _buildPeriodDropdown(),
            const SizedBox(height: 16),

            // Export Options
            _buildSectionTitle('Include Options'),
            const SizedBox(height: 8),
            _buildExportOptions(),
            const SizedBox(height: 16),

            // Export Preview
            _buildExportPreview(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isProcessing ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: isProcessing ? null : _processExport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            disabledBackgroundColor: Colors.grey.shade300,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Export ${selectedFormat.toUpperCase()}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildReportTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedType,
        decoration: InputDecoration(
          prefixIcon:
              Icon(Icons.description_rounded, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: reportTypes.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedType = value!),
      ),
    );
  }

  Widget _buildFormatDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedFormat,
        decoration: InputDecoration(
          prefixIcon:
              Icon(_getFormatIcon(selectedFormat), color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: formatTypes.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(_getFormatIcon(entry.key),
                    size: 16, color: _getFormatColor(entry.key)),
                const SizedBox(width: 8),
                Text(
                  entry.value,
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedFormat = value!),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedPeriod,
        decoration: InputDecoration(
          prefixIcon:
              Icon(Icons.calendar_today_rounded, color: Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: periodTypes.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: GoogleFonts.poppins(),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => selectedPeriod = value!),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            'Include Charts & Graphs',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Visual representations of payment data',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includeCharts,
          onChanged: selectedFormat == 'csv' || selectedFormat == 'json'
              ? null
              : (value) => setState(() => includeCharts = value ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(
            'Player Details',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Individual player payment information',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includePlayerDetails,
          onChanged: (value) =>
              setState(() => includePlayerDetails = value ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(
            'Team Summary',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          subtitle: Text(
            'Team-wise payment statistics',
            style:
                GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          ),
          value: includeTeamSummary,
          onChanged: (value) =>
              setState(() => includeTeamSummary = value ?? true),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildExportPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview_rounded,
                color: const Color(0xFF10B981),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Export Preview',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPreviewRow('Report Type:', reportTypes[selectedType]!),
          _buildPreviewRow('Format:', formatTypes[selectedFormat]!),
          _buildPreviewRow('Period:', periodTypes[selectedPeriod]!),
          _buildPreviewRow('File Size:', _getEstimatedSize()),
          if (selectedFormat == 'pdf' || selectedFormat == 'excel')
            _buildPreviewRow(
                'Charts:', includeCharts ? 'Included' : 'Excluded'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'excel':
        return Icons.table_chart_rounded;
      case 'csv':
        return Icons.grid_on_rounded;
      case 'json':
        return Icons.code_rounded;
      default:
        return Icons.file_copy_rounded;
    }
  }

  Color _getFormatColor(String format) {
    switch (format) {
      case 'pdf':
        return Colors.red.shade600;
      case 'excel':
        return Colors.green.shade600;
      case 'csv':
        return Colors.blue.shade600;
      case 'json':
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getEstimatedSize() {
    // Simple estimation based on format and options
    int baseSize = 50; // KB

    if (selectedFormat == 'pdf') baseSize += 200;
    if (selectedFormat == 'excel') baseSize += 100;
    if (includeCharts) baseSize += 150;
    if (includePlayerDetails) baseSize += 100;
    if (includeTeamSummary) baseSize += 50;

    if (baseSize < 1024) {
      return '${baseSize}KB';
    } else {
      return '${(baseSize / 1024).toStringAsFixed(1)}MB';
    }
  }

  Future<void> _processExport() async {
    setState(() => isProcessing = true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(height: 16),
              Text(
                'Generating ${formatTypes[selectedFormat]}...',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few moments',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );

      // Simulate export process
      await Future.delayed(const Duration(seconds: 3));

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close export dialog

      _showSuccessSnackBar(
          '${formatTypes[selectedFormat]} exported successfully! Check your downloads folder.');
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorSnackBar('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
