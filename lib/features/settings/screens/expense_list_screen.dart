import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/expense_controller.dart';
import 'expense_add_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late final ExpenseController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(ExpenseController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // No expense passed → add mode
          final result = await Get.to(() => const ExpenseAddScreen());
          if (result == true) c.applyFilters();
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
                        context: context,
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
    if (c.expenses.isEmpty) {
      return const Center(child: Text('Tidak ada pengeluaran'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: c.expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final exp = c.expenses[i];

        return Dismissible(
          key: ValueKey(exp.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus Pengeluaran?'),
              content: const Text(
                'Data pengeluaran ini akan dihapus secara permanen.',
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
          onDismissed: (_) => c.deleteExpense(exp.id),
          child: Card(
            child: ListTile(
              onTap: () async {
                // Pass model via constructor — type-safe, no Get.arguments risk
                final result = await Get.to(
                  () => ExpenseAddScreen(expense: exp),
                );
                if (result == true) c.applyFilters();
              },
              title: Text('Rp ${exp.nominal.toStringAsFixed(0)}'),
              subtitle: Text(
                '${exp.financialCategory} · ${exp.cashbox}\n${exp.description}',
              ),
              isThreeLine: true,
            ),
          ),
        );
      },
    );
  }
}
