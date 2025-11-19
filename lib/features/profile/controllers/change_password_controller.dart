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
      Get.snackbar(
        "Missing fields",
        "Please fill all fields.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPass != confirm) {
      Get.snackbar(
        "Password mismatch",
        "New passwords do not match.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!validatePassword(newPass)) {
      Get.snackbar(
        "Weak password",
        "Password must contain:\n- 1 capital letter\n- 1 number\n- 1 special character\n- At least 8 characters",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final user = auth.currentUser;

      if (user == null) {
        Get.snackbar("Error", "User not logged in.");
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

      Get.snackbar(
        "Success",
        "Your password has been updated.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Something went wrong.";

      if (e.code == "wrong-password")
        msg = "Your current password is incorrect.";
      if (e.code == "weak-password") msg = "Your new password is too weak.";
      if (e.code == "requires-recent-login") {
        msg = "Please login again to continue.";
      }

      Get.snackbar("Error", msg, snackPosition: SnackPosition.BOTTOM);
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
