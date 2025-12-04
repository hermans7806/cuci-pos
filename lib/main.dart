import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'features/auth/screens/branch_selection_screen.dart';
import 'features/profile/controllers/profile_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Register ProfileController globally if not registered
  if (!Get.isRegistered<ProfileController>()) {
    Get.put(ProfileController(), permanent: true);
  }

  // 🔹 Listen to auth changes and navigate automatically
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    final profileCtrl = Get.find<ProfileController>();

    if (user != null) {
      // Load profile when logged in
      await profileCtrl.loadProfile();
      final branches =
          profileCtrl.branches; // assume you have branches in profile
      final prefs = await SharedPreferences.getInstance();
      final savedBranch = prefs.getString('activeBranchId');

      if (savedBranch != null && savedBranch.isNotEmpty) {
        // Already checked in previously
        Get.offAllNamed('/dashboard');
        return;
      }

      // Need branch selection
      Get.offAll(() => BranchSelectionScreen(userBranches: branches));
    } else {
      // Navigate to login if logged out
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    }
  });

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fastclean Laundry POS',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/login',
    );
  }
}
