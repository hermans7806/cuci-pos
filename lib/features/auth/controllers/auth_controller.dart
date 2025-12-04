import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  /// 🔹 Sign in with Email & Password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true; // ✅ Success
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(context, e);
      return false; // ❌ Failed
    } catch (e) {
      _showError(context, "Unexpected error: $e");
      return false;
    }
  }

  /// 🔹 Sign in with Google
  Future<bool> loginWithGoogle(BuildContext context) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // cancelled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      print(FirebaseAuth.instance.currentUser?.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(context, e);
      return false;
    } catch (e) {
      _showError(context, "Google login failed: $e");
      return false;
    }
  }

  /// 🔹 Register new user
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(context, e);
      return false;
    } catch (e) {
      _showError(context, "Unexpected error: $e");
      return false;
    }
  }

  /// 🔹 Send password reset email
  Future<bool> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(context, e);
      return false;
    } catch (e) {
      _showError(context, "Unexpected error: $e");
      return false;
    }
  }

  /// 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeBranchId');
    await prefs.remove('activeBranchName');
  }

  /// 🔹 Handle Firebase-specific errors
  void _handleFirebaseError(BuildContext context, FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with that email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered.';
        break;
      case 'invalid-email':
        message = 'Invalid email format.';
        break;
      case 'weak-password':
        message = 'Password too weak. Must be at least 8 characters.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      default:
        message = e.message ?? 'Authentication failed.';
    }
    _showError(context, message);
  }

  /// 🔹 Show SnackBar error
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
