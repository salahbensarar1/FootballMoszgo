import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized service for managing snackbars and user messages
class GlobalMessengerService {
  static GlobalMessengerService? _instance;
  static GlobalMessengerService get instance => _instance ??= GlobalMessengerService._();
  
  GlobalMessengerService._();

  GlobalKey<ScaffoldMessengerState>? _messengerKey;

  void initialize(GlobalKey<ScaffoldMessengerState> messengerKey) {
    _messengerKey = messengerKey;
  }

  void showSuccess(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  void showError(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  void showWarning(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.orange.shade600,
      icon: Icons.warning_rounded,
      duration: duration,
    );
  }

  void showInfo(String message, {Duration? duration}) {
    _showSnackBar(
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration? duration,
  }) {
    final messengerState = _messengerKey?.currentState;
    if (messengerState == null) return;

    messengerState.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void hideCurrentSnackBar() {
    _messengerKey?.currentState?.hideCurrentSnackBar();
  }

  void clearSnackBars() {
    _messengerKey?.currentState?.clearSnackBars();
  }
}