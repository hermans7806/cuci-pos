import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  final ChangePasswordController controller = Get.put(
    ChangePasswordController(),
  );

  ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Handle Bar =====
            Center(
              child: Container(
                width: 55,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),

            // ===== Title =====
            Text(
              "Change Password",
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Create a strong new password to secure your account.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 26),

            // ===== Old Password =====
            Obx(
              () => _ModernInputField(
                label: "Current Password",
                hint: "Enter your current password",
                obscure: controller.oldObscure.value,
                controller: controller.oldPasswordController,
                onToggle: () => controller.oldObscure.toggle(),
              ),
            ),

            const SizedBox(height: 18),

            // ===== New Password =====
            Obx(
              () => _ModernInputField(
                label: "New Password",
                hint: "At least 8 characters",
                obscure: controller.newObscure.value,
                controller: controller.newPasswordController,
                onToggle: () => controller.newObscure.toggle(),
              ),
            ),

            const SizedBox(height: 18),

            // ===== Confirm New Password =====
            Obx(
              () => _ModernInputField(
                label: "Confirm Password",
                hint: "Re-enter your new password",
                obscure: controller.confirmObscure.value,
                controller: controller.confirmPasswordController,
                onToggle: () => controller.confirmObscure.toggle(),
              ),
            ),

            const SizedBox(height: 28),

            // ===== Update Button =====
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.updatePassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ModernInputField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController controller;
  final VoidCallback onToggle;

  const _ModernInputField({
    required this.label,
    required this.hint,
    required this.obscure,
    required this.controller,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: hint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
