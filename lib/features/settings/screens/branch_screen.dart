import 'package:cuci_pos/data/models/branch_model.dart';
import 'package:cuci_pos/features/settings/controllers/branch_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';

class BranchScreen extends StatelessWidget {
  final BranchController controller = Get.put(BranchController());

  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  BranchScreen({super.key});

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
      appBar: AppBar(title: const Text("Branch Management")),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add new branch
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Add New Branch",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Branch Name",
                      ),
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: "Phone"),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        controller.addBranch(
                          BranchModel(
                            id: '', // ignored because controller auto-generates ID
                            name: nameController.text,
                            address: addressController.text,
                            phone: phoneController.text,
                          ),
                        );

                        nameController.clear();
                        addressController.clear();
                        phoneController.clear();
                      },
                      child: const Text("Add Branch"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List branches
            ...controller.branches.map((b) {
              return Card(
                child: ListTile(
                  title: Text(b.name),
                  subtitle: Text("${b.address}\n${b.phone}"),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.deleteBranch(b.id),
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
