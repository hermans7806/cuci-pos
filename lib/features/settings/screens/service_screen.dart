import 'package:cuci_pos/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/top_notification.dart';
import '../controllers/service_controller.dart';
import 'add_service_category_screen.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    // Owner-only guard
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    final controller = Get.put(ServiceController(), permanent: true);
    // controller.fetchCategories();

    void _confirmDeleteCategory(
      BuildContext context,
      ServiceController controller,
      String categoryId,
    ) {
      Get.defaultDialog(
        title: "Hapus Kategori?",
        middleText:
            "Kategori ini dan semua layanan di dalamnya akan dihapus permanen.",
        confirm: ElevatedButton(
          onPressed: () async {
            Get.back(); // close dialog
            await controller.deleteCategory(categoryId);
            TopNotification.show(
              title: "Success",
              message: "Kategori berhasil dihapus",
              success: true,
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Hapus", style: TextStyle(color: Colors.white)),
        ),
        cancel: TextButton(
          onPressed: () => Get.back(),
          child: const Text("Batal"),
        ),
      );
    }

    void _openCategoryOptions(
      BuildContext context,
      ServiceController controller,
      String categoryId,
    ) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Opsi Kategori"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text("Ubah kategori / tambah layanan"),
                  onTap: () {
                    Navigator.pop(ctx);

                    final category = controller.categories.firstWhere(
                      (c) => c.id == categoryId,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddServiceCategoryScreen(editingCategory: category),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Hapus kategori",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteCategory(context, controller, categoryId);
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Layanan Reguler")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, "/settings/product/service/add-service");
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.categories.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada layanan terdaftar.\nTekan tombol + untuk menambah.",
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: controller.categories.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CATEGORY HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${category.categoryName} (${category.unit})",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _openCategoryOptions(
                        context,
                        controller,
                        category.id,
                      ),
                    ),
                  ],
                ),

                // Process Types
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    category.processTypes.join(", "),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),

                // Service Items
                ...category.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Rp ${item.price} / ${category.unit}"),
                            Text("${item.durationHours} jam"),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                item.notes!,
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            controller.deleteServiceItem(category.id, item.id),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        );
      }),
    );
  }
}
