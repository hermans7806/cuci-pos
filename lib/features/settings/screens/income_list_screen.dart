import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/income_controller.dart';

class IncomeListScreen extends StatelessWidget {
  const IncomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(IncomeController());

    return Scaffold(
      appBar: AppBar(title: const Text("Pendapatan Hari Ini")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/settings/finances/income/add');
          c.loadIncomes();
        },
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        return Column(
          children: [
            _buildFilters(c),
            const Divider(height: 1),
            Expanded(child: _buildList(c)),
          ],
        );
      }),
    );
  }

  Widget _buildFilters(IncomeController c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Cashbox + Category Filters SIDE BY SIDE
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: c.selectedCashbox.value,
                  decoration: const InputDecoration(labelText: "Cashbox"),
                  items: c.cashboxes
                      .map((cb) => DropdownMenuItem(value: cb, child: Text(cb)))
                      .toList(),
                  onChanged: (v) {
                    c.selectedCashbox.value = v!;
                    c.applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: c.selectedCategory.value,
                  decoration: const InputDecoration(labelText: "Kategori"),
                  items: c.categories
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (v) {
                    c.selectedCategory.value = v!;
                    c.applyFilters();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dates
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: c.startDate.value,
                    );
                    if (picked != null) {
                      c.startDate.value = picked;
                      c.applyFilters();
                    }
                  },
                  child: _dateBox("Start Date", c.startDate.value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: c.endDate.value,
                    );
                    if (picked != null) {
                      c.endDate.value = picked;
                      c.applyFilters();
                    }
                  },
                  child: _dateBox("End Date", c.endDate.value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          Text("${date.year}-${date.month}-${date.day}"),
        ],
      ),
    );
  }

  Widget _buildList(IncomeController c) {
    if (c.incomes.isEmpty) {
      return const Center(child: Text("Tidak ada pendapatan hari ini"));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: c.incomes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final inc = c.incomes[i];

        return Card(
          child: ListTile(
            title: Text("Rp ${inc.nominal.toStringAsFixed(0)}"),
            subtitle: Text(
              "${inc.financialCategory} · ${inc.cashbox}\n${inc.description}",
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
