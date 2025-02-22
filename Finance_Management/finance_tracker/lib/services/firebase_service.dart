import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  static Future<UserCredential?> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  static Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore methods
  static Future<void> saveTransaction(Map<String, dynamic> transaction) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    transaction['userId'] = user.uid;
    transaction['timestamp'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add(transaction);
  }

  static Stream<QuerySnapshot> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Future<void> updateTransaction(String id, Map<String, dynamic> transaction) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id)
        .update(transaction);
  }

  static Future<void> deleteTransaction(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(id)
        .delete();
  }
}
