// FILE: create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/promo_model.dart';
import '../../../data/models/selected_service_model.dart';
import '../controllers/order_controller.dart';
import './add_customer_screen.dart';
import 'promo_picker_sheet.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final controller = Get.put(OrderController());
  final notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.customerCtrl.addListener(() {
      final text = controller.customerCtrl.text;
      controller.customerName.value = text;
      controller.searchCustomers(text);
    });
  }

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _openPromoPicker() async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getString('activeBranchId') ?? '';

    final result = await showModalBottomSheet<PromoModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PromoPickerSheet(branchId: branchId),
    );

    if (result != null) controller.setPromo(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buat Pesanan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _customerField(),
            const SizedBox(height: 12),
            _detailSection(),
            const SizedBox(height: 12),
            _notesSection(),
            const SizedBox(height: 12),
            _promoSection(),
            const SizedBox(height: 12),
            _billingSection(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final total = controller.totalAfterPromo;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TOTAL TAGIHAN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Tagihan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Rp ${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // BUTTON
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Buat Transaksi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // -------------------- CUSTOMER FIELD --------------------
  Widget _customerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller.customerCtrl,
          decoration: InputDecoration(
            labelText: "Nama Pelanggan",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.contacts),
              onPressed: _openCustomerDialog,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final results = controller.searchResults;
          final searching = controller.isSearching.value;

          if (!searching && results.isEmpty) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searching ? 'Searching...' : 'Pelanggan ditemukan',
                          style: TextStyle(
                            color: searching ? Colors.blue : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (searching)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                if (!searching && results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Tidak ada hasil. Tekan tombol + untuk menambah pelanggan baru.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                if (results.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (_, i) {
                        final item = results[i];
                        return ListTile(
                          onTap: () {
                            controller.customerCtrl.text =
                                "${item.name} - ${item.phone}";
                            controller.customerName.value = item.name;
                            controller.customerPhone.value = item.phone;
                            controller.customerId.value = item.id;
                            controller.searchResults.clear();
                            FocusScope.of(context).unfocus();
                          },
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          title: _highlightMatch(
                            item.name,
                            controller.customerCtrl.text,
                          ),
                          subtitle: Text(item.phone),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text("Tambah Pelanggan Baru"),
                        onPressed: () {
                          Get.to(
                            () => AddCustomerScreen(
                              prefilledName: controller.customerCtrl.text,
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.phone_android),
                        label: const Text("Ambil dari Kontak HP"),
                        onPressed: controller.pickFromPhoneContacts,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // -------------------- DETAIL SECTION --------------------
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
          if (controller.selectedServices.isEmpty)
            return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: controller.selectedServices.map((s) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Service name + price
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

                      // Qty Editor – now safe
                      IntrinsicWidth(child: qtyEditor(s)),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
        TextButton(
          onPressed: controller.openAddServiceBottomSheet,
          child: const Text("+ Layanan", style: TextStyle(color: Colors.blue)),
        ),
        const SizedBox(height: 8),

        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gunakan Parfum",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Switch(
                value: controller.perfumeEnabled.value,
                onChanged: controller.togglePerfume,
              ),
            ],
          );
        }),
      ],
    );
  }

  // -------------------- NOTES --------------------
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

  // -------------------- PROMO --------------------
  Widget _promoSection() {
    return Obx(() {
      final promo = controller.selectedPromo.value;

      if (promo == null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.percent_outlined, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Pilih Promo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: _openPromoPicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                ),
                child: const Text(
                  "Pilih Promo",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }

      final label = promo.type == 'percentage'
          ? "${promo.discountRate}%"
          : "Rp ${promo.discountRate}";

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.percent_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(label),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _openPromoPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text(
                "Ganti Promo",
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: controller.clearPromo,
            ),
          ],
        ),
      );
    });
  }

  // -------------------- BILLING --------------------
  Widget _billingSection() {
    return Obx(() {
      return Card(
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
                    "Rp ${controller.totalBeforePromo.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (controller.selectedPromo.value != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Diskon"),
                    Text(
                      "- Rp ${controller.discountAmount.toStringAsFixed(0)}",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Setelah Diskon"),
                    Text(
                      "Rp ${controller.totalAfterPromo.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // -------------------- QTY EDITOR --------------------
  Widget qtyEditor(SelectedService s) {
    final controller = TextEditingController(text: s.qty.toString());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => Get.find<OrderController>().decreaseQty(s),
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            onChanged: (v) {
              final num = double.tryParse(v.replaceAll(',', '.'));
              if (num != null) Get.find<OrderController>().updateQty(s, num);
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

  // -------------------- CUSTOMER DIALOG --------------------
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

  // -------------------- TEXT HIGHLIGHT --------------------
  Widget _highlightMatch(String text, String query) {
    if (query.trim().length < 1) return Text(text);

    final q = query.toLowerCase();
    final lower = text.toLowerCase();

    final matches = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        matches.add(TextSpan(text: text.substring(start, idx)));
      }
      matches.add(
        TextSpan(
          text: text.substring(idx, idx + q.length),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      start = idx + q.length;
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: matches,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
