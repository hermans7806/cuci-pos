import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  User get user => _auth.currentUser!;

  /// Load user profile data from Firestore
  Future<Map<String, dynamic>?> loadProfile() async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  /// Upload new avatar and update Firestore
  Future<String?> uploadAvatar(File imageFile) async {
    final ref = _storage
        .ref()
        .child('users')
        .child('${user.uid}')
        .child('profile.jpg');
    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).set({
      'photoURL': url,
      'displayName': user.displayName ?? '',
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return url;
  }

  /// Delete current avatar
  Future<void> deleteAvatar() async {
    final ref = _storage
        .ref()
        .child('users')
        .child('${user.uid}')
        .child('profile.jpg');
    await ref.delete();
    await _firestore.collection('users').doc(user.uid).update({
      'photoURL': FieldValue.delete(),
    });
  }
}
