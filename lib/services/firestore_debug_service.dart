import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple debug service to test Firestore permissions
class FirestoreDebugService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Test anonymous authentication and Firestore access
  Future<void> testFirestoreAccess() async {
    try {
      print('🔍 Testing Firestore access...');

      // Check current user
      final currentUser = _auth.currentUser;
      print(
          'Current user: ${currentUser?.uid ?? 'null'} (isAnonymous: ${currentUser?.isAnonymous ?? false})');

      if (currentUser == null) {
        print('No user signed in, attempting anonymous sign-in...');
        await _auth.signInAnonymously();
        print('✅ Anonymous sign-in successful');
      }

      // Test reading organizations collection
      print('Testing organizations collection read...');
      final orgsQuery =
          await _firestore.collection('organizations').limit(1).get();
      print(
          '✅ Organizations collection read successful. Count: ${orgsQuery.docs.length}');

      // Test creating a test document
      print('Testing document creation...');
      final testDocRef = _firestore.collection('test_collection').doc();
      await testDocRef.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': _auth.currentUser?.uid,
      });
      print('✅ Test document created successfully');

      // Clean up test document
      await testDocRef.delete();
      print('✅ Test document deleted successfully');

      print('🎉 All Firestore tests passed!');
    } catch (e, stackTrace) {
      print('❌ Firestore test failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Test the organization creation flow specifically
  Future<void> testOrganizationCreation() async {
    try {
      print('🔍 Testing organization creation flow...');

      // Ensure authentication
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        print('✅ Anonymous authentication for org creation');
      }

      // Test organization creation
      final orgRef = _firestore.collection('organizations').doc();
      final testOrgData = {
        'name': 'Test Club ${DateTime.now().millisecondsSinceEpoch}',
        'address': 'Test Address',
        'type': 'club',
        'admin_user_id': '',
        'created_at': FieldValue.serverTimestamp(),
        'status': 'trial',
      };

      await orgRef.set(testOrgData);
      print('✅ Test organization created with ID: ${orgRef.id}');

      // Test reading the created organization
      final orgDoc = await orgRef.get();
      if (orgDoc.exists) {
        print('✅ Test organization read successfully');
        print('Data: ${orgDoc.data()}');
      } else {
        print('❌ Test organization not found after creation');
      }

      // Clean up
      await orgRef.delete();
      print('✅ Test organization deleted');

      print('🎉 Organization creation test passed!');
    } catch (e, stackTrace) {
      print('❌ Organization creation test failed: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Test with email/password authentication
  Future<void> testWithEmailAuth({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 Testing with email/password authentication...');

      // Try to create user account
      UserCredential? userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Email/password user created: ${userCredential.user?.uid}');
      } catch (e) {
        // User might already exist, try signing in
        print('User creation failed, trying sign in: $e');
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print(
            '✅ Email/password sign in successful: ${userCredential.user?.uid}');
      }

      // Test Firestore operations with authenticated user
      await testFirestoreAccess();
      await testOrganizationCreation();

      print('🎉 Email/password authentication test passed!');
    } catch (e, stackTrace) {
      print('❌ Email/password authentication test failed: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
