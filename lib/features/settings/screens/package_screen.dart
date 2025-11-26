import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';
import '../controllers/package_controller.dart';

class PackageScreen extends StatelessWidget {
  PackageScreen({super.key});

  final PackageController controller = Get.put(PackageController());

  // Form controllers
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final quotaCtrl = TextEditingController();
  final validityCtrl = TextEditingController();

  String serviceType = "kiloan";
  bool accumulateValidity = false;

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    // OWNER-ONLY access guard
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Layanan Paket")),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // -------------------------------
            // ADD NEW PACKAGE
            // -------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add New Package",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nama Paket",
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      value: serviceType,
                      decoration: const InputDecoration(
                        labelText: "Service Type",
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "kiloan",
                          child: Text("Kiloan"),
                        ),
                        DropdownMenuItem(
                          value: "satuan",
                          child: Text("Satuan"),
                        ),
                      ],
                      onChanged: (v) => serviceType = v as String,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: "Harga"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: quotaCtrl,
                      decoration: const InputDecoration(labelText: "Kuota"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: validityCtrl,
                      decoration: const InputDecoration(
                        labelText: "Masa Berlaku (hari)",
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: "Deskripsi"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      value: accumulateValidity,
                      onChanged: (v) => accumulateValidity = v,
                      title: const Text("Accumulate Validity?"),
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addPackage,
                      child: const Text("Add Package"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------
            // LIST OF PACKAGES
            // -------------------------------
            if (controller.packages.isEmpty)
              const Center(
                child: Text("Belum ada paket.", style: TextStyle(fontSize: 14)),
              ),

            ...controller.packages.map((p) {
              return Card(
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    "Rp ${p.price} • ${p.serviceType}\n"
                    "Kuota: ${p.quota} | Berlaku: ${p.validityPeriod} hari",
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => controller.deletePackage(p.id),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      }),
    );
  }

  // -------------------------------
  // ADD NEW PACKAGE HANDLER
  // -------------------------------
  void _addPackage() {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      Get.snackbar("Error", "Nama dan harga wajib diisi");
      return;
    }

    controller.addPackage(
      name: nameCtrl.text,
      serviceType: serviceType,
      price: double.tryParse(priceCtrl.text) ?? 0,
      quota: int.tryParse(quotaCtrl.text) ?? 0,
      description: descCtrl.text,
      validityPeriod: int.tryParse(validityCtrl.text) ?? 0,
      accumulateValidity: accumulateValidity,
    );

    nameCtrl.clear();
    descCtrl.clear();
    priceCtrl.clear();
    quotaCtrl.clear();
    validityCtrl.clear();
    serviceType = "kiloan";
    accumulateValidity = false;
  }
}
