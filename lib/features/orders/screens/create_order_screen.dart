import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/selected_service_model.dart';
import '../controllers/order_controller.dart';
import './add_customer_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final controller = Get.put(OrderController());

  final notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Pesanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _customerField(),
            const SizedBox(height: 24),
            _detailSection(),
            const SizedBox(height: 24),
            _notesSection(),
            const SizedBox(height: 24),
            _billingSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: controller.isValidOrder ? controller.submitOrder : null,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Text("Buat Transaksi"),
          ),
        ),
      ),
    );
  }

  // -------------------- Nama Pelanggan Field --------------------
  Widget _customerField() {
    return TextField(
      controller: controller.customerCtrl,
      decoration: InputDecoration(
        labelText: "Nama Pelanggan",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.contacts),
          onPressed: _openCustomerDialog,
        ),
      ),
      onChanged: (v) {
        controller.customerName.value = v;
      },
    );
  }

  // -------------------- Detail Pesanan --------------------
  Widget _detailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Pesanan",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Obx(() {
          if (controller.selectedServices.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...controller.selectedServices.map((s) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text("Rp ${s.price} • ${s.duration} hari"),
                            ],
                          ),
                        ),

                        qtyEditor(s),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
            ],
          );
        }),
        TextButton(
          onPressed: controller.openAddServiceBottomSheet,
          child: const Text("+ Layanan", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  // -------------------- Notes --------------------
  Widget _notesSection() {
    return TextField(
      controller: notesCtrl,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: "Informasi Tambahan",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (v) => controller.notes.value = v,
    );
  }

  // -------------------- Billing --------------------
  Widget _billingSection() {
    return Obx(
      () => Card(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informasi Tagihan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Harga"),
                  Text(
                    "Rp ${controller.totalPrice.value}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------- QTY Editor ----------------------
  Widget qtyEditor(SelectedService s) {
    final controller = TextEditingController(text: s.qty.toString());

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => Get.find<OrderController>().decreaseQty(s),
        ),

        SizedBox(
          width: 55,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (v) {
              final num = double.tryParse(v.replaceAll(',', '.'));
              if (num != null) {
                Get.find<OrderController>().updateQty(s, num);
              }
            },
            onSubmitted: (v) {
              final num = double.tryParse(v.replaceAll(',', '.')) ?? 1;
              Get.find<OrderController>().updateQty(s, num);
            },
          ),
        ),

        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => Get.find<OrderController>().increaseQty(s),
        ),
      ],
    );
  }

  // -------------------- Dialog for Address Book --------------------
  void _openCustomerDialog() {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          SimpleDialogOption(
            child: const Text("Cari Pelanggan"),
            onPressed: () {
              Navigator.pop(context);
              controller.pickExistingCustomer();
            },
          ),
          SimpleDialogOption(
            child: const Text("Tambah Pelanggan Baru"),
            onPressed: () {
              Navigator.pop(context);
              Get.to(
                () => AddCustomerScreen(
                  prefilledName: controller.customerName.value,
                ),
              );
            },
          ),
          SimpleDialogOption(
            child: const Text("Ambil dari Kontak HP"),
            onPressed: () {
              Navigator.pop(context);
              controller.pickFromPhoneContacts();
            },
          ),
        ],
      ),
    );
  }
}
