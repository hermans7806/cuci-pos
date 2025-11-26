import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/service_category_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/service_controller.dart';
import 'service_item_bottomsheet.dart';

class AddServiceCategoryScreen extends StatelessWidget {
  final ServiceCategoryModel? editingCategory;
  AddServiceCategoryScreen({super.key, this.editingCategory}) {
    // Pre-populate fields if editing
    if (editingCategory != null) {
      categoryCtrl.text = editingCategory!.categoryName;

      cuci.value = editingCategory!.processTypes.contains("cuci");
      kering.value = editingCategory!.processTypes.contains("kering");
      setrika.value = editingCategory!.processTypes.contains("setrika");

      // load items into tempItems
      controller.tempItems.assignAll(editingCategory!.items);
    } else {
      controller.tempItems.clear();
    }
  }

  final ServiceController controller = Get.put(ServiceController());

  // form controllers
  final TextEditingController categoryCtrl = TextEditingController();

  // checkboxes for process types
  final RxBool cuci = false.obs;
  final RxBool kering = false.obs;
  final RxBool setrika = false.obs;

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    // Preload data ONLY once when editing
    if (editingCategory != null && controller.tempItems.isEmpty) {
      // Fill category name
      categoryCtrl.text = editingCategory!.categoryName;

      // Fill checkboxes
      cuci.value = editingCategory!.processTypes.contains("cuci");
      kering.value = editingCategory!.processTypes.contains("kering");
      setrika.value = editingCategory!.processTypes.contains("setrika");

      // Load items into temp buffer
      controller.tempItems.assignAll(editingCategory!.items);
    }

    // Owner-only guard
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editingCategory == null
              ? "Tambah Kategori Layanan"
              : "Edit Kategori Layanan",
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddItemSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Kategori',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sepatu',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Proses Produksi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Checkboxes
                    Row(
                      children: [
                        // Cuci
                        Obx(
                          () => Row(
                            children: [
                              Checkbox(
                                value: cuci.value,
                                onChanged: (v) => cuci.value = v ?? false,
                              ),
                              const Text("Cuci"),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),

                        // Kering
                        Obx(
                          () => Row(
                            children: [
                              Checkbox(
                                value: kering.value,
                                onChanged: (v) => kering.value = v ?? false,
                              ),
                              const Text("Kering"),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),

                        // Setrika
                        Obx(
                          () => Row(
                            children: [
                              Checkbox(
                                value: setrika.value,
                                onChanged: (v) => setrika.value = v ?? false,
                              ),
                              const Text("Setrika"),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Tambah Layanan'),
                      onPressed: () => _openAddItemSheet(context),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Layanan (In-Memory)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // List of temp items
                    if (controller.tempItems.isEmpty)
                      const Text(
                        'Belum ada layanan. Tekan Tambah Layanan untuk membuat item.',
                      )
                    else
                      Column(
                        children: controller.tempItems.map((it) {
                          return Card(
                            child: ListTile(
                              title: Text(it.name),
                              subtitle: Text(
                                'Rp ${it.price} • ${it.durationHours} jam • ${it.unit}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    controller.removeTempItem(it.id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 18),

                    // Save button (bulk save)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _onSaveCategory(context),
                        child: const Text('Save Category & Items'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _openAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ServiceItemBottomSheet(),
    );
  }

  Future<void> _onSaveCategory(BuildContext context) async {
    final name = categoryCtrl.text.trim();
    final selectedTypes = <String>[];
    if (cuci.value) selectedTypes.add('cuci');
    if (kering.value) selectedTypes.add('kering');
    if (setrika.value) selectedTypes.add('setrika');

    if (name.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Nama Kategori Wajib Diisi",
        success: true,
      );
      return;
    }
    if (selectedTypes.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Pilih Setidaknya 1 Proses Produksi",
        success: true,
      );
      return;
    }
    if (controller.tempItems.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Tambahkan setidaknya 1 Layanan Sebelum Menyimpan",
        success: true,
      );
      return;
    }

    try {
      if (editingCategory == null) {
        await controller.saveCategoryWithItems(
          categoryName: name,
          types: selectedTypes,
        );
      } else {
        await controller.updateCategoryWithItems(
          categoryId: editingCategory!.id,
          categoryName: name,
          types: selectedTypes,
          items: controller.tempItems,
        );
      }
      TopNotification.show(
        title: "Success",
        message: "Sukses Menyimpan Kategori dan Layanan",
        success: true,
      );
      // Clear inputs after save
      categoryCtrl.clear();
      cuci.value = kering.value = setrika.value = false;
    } catch (e) {
      TopNotification.show(
        title: "Error",
        message: "Failed to save: $e",
        success: false,
      );
    }
  }
}
