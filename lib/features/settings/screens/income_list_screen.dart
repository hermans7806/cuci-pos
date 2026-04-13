import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/income_controller.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  State<IncomeListScreen> createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> {
  late final IncomeController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(IncomeController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendapatan')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // No arguments → add mode
          final result = await Navigator.pushNamed(
            context,
            '/settings/finances/income/add',
          );
          if (result == true) c.loadIncomes();
        },
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildFilters(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        );
      }),
    );
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: c.selectedCashbox.value,
                    decoration: const InputDecoration(labelText: 'Cashbox'),
                    items: c.cashboxes
                        .map(
                          (cb) => DropdownMenuItem(value: cb, child: Text(cb)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        c.selectedCashbox.value = v;
                        c.applyFilters();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: c.selectedCategory.value,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: c.categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        c.selectedCategory.value = v;
                        c.applyFilters();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Obx(
                  () => GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context, // ← local context, not Get.context!
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: c.startDate.value,
                      );
                      if (picked != null) {
                        c.startDate.value = picked;
                        c.applyFilters();
                      }
                    },
                    child: _dateBox('Start Date', c.startDate.value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDate: c.endDate.value,
                      );
                      if (picked != null) {
                        c.endDate.value = picked;
                        c.applyFilters();
                      }
                    },
                    child: _dateBox('End Date', c.endDate.value),
                  ),
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
          Text(
            '${date.year}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _buildList() {
    if (c.incomes.isEmpty) {
      return const Center(child: Text('Tidak ada pendapatan'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: c.incomes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final inc = c.incomes[i];

        return Dismissible(
          key: ValueKey(inc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => showDialog<bool>(
            context: context, // ← local context
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus Pendapatan?'),
              content: const Text(
                'Data pendapatan ini akan dihapus secara permanen.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) => c.deleteIncome(inc.id),
          child: Card(
            child: ListTile(
              onTap: () async {
                // Pass the full model — rawCashboxId/rawCategoryId are intact
                // so the edit form can pre-select the correct dropdown values.
                final result = await Navigator.pushNamed(
                  context, // ← local context
                  '/settings/finances/income/add',
                  arguments: inc,
                );
                if (result == true) c.loadIncomes();
              },
              title: Text('Rp ${inc.nominal.toStringAsFixed(0)}'),
              subtitle: Text(
                '${inc.financialCategory} · ${inc.cashbox}\n${inc.description}',
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}
