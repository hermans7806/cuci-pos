import 'package:cuci_pos/features/auth/screens/login_screen.dart';
import 'package:cuci_pos/features/dashboard/screens/dashboard_screen.dart';
import 'package:cuci_pos/features/profile/controllers/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/router/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 Listen to login/logout globally (recommended)
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController(), permanent: true);
      }

      final ctrl = Get.find<ProfileController>();
      await ctrl.loadProfile();

      if (Get.currentRoute != '/dashboard') {
        Get.offAll(() => const DashboardScreen());
      }
    } else {
      if (Get.currentRoute != '/login') {
        Get.offAll(() => const LoginScreen());
      }
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Fastclean Laundry POS',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generateRoute,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
