import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/data/models/user_model.dart' as UserModel;

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUserId => _auth.currentUser?.uid ?? 'unknown';

  Future<UserModel.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? UserModel.User.fromFirestore(doc) : null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<UserModel.User>> getCoaches() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'coach')
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.User.fromFirestore(doc))
            .toList());
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}
