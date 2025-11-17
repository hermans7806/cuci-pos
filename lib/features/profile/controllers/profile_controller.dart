import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Reactive current user (keeps UI synced with Firebase updates)
  final Rxn<User> user = Rxn<User>();

  /// Reactive fields
  RxString role = "".obs;
  RxString nickname = "".obs;
  RxString phoneNumber = "".obs;

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    /// Sync firebase user state
    user.value = _auth.currentUser;

    /// Listen for changes to auth user
    _auth.userChanges().listen((u) {
      user.value = u;
      if (u != null) {
        loadProfile();
      }
    });

    if (_auth.currentUser != null) {
      loadProfile();
    }
  }

  /// Loads Firestore profile fields (nickname, phone, role)
  Future<void> loadProfile() async {
    final u = user.value;
    if (u == null) return;

    isLoading.value = true;

    final doc = await _firestore.collection('users').doc(u.uid).get();
    final data = doc.data() ?? {};

    nickname.value = data['nickname'] ?? u.displayName ?? "";
    phoneNumber.value = data['phone'] ?? "";
    _extractRole(data['role']);

    isLoading.value = false;
  }

  void _extractRole(dynamic roleData) {
    if (roleData is Map && roleData.isNotEmpty) {
      role.value = roleData.keys.first;
    } else {
      role.value = "";
    }
  }

  /// Upload new avatar
  Future<String?> uploadAvatar(File imageFile) async {
    final u = user.value;
    if (u == null) return null;

    final ref = _storage.ref().child('users/${u.uid}/profile.jpg');

    await ref.putFile(imageFile);
    final url = await ref.getDownloadURL();

    await _firestore.collection('users').doc(u.uid).set({
      'photoURL': url,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return url;
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    final u = user.value;
    if (u == null) return;

    final ref = _storage.ref().child('users/${u.uid}/profile.jpg');

    try {
      await ref.delete();
    } catch (_) {}

    await _firestore.collection('users').doc(u.uid).update({
      'photoURL': FieldValue.delete(),
    });
  }

  /// Update profile data
  Future<void> updateProfile({
    required String name,
    required String nickname,
    required String phone,
  }) async {
    final u = user.value;
    if (u == null) return;

    await _firestore.collection('users').doc(u.uid).set({
      'displayName': name,
      'nickname': nickname,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Password change
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final u = user.value;
    if (u == null || u.email == null) {
      throw Exception("User tidak ditemukan");
    }

    final cred = EmailAuthProvider.credential(
      email: u.email!,
      password: currentPassword,
    );

    await u.reauthenticateWithCredential(cred);
    await u.updatePassword(newPassword);
  }

  /// Format date to string
  String formatDate(DateTime? time) {
    if (time == null) return "-";
    return "${time.day}/${time.month}/${time.year}";
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
