import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/user_model.dart' as user_model;
import 'package:footballtraining/services/organization_context.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  /// Returns the org-scoped users collection reference.
  CollectionReference get _usersCollection =>
      OrganizationContext.getCollection('users');

  Future<user_model.User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists
          ? user_model.User.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>)
          : null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<user_model.User>> getCoaches() {
    return _usersCollection
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => user_model.User.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}
