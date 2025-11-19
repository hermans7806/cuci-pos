import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Reactive state
  final Rxn<Map<String, dynamic>> userData = Rxn<Map<String, dynamic>>();
  final Rx<File?> avatarFile = Rx<File?>(null);
  final Rxn<User> user = Rxn<User>();
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isSaving = false.obs;

  final RxString displayName = ''.obs;
  final RxString nickname = ''.obs;
  final RxString phoneNumber = ''.obs;
  final RxString photoURL = ''.obs;
  final RxString role = ''.obs;

  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes
    user.value = _auth.currentUser;
    _auth.authStateChanges().listen((u) {
      user.value = u;
      if (u != null) {
        loadProfile();
      } else {
        // clear
        displayName.value = '';
        nickname.value = '';
        phoneNumber.value = '';
        photoURL.value = '';
        role.value = '';
        userData.value = null;
        nameController.clear();
        nicknameController.clear();
        phoneController.clear();
        emailController.clear();
      }
    });

    // If there's already a signed-in user, load profile
    if (_auth.currentUser != null) {
      loadProfile();
    }
  }

  String? get uid => user.value?.uid;

  /// Load profile from Firestore (users/{uid})
  Future<void> loadProfile() async {
    final uidLocal = uid;
    if (uidLocal == null) return;
    try {
      isLoading.value = true;
      final doc = await _firestore.collection('users').doc(uidLocal).get();
      final data = doc.data();
      if (data != null) {
        userData.value = Map<String, dynamic>.from(data);
        displayName.value =
            (data['displayName'] as String?) ?? user.value?.displayName ?? '';
        nickname.value = (data['nickname'] as String?) ?? '';
        phoneNumber.value = (data['phone'] as String?) ?? '';
        photoURL.value = (data['photoURL'] as String?) ?? '';
        nameController.text = displayName.value;
        nicknameController.text = nickname.value;
        phoneController.text = phoneNumber.value;
        emailController.text = user.value?.email ?? '';
        // role can be stored as map or list; attempt to read gracefully
        final roleData = data['role'];
        if (roleData is Map && roleData.isNotEmpty) {
          role.value = roleData.keys.first;
        } else if (roleData is List && roleData.isNotEmpty) {
          role.value = roleData.first.toString();
        } else {
          role.value = '';
        }
      } else {
        // fallback to auth profile
        displayName.value = user.value?.displayName ?? '';
        nickname.value = '';
        phoneNumber.value = '';
        photoURL.value = user.value?.photoURL ?? '';
        role.value = '';
        nameController.text = displayName.value;
        nicknameController.text = nickname.value;
        phoneController.text = phoneNumber.value;
        emailController.text = user.value?.email ?? '';
      }
    } catch (e) {
      // ignore or log
      debugPrint('Profile load error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAvatar() async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Pick from Gallery"),
                onTap: () async {
                  Get.back();
                  await pickAvatarGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () async {
                  Get.back();
                  await pickAvatarCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Photo"),
                onTap: () async {
                  Get.back();
                  await deleteAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Update profile in Firestore only (email not changed here)
  Future<void> saveProfile() async {
    if (isSaving.value) return;

    final uidLocal = uid;
    if (uidLocal == null) throw Exception('Not signed in');

    try {
      isLoading.value = true;

      await _firestore.collection('users').doc(uidLocal).set({
        'displayName': nameController.text.trim(),
        'nickname': nicknameController.text
            .trim(), // keep existing nickname if you want
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      displayName.value = nameController.text.trim();
      userData.value = (userData.value ?? {})
        ..['displayName'] = displayName.value;

      Get.snackbar(
        'Success',
        'Profile berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('saveProfile error: $e');
      Get.snackbar(
        'Error',
        'Gagal menyimpan profil: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Pick from gallery
  Future<void> pickAvatarGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    await _uploadAvatar(File(picked.path));
  }

  /// Pick from camera
  Future<void> pickAvatarCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return;
    await _uploadAvatar(File(picked.path));
  }

  /// Upload avatar to storage users/{uid}/profile.jpg, then update Firestore user doc
  @override
  Future<void> _uploadAvatar(File file) async {
    final uidLocal = uid;
    if (uidLocal == null) throw Exception('Not signed in');

    final storageRef = _storage
        .ref()
        .child('users')
        .child(uidLocal)
        .child('profile.jpg');

    try {
      isUploading.value = true;
      avatarFile.value = file; // preview immediately

      await storageRef.putFile(file);
      final url = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(uidLocal).set({
        'photoURL': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      photoURL.value = url;
      userData.value = (userData.value ?? {})..['photoURL'] = url;

      Get.snackbar('Success', 'Foto profil berhasil diunggah');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengunggah foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isUploading.value = false;
    }
  }

  /// Delete avatar (storage + delete field in Firestore)
  Future<void> deleteAvatar() async {
    final uidLocal = uid;
    if (uidLocal == null) throw Exception('Not signed in');
    final storageRef = _storage
        .ref()
        .child('users')
        .child(uidLocal)
        .child('profile.jpg');

    try {
      isUploading.value = true;
      // try delete; if not found ignore
      try {
        await storageRef.delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }

      // delete Firestore field
      await _firestore.collection('users').doc(uidLocal).update({
        'photoURL': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      photoURL.value = '';
      userData.value = (userData.value ?? {})..remove('photoURL');
      avatarFile.value = null;

      Get.snackbar(
        'Success',
        'Foto profil dihapus',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Delete avatar error: $e');
      Get.snackbar(
        'Error',
        'Gagal menghapus foto: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isUploading.value = false;
    }
  }

  /// Change password with re-authentication
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final u = _auth.currentUser;
    if (u == null || u.email == null) throw Exception('User not found');

    try {
      isLoading.value = true;
      final cred = EmailAuthProvider.credential(
        email: u.email!,
        password: currentPassword,
      );
      await u.reauthenticateWithCredential(cred);
      await u.updatePassword(newPassword);

      // store change time in Firestore
      await _firestore.collection('users').doc(u.uid).update({
        'passwordChangedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        'Success',
        'Password berhasil diganti',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('changePassword error: ${e.code} - ${e.message}');
      // translate common codes
      String msg = e.message ?? 'Gagal mengganti password';
      if (e.code == 'wrong-password') msg = 'Password saat ini salah';
      if (e.code == 'weak-password') msg = 'Password baru terlalu lemah';
      throw Exception(msg);
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      // navigate to login route (app uses Get)
      Get.offAllNamed('/login');
    }
  }

  /// Helper for formatting dates (optional)
  String formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
