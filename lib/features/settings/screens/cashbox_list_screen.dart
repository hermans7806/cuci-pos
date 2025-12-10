import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cashbox_controller.dart';

class CashboxListScreen extends StatelessWidget {
  const CashboxListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CashboxController());

    return Scaffold(
      appBar: AppBar(title: const Text("Cashbox")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context, controller),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              "Cashbox Aktif",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...controller.active.map(
              (cb) => Dismissible(
                key: Key(cb.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Hapus Cashbox?"),
                      content: Text(
                        "Anda yakin ingin menghapus '${cb.name}' ?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Hapus"),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) => controller.deleteCashbox(cb.id),
                child: Card(
                  child: ListTile(
                    leading: _buildIcon(cb.name),
                    title: Text(cb.name),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "Cashbox Tidak Aktif",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...controller.inactive.map(
              (cb) => Card(
                child: ListTile(
                  leading: _buildIcon(cb.name),
                  title: Text(cb.name),
                  trailing: ElevatedButton(
                    child: const Text("Aktifkan"),
                    onPressed: () => controller.activateCashbox(cb.name),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildIcon(String name) {
    switch (name) {
      case "BRI":
        return Image.asset("lib/assets/bri_logo.png", width: 32);
      case "BCA":
        return Image.asset("lib/assets/bca_logo.png", width: 32);
      case "BNI":
        return Image.asset("lib/assets/bni_logo.png", width: 32);
      case "MANDIRI":
        return Image.asset("lib/assets/mandiri_logo.png", width: 32);
      case "QRIS":
        return Image.asset("lib/assets/qris_logo.png", width: 32);
      case "TUNAI":
        return const Icon(Icons.attach_money, size: 28);
      default:
        return const Icon(Icons.account_balance_wallet);
    }
  }

  void _showAddDialog(BuildContext context, CashboxController controller) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tambah Cashbox"),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(labelText: "Masukkan Nama Cashbox"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                controller.addCustomCashbox(name);
              }
              Get.back();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }
}
