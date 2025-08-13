import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/user_model.dart' as user_model;

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  Future<user_model.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? user_model.User.fromFirestore(doc) : null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<user_model.User>> getCoaches() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => user_model.User.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
