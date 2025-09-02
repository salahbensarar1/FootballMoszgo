import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';
import 'environment.dart';

/// Production-grade Firebase configuration with proper error handling,
/// logging, and environment-based setup
class FirebaseConfig {
  static final Logger _logger = Logger();
  static FirebaseApp? _app;
  static FirebaseAnalytics? _analytics;
  static FirebaseCrashlytics? _crashlytics;

  /// Initialize Firebase with environment-based configuration
  static Future<FirebaseApp> initializeFirebase() async {
    try {
      _logger.i(
          '🔥 Initializing Firebase for ${Environment.environment} environment');

      // Use default Firebase initialization (google-services.json)
      if (Firebase.apps.isEmpty) {
        _app = await Firebase.initializeApp(
            options: const FirebaseOptions(
          apiKey: 'AIzaSyA0ld4bnw5JlxBhHShltnH32jR6M3X8Gns',
          appId: '1:388672883836:android:ee63ec68ad71e4d97e0df9',
          messagingSenderId: '388672883836',
          projectId: 'foottraining-4051b',
          storageBucket: 'foottraining-4051b.firebasestorage.app',
        ));
      } else {
        _app = Firebase.app();
      }

      _logger.i('✅ Firebase app initialized using google-services.json');

      // Initialize additional Firebase services
      await _initializeFirebaseServices();

      return _app!;
    } catch (e, stackTrace) {
      _logger.e('❌ Firebase initialization failed',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Initialize additional Firebase services
  static Future<void> _initializeFirebaseServices() async {
    try {
      // Initialize Crashlytics (always available in this setup)
      try {
        _crashlytics = FirebaseCrashlytics.instance;

        // Check environment safely for production features
        bool isProduction = false;
        try {
          isProduction = Environment.isProduction || Environment.isStaging;
        } catch (e) {
          // If environment check fails, assume development
          isProduction = false;
        }

        // Enable crash collection in production
        await _crashlytics!.setCrashlyticsCollectionEnabled(isProduction);

        // Set up automatic crash reporting
        if (isProduction) {
          FlutterError.onError = (errorDetails) {
            _crashlytics!.recordFlutterFatalError(errorDetails);
          };
        }

        _logger.i('✅ Firebase Crashlytics initialized');
      } catch (e) {
        _logger.w('⚠️ Crashlytics initialization failed: $e');
      }

      // Initialize Analytics
      try {
        _analytics = FirebaseAnalytics.instance;

        // Configure analytics based on environment (safely)
        bool enableAnalytics = false;
        try {
          enableAnalytics = Environment.isProduction || Environment.isStaging;
        } catch (e) {
          // Default to false for development/unknown environments
          enableAnalytics = false;
        }

        await _analytics!.setAnalyticsCollectionEnabled(enableAnalytics);

        _logger.i('✅ Firebase Analytics initialized');
      } catch (e) {
        _logger.w('⚠️ Analytics initialization failed: $e');
      }
    } catch (e) {
      _logger.w('⚠️ Firebase services initialization failed: $e');
    }
  }

  /// Get Firebase Analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  /// Get Firebase Crashlytics instance
  static FirebaseCrashlytics? get crashlytics => _crashlytics;

  /// Get Firebase App instance
  static FirebaseApp? get app => _app;

  /// Log custom events for analytics
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      if (_analytics != null &&
          (Environment.isProduction || Environment.isStaging)) {
        await _analytics!.logEvent(
          name: name,
          parameters: parameters,
        );
        _logger.d('📊 Analytics event logged: $name');
      }
    } catch (e) {
      _logger.w('⚠️  Analytics event logging failed: $e');
    }
  }

  /// Report non-fatal errors to Crashlytics
  static Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    try {
      if (_crashlytics != null &&
          (Environment.isProduction || Environment.isStaging)) {
        await _crashlytics!.recordError(
          exception,
          stackTrace,
          reason: reason,
          fatal: fatal,
        );
        _logger.w('🚨 Error reported to Crashlytics: $exception');
      } else {
        _logger.w('🚨 Error (dev mode): $exception');
      }
    } catch (e) {
      _logger.e('❌ Failed to report error to Crashlytics: $e');
    }
  }

  /// Set user properties for analytics and crashlytics
  static Future<void> setUserProperties({
    required String userId,
    String? role,
    String? organization,
  }) async {
    try {
      // Set user for Crashlytics
      if (_crashlytics != null) {
        await _crashlytics!.setUserIdentifier(userId);
        if (role != null) {
          await _crashlytics!.setCustomKey('user_role', role);
        }
        if (organization != null) {
          await _crashlytics!.setCustomKey('organization', organization);
        }
      }

      // Set user for Analytics
      if (_analytics != null) {
        await _analytics!.setUserId(id: userId);
        if (role != null) {
          await _analytics!.setUserProperty(name: 'user_role', value: role);
        }
        if (organization != null) {
          await _analytics!
              .setUserProperty(name: 'organization', value: organization);
        }
      }

      _logger.i('👤 User properties set for Firebase services');
    } catch (e) {
      _logger.w('⚠️  Setting user properties failed: $e');
    }
  }

  /// Get Firebase configuration summary (for debugging)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'app_initialized': _app != null,
      'analytics_initialized': _analytics != null,
      'crashlytics_initialized': _crashlytics != null,
      'environment': Environment.environment,
      'project_id': Environment.firebaseProjectId,
    };
  }
}
