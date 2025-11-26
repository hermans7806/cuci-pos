import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart'; // tiny package for generating temporary ids (optional)

import '../../../data/models/service_item_model.dart';
import '../controllers/service_controller.dart';

class ServiceItemBottomSheet extends StatefulWidget {
  const ServiceItemBottomSheet({super.key});

  @override
  State<ServiceItemBottomSheet> createState() => _ServiceItemBottomSheetState();
}

class _ServiceItemBottomSheetState extends State<ServiceItemBottomSheet> {
  final controller = Get.find<ServiceController>();

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  // unit radio (Kg, Meter, Satuan)
  String unit = 'Kg';

  // estimated unit selector (jam, hari)
  String estUnit = 'jam';

  // optional: which process type this item belongs to — we keep blank, UI can set if needed
  String processType = 'cuci';

  @override
  Widget build(BuildContext context) {
    // Use SafeArea + Padding for the keyboard
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Service Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Layanan'),
                ),

                const SizedBox(height: 8),
                // Unit radio
                Row(
                  children: [
                    Expanded(child: Text('Unit:')),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Kg',
                          groupValue: unit,
                          onChanged: (v) => setState(() => unit = v!),
                        ),
                        const Text('Kg'),
                        Radio<String>(
                          value: 'Meter',
                          groupValue: unit,
                          onChanged: (v) => setState(() => unit = v!),
                        ),
                        const Text('Meter'),
                        Radio<String>(
                          value: 'Satuan',
                          groupValue: unit,
                          onChanged: (v) => setState(() => unit = v!),
                        ),
                        const Text('Satuan'),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 8),

                // Estimation + select box unit (jam/hari)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Estimasi Waktu',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: estUnit,
                      items: const [
                        DropdownMenuItem(value: 'jam', child: Text('Jam')),
                        DropdownMenuItem(value: 'hari', child: Text('Hari')),
                      ],
                      onChanged: (v) => setState(() => estUnit = v ?? 'jam'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (opsional)',
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSaveItem,
                        child: const Text('Save Item'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSaveItem() {
    final name = nameCtrl.text.trim();
    final price = num.tryParse(priceCtrl.text.trim()) ?? 0;
    final durationVal = int.tryParse(durationCtrl.text.trim()) ?? 0;
    final notes = notesCtrl.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Error', 'Nama layanan harus diisi');
      return;
    }
    if (durationVal <= 0) {
      Get.snackbar('Error', 'Estimasi harus lebih dari 0');
      return;
    }

    // convert to hours
    final int durationHours = estUnit == 'hari'
        ? (durationVal * 24)
        : durationVal;

    // generate a temporary id for in-memory list (we use uuid or timestamp)
    final String tempId = const Uuid().v4();

    final item = ServiceItemModel(
      id: tempId,
      name: name,
      unit: unit,
      price: price,
      durationHours: durationHours,
      notes: notes,
    );

    controller.addTempItem(item);

    nameCtrl.text = '';
    priceCtrl.text = '';
    durationCtrl.text = '';
    notesCtrl.text = '';

    // Get.back(); // dismiss bottom sheet
  }
}
