import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/controllers/profile_controller.dart';
import '../controllers/promo_controller.dart';
import '../widgets/promo_card.dart';
import './add_promo_screen.dart';

class PromoScreen extends StatelessWidget {
  PromoScreen({super.key});

  final c = Get.put(PromoController());

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Promos")),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const AddPromoScreen());
          if (result == true) c.loadPromos(); // refresh after add
        },
        child: const Icon(Icons.add),
      ),

      body: Obx(() {
        final pilihan = c.pilihanPromos;
        final otomatis = c.otomatisPromos;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: c.filter.value,
                decoration: const InputDecoration(
                  labelText: "Filter Promos",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "active",
                    child: Text("Active Promos"),
                  ),
                  DropdownMenuItem(
                    value: "inactive",
                    child: Text("Inactive Promos"),
                  ),
                  DropdownMenuItem(value: "all", child: Text("All Promos")),
                ],
                onChanged: (v) => c.filter.value = v!,
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text(
                    "Promo Pilihan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (pilihan.isEmpty) const Text("Tidak ada promo pilihan."),

                  ...pilihan.map((p) {
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Promo?"),
                            content: const Text(
                              "Are you sure you want to delete this promo?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await c.deletePromo(p.id);
                        c.loadPromos();
                      },
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Get.to(
                            () => AddPromoScreen(promo: p),
                          );
                          if (result == true) c.loadPromos();
                        },
                        child: PromoCard(promo: p),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 24),

                  const Text(
                    "Promo Otomatis",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (otomatis.isEmpty) const Text("Tidak ada promo otomatis."),

                  ...otomatis.map((p) {
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Delete Promo?"),
                            content: const Text(
                              "Are you sure you want to delete this promo?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await c.deletePromo(p.id);
                        c.loadPromos();
                      },
                      child: GestureDetector(
                        onTap: () async {
                          final result = await Get.to(
                            () => AddPromoScreen(promo: p),
                          );
                          if (result == true) c.loadPromos();
                        },
                        child: PromoCard(promo: p),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
