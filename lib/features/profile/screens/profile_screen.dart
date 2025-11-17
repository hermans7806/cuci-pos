import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Obx(() {
        final user = controller.user.value;

        if (controller.isLoading.value || user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 55, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                user.displayName ?? "No Name",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              // Email
              Text(
                user.email ?? "-",
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),

              const SizedBox(height: 25),
              const Divider(),

              // Items
              _item(
                icon: Icons.phone,
                title: "Phone Number",
                value: controller.phoneNumber.value.isNotEmpty
                    ? controller.phoneNumber.value
                    : "Not Set",
              ),
              const SizedBox(height: 15),

              _item(
                icon: Icons.person_outline,
                title: "Display Name",
                value: user.displayName ?? "-",
              ),
              const SizedBox(height: 15),

              _item(
                icon: Icons.verified_user,
                title: "Email Verified",
                value: user.emailVerified ? "Verified" : "Not Verified",
              ),
              const SizedBox(height: 15),

              _item(
                icon: Icons.calendar_month,
                title: "Account Created",
                value: controller.formatDate(user.metadata.creationTime),
              ),

              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Logout",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _confirmLogout(controller),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 26),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(ProfileController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Get.back()),
          ElevatedButton(
            child: const Text("Logout"),
            onPressed: () {
              Get.back();
              controller.logout();
            },
          ),
        ],
      ),
    );
  }
}
