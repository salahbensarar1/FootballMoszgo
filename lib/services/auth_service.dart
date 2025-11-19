import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/services/organization_context.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AuthService {
  static Future<AuthResult> loginUser(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Authentication failed");

      String? userRole;
      String? organizationId;

      // OPTIMIZED: Use collectionGroup query instead of N+1 queries
      // This replaces 1 + N queries with a single indexed query
      final userQuery = await FirebaseFirestore.instance
          .collectionGroup('users')
          .where('email', isEqualTo: user.email)
          .where('is_active', isEqualTo: true)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        userRole = userData['role'];

        // Extract organization ID from document path: organizations/{orgId}/users/{userId}
        final pathSegments = userQuery.docs.first.reference.path.split('/');
        organizationId = pathSegments[1];
      }

      if (userRole == null || organizationId == null) {
        throw Exception("User not found in any organization");
      }

      await OrganizationContext.initialize(specificOrgId: organizationId);

      return AuthResult.success(userRole);
    } catch (e) {
      return AuthResult.error(e.toString());
    }
  }

  static String getErrorMessage(String error, AppLocalizations l10n) {
    if (error.contains('user-not-found')) return l10n.userNotFound;
    if (error.contains('wrong-password')) return l10n.wrongPassword;
    if (error.contains('invalid-email')) return l10n.invalidEmail;
    if (error.contains('user-disabled')) return l10n.userDisabled;
    if (error.contains('too-many-requests')) return l10n.tooManyRequests;
    if (error.contains('network-request-failed')) return l10n.networkError;
    if (error.contains('User not found in any organization')) {
      return 'User not registered in any organization.';
    }
    if (error.contains('Unauthorized role')) {
      return 'Access denied. Contact your administrator.';
    }
    return l10n.loginFailed;
  }
}

class AuthResult {
  final bool isSuccess;
  final String? userRole;
  final String? error;

  AuthResult._(this.isSuccess, this.userRole, this.error);

  factory AuthResult.success(String userRole) => AuthResult._(true, userRole, null);
  factory AuthResult.error(String error) => AuthResult._(false, null, error);
}