import 'package:logger/logger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../config/environment.dart';

/// Production-grade logging service with structured logging,
/// filtering, and crash reporting integration
class LoggingService {
  static Logger? _logger;
  static FirebaseCrashlytics? _crashlytics;
  
  /// Initialize the logging service
  static void initialize() {
    if (_logger != null) return;
    
    // Safely check development mode with fallback
    bool isDevelopment = true; // Default to development
    try {
      isDevelopment = Environment.isDevelopment;
    } catch (e) {
      // If Environment isn't initialized yet, assume development
      isDevelopment = true;
    }
    
    _logger = Logger(
      filter: _LogFilter(),
      printer: isDevelopment 
          ? PrettyPrinter(
              methodCount: 2,
              errorMethodCount: 8,
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            )
          : SimplePrinter(),
      output: _LogOutput(),
    );
    
    // Initialize Crashlytics if available
    try {
      _crashlytics = FirebaseCrashlytics.instance;
    } catch (e) {
      // Crashlytics not available, continue without it
    }
  }
  
  /// Get logger instance
  static Logger get logger {
    if (_logger == null) {
      initialize();
    }
    return _logger!;
  }
  
  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.w(message, error: error, stackTrace: stackTrace);
    
    // Send non-fatal error to Crashlytics
    if (_crashlytics != null && Environment.isProduction) {
      _crashlytics!.recordError(error ?? message, stackTrace, 
          reason: 'Warning logged', fatal: false);
    }
  }
  
  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.e(message, error: error, stackTrace: stackTrace);
    
    // Send error to Crashlytics
    if (_crashlytics != null && (Environment.isProduction || Environment.isStaging)) {
      _crashlytics!.recordError(error ?? message, stackTrace, 
          reason: message, fatal: false);
    }
  }
  
  /// Log fatal error
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    logger.f(message, error: error, stackTrace: stackTrace);
    
    // Send fatal error to Crashlytics
    if (_crashlytics != null && (Environment.isProduction || Environment.isStaging)) {
      _crashlytics!.recordError(error ?? message, stackTrace, 
          reason: message, fatal: true);
    }
  }
  
  /// Log user action for analytics
  static void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    final logMessage = 'User Action: $action';
    if (parameters != null) {
      info('$logMessage - Parameters: $parameters');
    } else {
      info(logMessage);
    }
  }
  
  /// Log API call
  static void logApiCall(String endpoint, String method, {int? statusCode, String? error}) {
    final message = 'API Call: $method $endpoint';
    if (error != null) {
      LoggingService.error('$message - Error: $error');
    } else if (statusCode != null) {
      LoggingService.info('$message - Status: $statusCode');
    } else {
      LoggingService.debug(message);
    }
  }
  
  /// Log performance metric
  static void logPerformance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');
  }
}

/// Custom log filter that respects environment settings
class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (!Environment.enableLogging) return false;
    
    // In production, only log warnings and errors
    if (Environment.isProduction) {
      return event.level.index >= Level.warning.index;
    }
    
    // In staging, log info and above
    if (Environment.isStaging) {
      return event.level.index >= Level.info.index;
    }
    
    // In development, log everything
    return true;
  }
}

/// Custom log output that can be extended for remote logging
class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // Default console output
    for (final line in event.lines) {
      // ignore: avoid_print
      print(line);
    }
    
    // TODO: Add remote logging service here if needed
    // e.g., send to external logging service in production
  }
}

/// Extension methods for easier logging
extension LoggingExtensions on Object {
  void logDebug(String message) {
    LoggingService.debug('${runtimeType.toString()}: $message');
  }
  
  void logInfo(String message) {
    LoggingService.info('${runtimeType.toString()}: $message');
  }
  
  void logWarning(String message, [dynamic error]) {
    LoggingService.warning('${runtimeType.toString()}: $message', error);
  }
  
  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    LoggingService.error('${runtimeType.toString()}: $message', error, stackTrace);
  }
}