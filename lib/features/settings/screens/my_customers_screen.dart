import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';
import '../controllers/customer_controller.dart';
import 'customer_form_screen.dart';

class MyCustomersScreen extends StatelessWidget {
  MyCustomersScreen({super.key});

  final TextEditingController searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerController());
    final profileCtrl = Get.find<ProfileController>();

    // Owner-only guard
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => CustomerFormScreen()),
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by name or phone",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                controller.search(v.trim());
              },
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.customers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent) {
                    controller.fetchMore();
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount:
                      controller.customers.length +
                      (controller.isMoreLoading.value ? 1 : 0),
                  itemBuilder: (_, i) {
                    // Show pagination loading row
                    if (i == controller.customers.length &&
                        controller.isMoreLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final c = controller.customers[i];

                    return Dismissible(
                      key: Key(c.id),
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
                            title: const Text('Delete?'),
                            content: const Text(
                              'Are you sure you want to delete this customer?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) => controller.deleteCustomer(c.id),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(c.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                Get.to(() => CustomerFormScreen(customer: c)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
