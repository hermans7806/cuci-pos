import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());
  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() {
        final user = controller.userData.value;

        if (user == null) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ===== AVATAR SECTION =====
            Center(
              child: Stack(
                children: [
                  Obx(() {
                    final avatar = controller.avatarFile.value;

                    return CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: avatar != null
                          ? FileImage(avatar)
                          : (user['avatar'] != null
                                    ? NetworkImage(user['avatar'])
                                    : null)
                                as ImageProvider?,
                      child: avatar == null && user['avatar'] == null
                          ? Icon(Icons.person, size: 55)
                          : null,
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => controller.pickAvatar(),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ===== DISPLAY NAME =====
            Text("Nama Lengkap", style: labelStyle(context)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.nameController,
              decoration: inputDecoration("Masukkan Nama Lengkap"),
            ),
            const SizedBox(height: 10),
            Text("Nama Panggilan ", style: labelStyle(context)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.nicknameController,
              decoration: inputDecoration("Masukkan Nama Panggilan"),
            ),
            const SizedBox(height: 10),
            Text("Nomor HP ", style: labelStyle(context)),
            const SizedBox(height: 6),
            TextField(
              controller: controller.phoneController,
              decoration: inputDecoration("Masukkan Nomor HP"),
            ),
            const SizedBox(height: 10),

            // ===== EMAIL (READ ONLY) =====
            Text("Email", style: labelStyle(context)),
            const SizedBox(height: 6),
            TextField(
              enabled: false,
              controller: controller.emailController,
              decoration: inputDecoration(null).copyWith(
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ===== SAVE BUTTON =====
            Obx(
              () => ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: controller.isSaving.value
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveProfile,
                style: mainButtonStyle(),
              ),
            ),

            const SizedBox(height: 10),

            // ===== CHANGE PASSWORD =====
            ElevatedButton.icon(
              icon: const Icon(Icons.password_sharp),
              label: const Text("Change Password"),
              onPressed: () {
                Get.bottomSheet(
                  ChangePasswordScreen(),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                );
              },
              style: secondaryButtonStyle(),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.grey, indent: 50, endIndent: 50),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text("Log out"),
              onPressed: () {
                controller.logout();
              },
            ),
          ],
        );
      }),
    );
  }

  // --- UI Helpers ---
  InputDecoration inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  TextStyle labelStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  }

  ButtonStyle mainButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle secondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
