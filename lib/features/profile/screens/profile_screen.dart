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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 1,
      ),
      body: Obx(() {
        final user = controller.userData.value;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 350),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ===== AVATAR SECTION =====
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      final avatar = controller.avatarFile.value;

                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: avatar != null
                            ? FileImage(avatar)
                            : (user['photoURL'] != null
                                      ? NetworkImage(user['photoURL'])
                                      : null)
                                  as ImageProvider?,
                        child: avatar == null && user['photoURL'] == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () => controller.pickAvatar(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
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
              const SizedBox(height: 25),

              // ===== FORM CARD =====
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel("Nama Lengkap"),
                      TextField(
                        controller: controller.nameController,
                        decoration: inputDecoration("Masukkan Nama Lengkap"),
                      ),
                      const SizedBox(height: 15),

                      buildLabel("Nama Panggilan"),
                      TextField(
                        controller: controller.nicknameController,
                        decoration: inputDecoration("Masukkan Nama Panggilan"),
                      ),
                      const SizedBox(height: 15),

                      buildLabel("Nomor HP"),
                      TextField(
                        controller: controller.phoneController,
                        decoration: inputDecoration("Masukkan Nomor HP"),
                      ),
                      const SizedBox(height: 15),

                      buildLabel("Email (read-only)"),
                      TextField(
                        enabled: false,
                        controller: controller.emailController,
                        decoration: disabledInputDecoration(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ===== SAVE BUTTON =====
              Obx(
                () => ElevatedButton(
                  style: mainButtonStyle(),
                  onPressed: controller.isSaving.value
                      ? null
                      : () async {
                          await controller.saveProfile();
                        },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.save),
                              SizedBox(width: 6),
                              Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== CHANGE PASSWORD =====
              ElevatedButton.icon(
                style: secondaryButtonStyle(),
                icon: const Icon(Icons.lock_reset),
                label: const Text("Change Password"),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // allows full height scroll
                    backgroundColor: Colors.transparent,
                    enableDrag: true, // drag-to-dismiss enabled
                    builder: (_) => ChangePasswordScreen(),
                  );
                },
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade400),
              const SizedBox(height: 20),

              // ===== LOGOUT =====
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Log Out"),
                onPressed: () => controller.logout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ------------------------- UI HELPERS -------------------------

  Widget buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
    ),
  );

  InputDecoration inputDecoration(String hint) {
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

  InputDecoration disabledInputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  ButtonStyle mainButtonStyle() {
    return ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  ButtonStyle secondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
