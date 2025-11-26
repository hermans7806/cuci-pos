import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    return Obx(() {
      if (profileCtrl.role.value != 'owner') {
        Future.microtask(
          () => Navigator.pushReplacementNamed(context, '/dashboard'),
        );
        return const SizedBox.shrink();
      }

      return Scaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: ListView(
          children: [
            ListTile(
              title: const Text("Branch Management"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/branch'),
            ),
            ListTile(
              title: const Text("Role Management"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/role'),
            ),
            ListTile(
              title: const Text("Staff/User Management"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/staff'),
            ),
            ListTile(
              title: const Text("Product / Service Management"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/settings/product'),
            ),
          ],
        ),
      );
    });
  }
}
