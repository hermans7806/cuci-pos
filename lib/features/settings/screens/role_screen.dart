import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/role_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/role_controller.dart';

class RoleScreen extends StatelessWidget {
  final RoleController controller = Get.put(RoleController());

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final descController = TextEditingController();

  RoleScreen({super.key});

  void clearFields() {
    idController.clear();
    nameController.clear();
    descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Role")),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add role section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add New Role",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: "ID (e.g. manager)",
                      ),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        controller.createRole(
                          RoleModel(
                            id: idController.text.trim(),
                            name: nameController.text.trim(),
                            description: descController.text.trim(),
                          ),
                        );
                        clearFields();
                      },
                      child: const Text("Add Role"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role list
            ...controller.roles.map(
              (role) => Card(
                child: ListTile(
                  title: Text(role.name),
                  subtitle: Text(role.description ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.deleteRole(role.id),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
