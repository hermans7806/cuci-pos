import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';
import '../controllers/staff_controller.dart';

class StaffScreen extends StatelessWidget {
  final StaffController controller = Get.put(StaffController());

  final nameCtrl = TextEditingController();
  final nickCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  /// selected role now a map, not string
  final selectedRole = Rxn<Map<String, dynamic>>();

  /// selected branches list of IDs
  final selectedBranches = <String>[].obs;

  StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();

    if (profile.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Management")),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Add Staff",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: nickCtrl,
                      decoration: const InputDecoration(labelText: "Nickname"),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: "Phone"),
                    ),
                    TextField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                    ),

                    // Role dropdown (Map)
                    DropdownButtonFormField<Map<String, dynamic>>(
                      value: selectedRole.value,
                      items: controller.roles.map((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r["name"]),
                        );
                      }).toList(),
                      onChanged: (v) => selectedRole.value = v,
                      decoration: const InputDecoration(labelText: "Role"),
                    ),

                    // Branch multi-select
                    Obx(() {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const Text(
                            "Branches",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...controller.branches.map((b) {
                            return CheckboxListTile(
                              title: Text(b["name"]),
                              value: selectedBranches.contains(b["id"]),
                              onChanged: (v) {
                                if (v == true) {
                                  selectedBranches.add(b["id"]);
                                } else {
                                  selectedBranches.remove(b["id"]);
                                }
                              },
                            );
                          }),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        controller.addStaff(
                          displayName: nameCtrl.text,
                          nickname: nickCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          role: selectedRole.value ?? {}, // <--- FIXED
                          branches: selectedBranches.toList(),
                          password: passwordCtrl.text,
                        );

                        nameCtrl.clear();
                        nickCtrl.clear();
                        emailCtrl.clear();
                        phoneCtrl.clear();
                        passwordCtrl.clear();
                        selectedRole.value = null;
                        selectedBranches.clear();
                      },
                      child: const Text("Add Staff"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Staff List
            ...controller.staffs.map((s) {
              return Card(
                child: ListTile(
                  title: Text("${s.displayName} (${s.nickname})"),
                  subtitle: Text(
                    "${s.email}\n"
                    "${s.phone}\n"
                    "Role: ${s.role.values.join(', ')}\n"
                    "Branches: ${s.branches?.join(', ') ?? '-'}",
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.deleteStaff(s.id),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }
}
