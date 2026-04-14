import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/income_model.dart';
import '../controllers/income_add_controller.dart';

class IncomeAddScreen extends StatefulWidget {
  final IncomeModel? income;

  const IncomeAddScreen({super.key, this.income});

  @override
  State<IncomeAddScreen> createState() => _IncomeAddScreenState();
}

class _IncomeAddScreenState extends State<IncomeAddScreen> {
  late final IncomeAddController c;

  @override
  void initState() {
    super.initState();
    Get.delete<IncomeAddController>(force: true);
    // Pass widget.income directly — no Get.arguments, no routing magic.
    c = Get.put(IncomeAddController(editingModel: widget.income));
  }

  @override
  void dispose() {
    Get.delete<IncomeAddController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(c.isEditing ? 'Edit Pendapatan' : 'Tambah Pendapatan'),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: c.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Date picker ────────────────────────────────────────────
              Obx(
                () => GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: c.date.value,
                    );
                    if (picked != null) c.date.value = picked;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tanggal'),
                        Text(
                          '${c.date.value.year}-'
                          '${c.date.value.month.toString().padLeft(2, '0')}-'
                          '${c.date.value.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Cashbox ────────────────────────────────────────────────
              Obx(
                () => DropdownButtonFormField<String>(
                  key: ValueKey(
                    'cashbox_${c.cashboxes.length}_${c.selectedCashbox.value}',
                  ),
                  decoration: const InputDecoration(labelText: 'Cashbox'),
                  value:
                      c.selectedCashbox.value.isEmpty ||
                          !c.cashboxes.any(
                            (cb) => cb.id == c.selectedCashbox.value,
                          )
                      ? null
                      : c.selectedCashbox.value,
                  items: c.cashboxes
                      .map(
                        (cb) => DropdownMenuItem(
                          value: cb.id,
                          child: Text(cb.name),
                        ),
                      )
                      .toList(),
                  validator: (v) => v == null ? 'Pilih cashbox' : null,
                  onChanged: (v) {
                    if (v != null) c.selectedCashbox.value = v;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Category ───────────────────────────────────────────────
              Obx(
                () => DropdownButtonFormField<String>(
                  key: ValueKey(
                    'category_${c.categories.length}_${c.selectedCategory.value}',
                  ),
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  value:
                      c.selectedCategory.value.isEmpty ||
                          !c.categories.any(
                            (cat) => cat.id == c.selectedCategory.value,
                          )
                      ? null
                      : c.selectedCategory.value,
                  items: c.categories
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ),
                      )
                      .toList(),
                  validator: (v) =>
                      v == null ? 'Pilih kategori pendapatan' : null,
                  onChanged: (v) {
                    if (v != null) c.selectedCategory.value = v;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ── Nominal ────────────────────────────────────────────────
              TextFormField(
                controller: c.nominal,
                decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Nominal wajib diisi';
                  if (double.tryParse(v) == null) return 'Nominal tidak valid';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Description ────────────────────────────────────────────
              TextFormField(
                controller: c.description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                ),
              ),

              const SizedBox(height: 30),

              // ── Submit ─────────────────────────────────────────────────
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: c.isSaving.value ? null : c.save,
                    child: c.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan'),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
