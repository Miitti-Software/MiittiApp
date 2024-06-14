import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/providers.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  final Ref ref;

  FirestoreService(this.ref) : _firestore = FirebaseFirestore.instance;

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    final auth = ref.read(authService);
    final user = auth.currentUser;

    if (user != null) {
      await _firestore.collection(collection).add({
        ...data,
        'userId': user.uid,
      });
    } else {
      throw Exception('User not signed in');
    }
  }
  // Other Firestore-related methods
}
