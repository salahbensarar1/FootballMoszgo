import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to add is_active field to all users
/// Use this once in your app to migrate existing users
class MigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add is_active: true field to all users who don't have it
  static Future<Map<String, int>> addIsActiveFieldToAllUsers() async {
    int organizationsProcessed = 0;
    int usersUpdated = 0;
    int usersAlreadyHaveField = 0;

    try {
      // Get all organizations
      final organizations = await _firestore.collection('organizations').get();

      for (final org in organizations.docs) {
        organizationsProcessed++;

        // Get all users in this organization
        final users = await org.reference.collection('users').get();

        for (final userDoc in users.docs) {
          final userData = userDoc.data();

          // Check if user already has is_active field
          if (userData.containsKey('is_active')) {
            usersAlreadyHaveField++;
          } else {
            // Add is_active: true field
            await userDoc.reference.update({'is_active': true});
            usersUpdated++;

            // Small delay to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      }

      return {
        'organizationsProcessed': organizationsProcessed,
        'usersUpdated': usersUpdated,
        'usersAlreadyHaveField': usersAlreadyHaveField,
        'totalUsers': usersUpdated + usersAlreadyHaveField,
      };
    } catch (e) {
      rethrow;
    }
  }
}