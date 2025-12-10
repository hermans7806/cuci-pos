// lib/features/finances/screens/fin_category_screen.dart
import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/financial_category_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/fin_category_controller.dart';

class FinCategoryListScreen extends StatelessWidget {
  const FinCategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    final controller = Get.put(FinCategoryController());

    // DefaultTabController is provided here. Use Builder to get a context
    // that is a descendant of DefaultTabController so DefaultTabController.of(context)
    // returns a valid TabController.
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (innerContext) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Financial Categories'),
              // DON'T make TabBar const so it can resolve the runtime TabController.
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Kategori Pendapatan'),
                  Tab(text: 'Kategori Pengeluaran'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // use innerContext (descendant of DefaultTabController)
                final tabIndex = DefaultTabController.of(innerContext)!.index;
                final category = tabIndex == 0 ? 'pendapatan' : 'pengeluaran';
                _showAddDialog(innerContext, controller, category);
              },
              child: const Icon(Icons.add),
            ),
            body: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                children: [
                  _buildListView(
                    context,
                    controller,
                    controller.income,
                    'pendapatan',
                  ),
                  _buildListView(
                    context,
                    controller,
                    controller.expense,
                    'pengeluaran',
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    FinCategoryController ctrl,
    List<FinancialCategory> items,
    String categoryKey,
  ) {
    if (items.isEmpty) {
      return Center(child: Text('No items in "$categoryKey"'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final cat = items[i];

        return Dismissible(
          key: Key(cat.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            // confirm dialog
            final res = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Hapus Kategori'),
                content: Text('Yakin ingin menghapus "${cat.name}" ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            );
            return res ?? false;
          },
          onDismissed: (_) async {
            try {
              await ctrl.deleteCategory(cat.id);
              TopNotification.show(
                title: 'Deleted',
                message: 'Category "${cat.name}" deleted',
                success: true,
              );
            } catch (e) {
              // if deletion failed (e.g., not owner) - show error and reload
              TopNotification.show(
                title: 'Error',
                message: e.toString(),
                success: false,
              );
              await ctrl.loadData();
            }
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: Card(child: ListTile(title: Text(cat.name))),
        );
      },
    );
  }

  void _showAddDialog(
    BuildContext context,
    FinCategoryController controller,
    String category, // 'pendapatan' | 'pengeluaran'
  ) {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                Get.back(); // close dialog first
                TopNotification.show(
                  title: 'Error',
                  message: 'Nama Kategori tidak boleh kosong',
                  success: false,
                );
                return;
              }

              Navigator.pop(context); // close dialog first

              await controller.addCategory(name: name, category: category);

              TopNotification.show(
                title: 'Saved',
                message: 'Kategori ditambahkan',
                success: true,
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
