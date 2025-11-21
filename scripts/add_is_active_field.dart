import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to add is_active: true field to all users who don't have it
/// Run this once to update all existing users in Firestore
///
/// Usage: dart run scripts/add_is_active_field.dart

void main() async {
  print('🔧 Starting is_active field migration script...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    int organizationsProcessed = 0;
    int usersUpdated = 0;
    int usersAlreadyHaveField = 0;

    // Get all organizations
    print('📋 Fetching organizations...');
    final organizations = await firestore.collection('organizations').get();
    print('Found ${organizations.docs.length} organizations');

    for (final org in organizations.docs) {
      print('\n🏢 Processing organization: ${org.id}');
      organizationsProcessed++;

      // Get all users in this organization
      final users = await org.reference.collection('users').get();
      print('  📊 Found ${users.docs.length} users in this organization');

      for (final userDoc in users.docs) {
        final userData = userDoc.data();
        final userEmail = userData['email'] ?? 'unknown';

        // Check if user already has is_active field
        if (userData.containsKey('is_active')) {
          print('  ✓ User $userEmail already has is_active field: ${userData['is_active']}');
          usersAlreadyHaveField++;
        } else {
          // Add is_active: true field
          await userDoc.reference.update({'is_active': true});
          print('  🔄 Added is_active: true to user: $userEmail');
          usersUpdated++;

          // Small delay to avoid rate limiting
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    }

    print('\n🎉 Migration completed successfully!');
    print('📈 Summary:');
    print('   - Organizations processed: $organizationsProcessed');
    print('   - Users updated: $usersUpdated');
    print('   - Users already had field: $usersAlreadyHaveField');
    print('   - Total users: ${usersUpdated + usersAlreadyHaveField}');

  } catch (e) {
    print('❌ Error during migration: $e');
    exit(1);
  }

  print('\n✅ All done! Users can now authenticate with the is_active field requirement.');
  exit(0);
}