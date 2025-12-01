import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../services/customer_service.dart';

class AddCustomerScreen extends StatefulWidget {
  final String? prefilledName;

  const AddCustomerScreen({super.key, this.prefilledName});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledName != null) {
      nameCtrl.text = widget.prefilledName!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pelanggan Baru")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _field(nameCtrl, "Nama Pelanggan"),
            const SizedBox(height: 16),
            _field(phoneCtrl, "No HP", keyboard: TextInputType.phone),
            const SizedBox(height: 16),
            _field(addressCtrl, "Alamat", minLines: 3, maxLines: 5),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveCustomer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Simpan"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar("Error", "Nama pelanggan wajib diisi");
      return;
    }

    final model = CustomerModel(
      id: null,
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      address: addressCtrl.text.trim(),
    );

    final saved = await CustomerService.saveCustomer(model);

    Get.back(result: saved);
  }
}
