import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/service_category_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/service_controller.dart';
import 'service_item_bottomsheet.dart';

class AddServiceCategoryScreen extends StatefulWidget {
  final ServiceCategoryModel? editingCategory;

  const AddServiceCategoryScreen({super.key, this.editingCategory});

  @override
  State<AddServiceCategoryScreen> createState() =>
      _AddServiceCategoryScreenState();
}

class _AddServiceCategoryScreenState extends State<AddServiceCategoryScreen> {
  final ServiceController controller = Get.find<ServiceController>();

  // Form controllers
  final TextEditingController categoryCtrl = TextEditingController();

  // Checkboxes
  final RxBool cuci = false.obs;
  final RxBool kering = false.obs;
  final RxBool setrika = false.obs;

  @override
  void initState() {
    super.initState();

    final editing = widget.editingCategory;

    if (editing != null) {
      // Prefill editing state
      categoryCtrl.text = editing.categoryName;

      cuci.value = editing.processTypes.contains("cuci");
      kering.value = editing.processTypes.contains("kering");
      setrika.value = editing.processTypes.contains("setrika");

      controller.categoryUnit.value = editing.unit ?? "Satuan";

      controller.tempItems.assignAll(editing.items);

      controller.initializedForAdd = false; // prevent auto clearing
    } else {
      // Adding new category — clear temp only once
      if (!controller.initializedForAdd) {
        controller.tempItems.clear();
        controller.initializedForAdd = true;
      }

      // default unit
      controller.categoryUnit.value = "Satuan";
    }
  }

  @override
  void dispose() {
    _resetForm();
    super.dispose();
  }

  // Reset everything (called on back and dispose)
  void _resetForm() {
    controller.tempItems.clear();
    controller.initializedForAdd = false;

    categoryCtrl.clear();
    cuci.value = false;
    kering.value = false;
    setrika.value = false;

    controller.categoryUnit.value = "Satuan";
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
    if (cuci.value) selectedTypes.add("cuci");
    if (kering.value) selectedTypes.add("kering");
    if (setrika.value) selectedTypes.add("setrika");

    if (name.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Nama Kategori Wajib Diisi",
        success: false,
      );
      return;
    }
    if (selectedTypes.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Pilih Setidaknya 1 Proses Produksi",
        success: false,
      );
      return;
    }
    if (controller.tempItems.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Tambahkan setidaknya 1 Layanan",
        success: false,
      );
      return;
    }

    try {
      if (widget.editingCategory == null) {
        await controller.saveCategoryWithItems(
          categoryName: name,
          types: selectedTypes,
        );
      } else {
        await controller.updateCategoryWithItems(
          categoryId: widget.editingCategory!.id,
          categoryName: name,
          types: selectedTypes,
          items: controller.tempItems,
        );
      }

      TopNotification.show(
        title: "Success",
        message: "Sukses Menyimpan Kategori & Layanan",
        success: true,
      );

      _resetForm(); // clear before closing
      Get.back();
    } catch (e) {
      TopNotification.show(
        title: "Error",
        message: "Failed to save: $e",
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    // Owner guard
    if (profileCtrl.role.value != "owner") {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          _resetForm();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.editingCategory == null
                ? "Tambah Kategori Layanan"
                : "Edit Kategori Layanan",
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _resetForm();
              Get.back();
            },
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
                        "Nama Kategori",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "e.g. Sepatu",
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Proses Produksi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Obx(
                            () => Checkbox(
                              value: cuci.value,
                              onChanged: (v) => cuci.value = v!,
                            ),
                          ),
                          const Text("Cuci"),
                          const SizedBox(width: 16),

                          Obx(
                            () => Checkbox(
                              value: kering.value,
                              onChanged: (v) => kering.value = v!,
                            ),
                          ),
                          const Text("Kering"),
                          const SizedBox(width: 16),

                          Obx(
                            () => Checkbox(
                              value: setrika.value,
                              onChanged: (v) => setrika.value = v!,
                            ),
                          ),
                          const Text("Setrika"),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Unit Satuan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Obx(() {
                        return Row(
                          children: [
                            Radio(
                              value: "Kg",
                              groupValue: controller.categoryUnit.value,
                              onChanged: (v) =>
                                  controller.categoryUnit.value = v!,
                            ),
                            const Text("Kg"),
                            Radio(
                              value: "Meter",
                              groupValue: controller.categoryUnit.value,
                              onChanged: (v) =>
                                  controller.categoryUnit.value = v!,
                            ),
                            const Text("Meter"),
                            Radio(
                              value: "Satuan",
                              groupValue: controller.categoryUnit.value,
                              onChanged: (v) =>
                                  controller.categoryUnit.value = v!,
                            ),
                            const Text("Satuan"),
                          ],
                        );
                      }),

                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () => _openAddItemSheet(context),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text("Tambah Layanan"),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const Text(
                        "Layanan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      if (controller.tempItems.isEmpty)
                        const Text("Belum ada layanan.")
                      else
                        Column(
                          children: controller.tempItems.map((it) {
                            return Card(
                              child: ListTile(
                                title: Text(it.name),
                                subtitle: Text(
                                  "Rp ${it.price} • ${it.durationHours} jam",
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

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _onSaveCategory(context),
                          child: const Text("Save Category & Items"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
