import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;

  final oldObscure = true.obs;
  final newObscure = true.obs;
  final confirmObscure = true.obs;

  final auth = FirebaseAuth.instance;

  // Strong password validator
  bool validatePassword(String value) {
    // At least 8 chars, 1 capital, 1 number, 1 special
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(value);
  }

  Future<void> updatePassword() async {
    final old = oldPasswordController.text.trim();
    final newPass = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (old.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      TopNotification.show(
        title: 'Missing Fields',
        message: 'Mohon isi semua fields',
        success: false,
      );
      return;
    }

    if (newPass != confirm) {
      TopNotification.show(
        title: 'Password mismatch',
        message: 'Password baru tidak sama',
        success: false,
      );
      return;
    }

    if (!validatePassword(newPass)) {
      TopNotification.show(
        title: 'Weak Password',
        message:
            'Password harus mempunyai setidaknya:\n- 1 huruf kapital\n- 1 angka\n- 1 karakter spesial seperti @,&,%,dsb.\n- minimal 8 karakter.',
        success: false,
      );
      return;
    }

    try {
      isLoading.value = true;

      final user = auth.currentUser;

      if (user == null) {
        TopNotification.show(
          title: 'Error',
          message: 'User belum login!',
          success: false,
        );
        return;
      }

      // Reauthenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: old,
      );

      await user.reauthenticateWithCredential(cred);

      // Update password
      await user.updatePassword(newPass);

      Get.back(); // Close modal

      TopNotification.show(
        title: 'Sukses',
        message: 'Password berhasil diganti.',
        success: true,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Something went wrong.";

      if (e.code == "wrong-password")
        msg = "Your current password is incorrect.";
      if (e.code == "weak-password") msg = "Your new password is too weak.";
      if (e.code == "requires-recent-login") {
        msg = "Please login again to continue.";
      }

      TopNotification.show(title: 'Error', message: msg, success: false);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
