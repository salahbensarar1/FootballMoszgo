import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:footballtraining/services/coach_data_consistency_fixer.dart';

/// 🚨 EMERGENCY BUTTON: Fix coach assignment data inconsistencies
class EmergencyDataFixButton extends StatefulWidget {
  const EmergencyDataFixButton({super.key});

  @override
  State<EmergencyDataFixButton> createState() => _EmergencyDataFixButtonState();
}

class _EmergencyDataFixButtonState extends State<EmergencyDataFixButton> {
  bool _isFixing = false;
  String? _fixResults;

  Future<void> _runEmergencyFix() async {
    if (_isFixing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Text(
              'Emergency Data Fix',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'This will fix coach assignment inconsistencies between teams and users collections. '
          'It will:\n\n'
          '• Synchronize all coach assignments\n'
          '• Fix field name mismatches (userId vs coach_id)\n'
          '• Update primary_coach references\n'
          '• Ensure bidirectional consistency\n\n'
          'This is safe to run multiple times.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Run Fix',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isFixing = true;
      _fixResults = null;
    });

    try {
      final results = await CoachDataConsistencyFixer.fixAllCoachAssignments();
      
      final fixedAssignments = results['fixed_assignments'] as List<Map<String, dynamic>>;
      final teamsProcessed = results['teams_processed'];
      final usersProcessed = results['users_processed'];
      final assignmentsFixed = results['assignments_fixed'];
      final errors = results['errors'] as List<String>;
      
      setState(() {
        _fixResults = '''
🎉 Emergency Fix Completed!

📊 Summary:
• $teamsProcessed teams processed
• $usersProcessed users processed  
• $assignmentsFixed assignments fixed

${fixedAssignments.isNotEmpty ? '\n✅ Fixed Assignments:\n${fixedAssignments.map((assignment) => '• ${assignment['coach_name']}: ${assignment['teams_assigned']} teams').join('\n')}' : ''}

${errors.isNotEmpty ? '\n⚠️ Errors:\n${errors.join('\n')}' : ''}
        ''';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Emergency fix completed! $assignmentsFixed assignments fixed.'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _fixResults = '❌ Fix failed: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Fix failed: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() {
        _isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _isFixing ? null : _runEmergencyFix,
          icon: _isFixing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.build_rounded, color: Colors.white),
          label: Text(
            _isFixing ? 'Fixing Data...' : '🚨 Emergency Fix Coach Data',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        if (_fixResults != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              _fixResults!,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}