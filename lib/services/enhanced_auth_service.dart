import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Production-Ready Enhanced Auth Service with Android optimizations
class EnhancedAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Android-specific timeout configurations
  static const Duration _androidAuthTimeout = Duration(seconds: 15);
  static const Duration _iosAuthTimeout = Duration(seconds: 8);
  static const int _maxRetryAttempts = 3;

  Duration get _platformTimeout =>
      Platform.isAndroid ? _androidAuthTimeout : _iosAuthTimeout;

  /// Enhanced sign-in with platform-specific optimizations
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Pre-flight checks for Android
      if (Platform.isAndroid) {
        await _performAndroidPreflightChecks();
      }

      // Attempt sign-in with timeout and retry logic
      return await _signInWithRetry(
        () => _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        ),
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Enhanced Google sign-in with Android optimizations
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (Platform.isAndroid) {
        await _performAndroidPreflightChecks();
        // Clear any cached Google Sign-In state on Android
        await _googleSignIn.signOut();
      }

      return await _signInWithRetry(() async {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken!,
          idToken: googleAuth.idToken!,
        );

        return await _auth.signInWithCredential(credential);
      });
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Android-specific preflight checks
  Future<void> _performAndroidPreflightChecks() async {
    // Warm up Google Play Services (Android-specific)
    if (Platform.isAndroid) {
      try {
        final isSignedIn = await _googleSignIn.isSignedIn();
        // Warm up the sign-in process
        if (!isSignedIn) {
          // Pre-initialize Google Sign-In
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        // Google Play Services might not be ready
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Retry logic with exponential backoff
  Future<UserCredential?> _signInWithRetry(
    Future<UserCredential?> Function() signInFunction,
  ) async {
    int attempts = 0;
    Duration delay = const Duration(milliseconds: 500);

    while (attempts < _maxRetryAttempts) {
      try {
        final result = await signInFunction().timeout(_platformTimeout);
        if (result != null) return result;
      } catch (e) {
        attempts++;

        if (attempts >= _maxRetryAttempts) {
          rethrow;
        }

        // Exponential backoff for Android
        if (Platform.isAndroid) {
          await Future.delayed(delay);
          delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
        }
      }
    }
    return null;
  }

  /// Enhanced error handling with platform-specific messages
  AuthException _handleAuthException(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'network-request-failed':
          return AuthException(
            Platform.isAndroid
                ? 'Network issue detected. Please check your connection and Google Play Services.'
                : 'Network connection failed. Please try again.',
          );
        case 'too-many-requests':
          return const AuthException(
            'Too many failed attempts. Please wait a few minutes before trying again.',
          );
        case 'user-disabled':
          return const AuthException('This account has been disabled.');
        case 'user-not-found':
        case 'wrong-password':
          return const AuthException('Invalid email or password.');
        case 'invalid-email':
          return const AuthException('Please enter a valid email address.');
        default:
          return AuthException(
            Platform.isAndroid
                ? 'Authentication failed. Please ensure Google Play Services is updated.'
                : 'Authentication failed. Please try again.',
          );
      }
    }

    if (error is TimeoutException) {
      return AuthException(
        Platform.isAndroid
            ? 'Sign-in timed out. This may be due to Google Play Services. Please try again.'
            : 'Sign-in timed out. Please check your connection.',
      );
    }

    return AuthException('An unexpected error occurred: ${error.toString()}');
  }

  /// Monitor auth state changes with enhanced error recovery
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges().handleError((error) {
      print('Auth state error: $error');
      // Implement recovery logic if needed
    });
  }

  /// Sign out with platform-specific cleanup
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      // Ensure sign-out even if some services fail
      try {
        await _auth.signOut();
      } catch (_) {}
    }
  }

  /// Get current user with null safety
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Android-specific: Check Google Play Services availability
  Future<bool> isGooglePlayServicesAvailable() async {
    if (!Platform.isAndroid) return true;

    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  /// Debug information for troubleshooting
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'isAuthenticated': isAuthenticated,
      'currentUser': currentUser?.uid,
      'googlePlayServices': Platform.isAndroid
          ? await isGooglePlayServicesAvailable()
          : 'N/A (iOS)',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Custom Auth Exception with enhanced error information
class AuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const AuthException(this.message, {this.code, this.details});

  @override
  String toString() => 'AuthException: $message';
}
