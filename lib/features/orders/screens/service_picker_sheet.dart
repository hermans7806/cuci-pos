import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/selected_service_model.dart';

class ServiceCategory {
  final String id;
  final String name;

  ServiceCategory({required this.id, required this.name});
}

class ServiceItemModel {
  final String id;
  final String name;
  final int price;
  final int duration; // days or hours depending on your system

  ServiceItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
  });
}

class ServicePickerSheet extends StatefulWidget {
  final Function(SelectedService item) onAdd;

  const ServicePickerSheet({super.key, required this.onAdd});

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<ServiceCategory> categories = [];
  Map<String, List<ServiceItemModel>> itemsMap = {};
  List<String> expanded = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final snap = await _db.collection('services').get();
    categories = snap.docs
        .map((d) => ServiceCategory(id: d.id, name: d['name']))
        .toList();

    setState(() {});
  }

  Future<void> loadItems(String categoryId) async {
    final snap = await _db
        .collection('services')
        .doc(categoryId)
        .collection('items')
        .get();

    itemsMap[categoryId] = snap.docs.map((d) {
      final data = d.data();
      return ServiceItemModel(
        id: d.id,
        name: data['name'] ?? '',
        price: (data['price'] as num?)?.toInt() ?? 0,
        duration: data['duration'] ?? 0,
      );
    }).toList();

    setState(() {});
  }

  void toggleExpand(String categoryId) async {
    if (expanded.contains(categoryId)) {
      expanded.remove(categoryId);
    } else {
      expanded.add(categoryId);
      await loadItems(categoryId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Pilih Layanan",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (_, i) {
                    final cat = categories[i];
                    final isOpen = expanded.contains(cat.id);
                    final items = itemsMap[cat.id] ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          onTap: () => toggleExpand(cat.id),
                        ),

                        if (isOpen)
                          ...items.map((item) {
                            return Container(
                              margin: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                bottom: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade100,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Rp ${item.price}  •  ${item.duration} hari",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final selected = SelectedService(
                                        id: item.id,
                                        name: item.name,
                                        price: item.price,
                                        duration: item.duration,
                                        qty: 1,
                                      );
                                      widget.onAdd(selected);
                                      Get.back();
                                    },
                                    child: const Text("Tambah"),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
