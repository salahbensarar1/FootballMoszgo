import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Production-grade environment configuration
/// Handles different environments (dev, staging, prod) securely
class Environment {
  // Private constructor to prevent instantiation
  Environment._();
  
  /// Initialize environment configuration
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Fallback for development - try without file extension or create default
      try {
        await dotenv.load(fileName: "env");  
      } catch (e2) {
        // If no .env file exists, initialize with defaults for development
        if (!dotenv.isInitialized) {
          dotenv.testLoad(fileInput: '''
# Default Development Environment
APP_NAME=Football Training Manager
APP_VERSION=1.0.0
ENVIRONMENT=development
FIREBASE_PROJECT_ID=foottraining-4051b
FIREBASE_API_KEY_ANDROID=AIzaSyBPwPSHkw1rupR_PCwaaKeFknpSqoBeUfM
FIREBASE_API_KEY_IOS=AIzaSyBPwPSHkw1rupR_PCwaaKeFknpSqoBeUfM
FIREBASE_APP_ID_ANDROID=1:388672883836:android:924ffce1dc97af7d7e0df9
FIREBASE_APP_ID_IOS=1:388672883836:ios:5d90d92b8467e1407e0df9
FIREBASE_MESSAGING_SENDER_ID=388672883836
FIREBASE_STORAGE_BUCKET=foottraining-4051b.appspot.com
DEBUG_MODE=true
ENABLE_LOGGING=true
MOCK_DATA=false
''');
        }
      }
    }
  }
  
  // App Configuration
  static String get appName => dotenv.get('APP_NAME', fallback: 'Football Training');
  static String get appVersion => dotenv.get('APP_VERSION', fallback: '1.0.0');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');
  
  // Environment Checks
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';
  
  // Firebase Configuration
  static String get firebaseProjectId => dotenv.get('FIREBASE_PROJECT_ID');
  static String get firebaseApiKeyAndroid => dotenv.get('FIREBASE_API_KEY_ANDROID');
  static String get firebaseApiKeyIOS => dotenv.get('FIREBASE_API_KEY_IOS');
  static String get firebaseAppIdAndroid => dotenv.get('FIREBASE_APP_ID_ANDROID');
  static String get firebaseAppIdIOS => dotenv.get('FIREBASE_APP_ID_IOS');
  static String get firebaseMessagingSenderId => dotenv.get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseStorageBucket => dotenv.get('FIREBASE_STORAGE_BUCKET');
  
  // Feature Flags
  static bool get debugMode => dotenv.get('DEBUG_MODE', fallback: 'false').toLowerCase() == 'true';
  static bool get enableLogging => dotenv.get('ENABLE_LOGGING', fallback: 'true').toLowerCase() == 'true';
  static bool get mockData => dotenv.get('MOCK_DATA', fallback: 'false').toLowerCase() == 'true';
  
  // External Services (Optional)
  static String get emailServiceApiKey => dotenv.get('EMAIL_SERVICE_API_KEY', fallback: '');
  static String get analyticsTrackingId => dotenv.get('ANALYTICS_TRACKING_ID', fallback: '');
  
  /// Validate that all required environment variables are present
  static void validate() {
    final requiredVars = [
      'FIREBASE_PROJECT_ID',
      'FIREBASE_API_KEY_ANDROID', 
      'FIREBASE_API_KEY_IOS',
      'FIREBASE_APP_ID_ANDROID',
      'FIREBASE_APP_ID_IOS',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_STORAGE_BUCKET',
    ];
    
    for (final variable in requiredVars) {
      if (!dotenv.env.containsKey(variable) || dotenv.get(variable).isEmpty) {
        throw EnvironmentException('Required environment variable $variable is missing or empty');
      }
    }
  }
  
  /// Get configuration summary for debugging (hides sensitive data)
  static Map<String, dynamic> getConfigSummary() {
    return {
      'app_name': appName,
      'app_version': appVersion,
      'environment': environment,
      'debug_mode': debugMode,
      'enable_logging': enableLogging,
      'mock_data': mockData,
      'firebase_project': firebaseProjectId,
      'has_email_service': emailServiceApiKey.isNotEmpty,
      'has_analytics': analyticsTrackingId.isNotEmpty,
    };
  }
}

/// Custom exception for environment configuration errors
class EnvironmentException implements Exception {
  final String message;
  const EnvironmentException(this.message);
  
  @override
  String toString() => 'EnvironmentException: $message';
}

/// Environment-specific configuration builder
class EnvironmentConfig {
  static T getConfig<T>({
    required T development,
    required T staging,
    required T production,
  }) {
    switch (Environment.environment) {
      case 'development':
        return development;
      case 'staging':
        return staging;
      case 'production':
        return production;
      default:
        return development;
    }
  }
}