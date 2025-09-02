import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logging_service.dart';

/// Service for persisting organization setup progress locally
class SetupPersistenceService {
  static const String _setupProgressKey = 'setup_in_progress';
  static const String _setupDataKey = 'setup_temp_data';
  static const String _setupTimestampKey = 'setup_start_timestamp';
  static const int _setupTimeoutMinutes = 30;

  /// Save setup progress with current step and data
  static Future<void> saveProgress({
    required String tempOrgId,
    required int currentStep,
    required Map<String, dynamic> formData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await Future.wait([
        prefs.setString(_setupProgressKey, tempOrgId),
        prefs.setString(_setupDataKey, jsonEncode({
          'current_step': currentStep,
          'org_id': tempOrgId,
          'form_data': formData,
        })),
        prefs.setInt(_setupTimestampKey, timestamp),
      ]);
      
      LoggingService.info('Setup progress saved: step $currentStep');
    } catch (e, stackTrace) {
      LoggingService.error('Failed to save setup progress', e, stackTrace);
    }
  }

  /// Load saved setup progress
  static Future<Map<String, dynamic>?> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final progressId = prefs.getString(_setupProgressKey);
      final dataJson = prefs.getString(_setupDataKey);
      final timestamp = prefs.getInt(_setupTimestampKey);
      
      if (progressId == null || dataJson == null || timestamp == null) {
        return null;
      }
      
      // Check if setup is expired (older than 30 minutes)
      final setupTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final isExpired = DateTime.now().difference(setupTime).inMinutes > _setupTimeoutMinutes;
      
      if (isExpired) {
        LoggingService.info('Setup progress expired, clearing');
        await clearProgress();
        return null;
      }
      
      final data = jsonDecode(dataJson) as Map<String, dynamic>;
      LoggingService.info('Setup progress loaded: step ${data['current_step']}');
      
      return data;
    } catch (e, stackTrace) {
      LoggingService.error('Failed to load setup progress', e, stackTrace);
      await clearProgress(); // Clear corrupted data
      return null;
    }
  }

  /// Clear all setup progress
  static Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_setupProgressKey),
        prefs.remove(_setupDataKey),
        prefs.remove(_setupTimestampKey),
      ]);
      LoggingService.info('Setup progress cleared');
    } catch (e, stackTrace) {
      LoggingService.error('Failed to clear setup progress', e, stackTrace);
    }
  }

  /// Check if setup is in progress
  static Future<bool> isSetupInProgress() async {
    final progress = await loadProgress();
    return progress != null;
  }

  /// Update current step only
  static Future<void> updateCurrentStep(int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString(_setupDataKey);
      
      if (dataJson != null) {
        final data = jsonDecode(dataJson) as Map<String, dynamic>;
        data['current_step'] = step;
        await prefs.setString(_setupDataKey, jsonEncode(data));
      }
    } catch (e, stackTrace) {
      LoggingService.error('Failed to update setup step', e, stackTrace);
    }
  }

  /// Mark setup as completed
  static Future<void> markCompleted() async {
    await clearProgress();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_completed', true);
      await prefs.setInt('setup_completed_at', DateTime.now().millisecondsSinceEpoch);
      LoggingService.info('Setup marked as completed');
    } catch (e, stackTrace) {
      LoggingService.error('Failed to mark setup as completed', e, stackTrace);
    }
  }

  /// Check if setup was ever completed
  static Future<bool> hasCompletedSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('setup_completed') ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// Debouncer utility for button presses
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Button state manager for preventing double-tap
class ButtonStateManager {
  bool _isProcessing = false;
  final Map<String, DateTime> _lastPressTime = {};
  static const int _debounceMs = 500;

  /// Check if button press should be processed
  bool canProcess(String buttonId) {
    if (_isProcessing) return false;
    
    final now = DateTime.now();
    final lastPress = _lastPressTime[buttonId];
    
    if (lastPress != null && 
        now.difference(lastPress).inMilliseconds < _debounceMs) {
      return false;
    }
    
    _lastPressTime[buttonId] = now;
    return true;
  }

  /// Mark processing as started
  void startProcessing() {
    _isProcessing = true;
  }

  /// Mark processing as finished
  void finishProcessing() {
    _isProcessing = false;
  }

  /// Get current processing state
  bool get isProcessing => _isProcessing;

  /// Reset all state
  void reset() {
    _isProcessing = false;
    _lastPressTime.clear();
  }
}