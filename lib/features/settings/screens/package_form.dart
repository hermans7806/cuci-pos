import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/package_model.dart';
import '../controllers/package_controller.dart';

class PackageForm extends StatefulWidget {
  final PackageModel? package; // null = ADD, not null = EDIT

  const PackageForm({super.key, this.package});

  @override
  State<PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<PackageForm> {
  final controller = Get.find<PackageController>();

  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final quotaCtrl = TextEditingController();
  final validityCtrl = TextEditingController();

  String serviceType = "kiloan";
  bool accumulateValidity = false;

  @override
  void initState() {
    super.initState();

    if (widget.package != null) {
      nameCtrl.text = widget.package!.name;
      descriptionCtrl.text = widget.package!.description ?? "";
      priceCtrl.text = widget.package!.price.toString();
      quotaCtrl.text = widget.package!.quota.toString();
      validityCtrl.text = widget.package!.validityPeriod.toString();
      serviceType = widget.package!.serviceType;
      accumulateValidity = widget.package!.accumulateValidity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.package != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Paket" : "Tambah Paket")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nama Paket"),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField(
              value: serviceType,
              decoration: const InputDecoration(labelText: "Service Type"),
              items: const [
                DropdownMenuItem(value: "kiloan", child: Text("Kiloan")),
                DropdownMenuItem(value: "satuan", child: Text("Satuan")),
              ],
              onChanged: (v) => setState(() => serviceType = v as String),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Harga"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: quotaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Kuota"),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: validityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masa Berlaku (hari)",
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: descriptionCtrl,
              decoration: const InputDecoration(labelText: "Deskripsi"),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              value: accumulateValidity,
              onChanged: (v) => setState(() => accumulateValidity = v),
              title: const Text("Accumulate Validity?"),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () => _onSubmit(isEdit),
              child: Text(isEdit ? "Update Paket" : "Tambah Paket"),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit(bool isEdit) {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      Get.snackbar("Error", "Nama dan harga harus diisi");
      return;
    }

    if (isEdit) {
      final updated = widget.package!.copyWith(
        name: nameCtrl.text,
        description: descriptionCtrl.text,
        price: double.tryParse(priceCtrl.text) ?? 0,
        quota: int.tryParse(quotaCtrl.text) ?? 0,
        serviceType: serviceType,
        validityPeriod: int.tryParse(validityCtrl.text) ?? 0,
        accumulateValidity: accumulateValidity,
      );

      controller.updatePackage(updated);
    } else {
      controller.addPackage(
        name: nameCtrl.text,
        description: descriptionCtrl.text,
        price: double.tryParse(priceCtrl.text) ?? 0,
        quota: int.tryParse(quotaCtrl.text) ?? 0,
        serviceType: serviceType,
        validityPeriod: int.tryParse(validityCtrl.text) ?? 0,
        accumulateValidity: accumulateValidity,
      );
    }

    Get.back();
  }
}
