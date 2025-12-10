import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/income_add_controller.dart';

class IncomeAddScreen extends StatelessWidget {
  const IncomeAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(IncomeAddController());

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Pendapatan")),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: c.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Cashbox
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Cashbox"),
                value: c.selectedCashbox.value.isEmpty
                    ? null
                    : c.selectedCashbox.value,
                items: c.cashboxes
                    .map(
                      (cb) =>
                          DropdownMenuItem(value: cb.id, child: Text(cb.name)),
                    )
                    .toList(),
                validator: (v) => v == null ? "Pilih cashbox" : null,
                onChanged: (v) => c.selectedCashbox.value = v!,
              ),

              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Kategori"),
                value: c.selectedCategory.value.isEmpty
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
                    v == null ? "Pilih kategori pendapatan" : null,
                onChanged: (v) => c.selectedCategory.value = v!,
              ),

              const SizedBox(height: 16),

              // Nominal
              TextFormField(
                controller: c.nominal,
                decoration: const InputDecoration(labelText: "Nominal (Rp)"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Nominal wajib diisi";
                  }
                  if (double.tryParse(v) == null) {
                    return "Nominal tidak valid";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: c.description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Deskripsi (opsional)",
                ),
              ),

              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
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
                      const Text("Tanggal"),
                      Text(
                        "${c.date.value.year}-${c.date.value.month}-${c.date.value.day}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: c.save,
                  child: const Text("Simpan"),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
