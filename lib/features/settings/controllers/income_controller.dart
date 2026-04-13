import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/income_model.dart';

class IncomeController extends GetxController {
  final incomes = <IncomeModel>[].obs;

  final cashboxes = <String>[]; // display names for filter dropdown
  final cashboxIdMap = <String, String>{}; // id → name (plain map, not .obs)

  final categories = <String>[]; // display names for filter dropdown
  final categoryIdMap = <String, String>{}; // id → name

  final selectedCashbox = 'Semua'.obs;
  final selectedCategory = 'Semua'.obs;

  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().obs;

  final isLoading = true.obs;

  late String branchId;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // onInit MUST be synchronous in GetX — async work goes in a helper.
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _loadBranchId();
      await loadCashboxes();
      await loadCategories();
      await loadIncomes();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    branchId = prefs.getString('activeBranchId') ?? '';
  }

  // ── Loaders ───────────────────────────────────────────────────────────────

  Future<void> loadCashboxes() async {
    final qs = await FirebaseFirestore.instance
        .collection('cashboxes')
        .where('isActive', isEqualTo: true)
        .where('branchId', isEqualTo: branchId)
        .get();

    cashboxes.clear();
    cashboxIdMap.clear();
    cashboxes.add('Semua');

    for (final d in qs.docs) {
      final name = d['name'] as String;
      cashboxes.add(name);
      cashboxIdMap[d.id] = name;
    }
  }

  Future<void> loadCategories() async {
    final qs = await FirebaseFirestore.instance
        .collection('financial_categories')
        .where('branchId', isEqualTo: branchId)
        .where('category', isEqualTo: 'pendapatan')
        .get();

    categories.clear();
    categoryIdMap.clear();
    categories.add('Semua');

    for (final d in qs.docs) {
      final name = d['name'] as String;
      categories.add(name);
      categoryIdMap[d.id] = name;
    }
  }

  Future<void> loadIncomes() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final qs = await FirebaseFirestore.instance
        .collection('incomes')
        .where('branchId', isEqualTo: branchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();

    incomes.value = qs.docs
        .map((d) => IncomeModel.fromMap(d.id, d.data()))
        .toList();

    _applyNameMapping();
  }

  Future<void> applyFilters() async {
    final start = DateTime(
      startDate.value.year,
      startDate.value.month,
      startDate.value.day,
    );
    final end = DateTime(
      endDate.value.year,
      endDate.value.month,
      endDate.value.day,
      23,
      59,
      59,
    );

    final result = await FirebaseFirestore.instance
        .collection('incomes')
        .where('branchId', isEqualTo: branchId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date', descending: true)
        .get();

    var list = result.docs
        .map((d) => IncomeModel.fromMap(d.id, d.data()))
        .toList();

    // MUST use rawCashboxId / rawCategoryId — the cashbox / financialCategory
    // fields may already be display names after _applyNameMapping().
    if (selectedCashbox.value != 'Semua') {
      list = list
          .where((e) => cashboxIdMap[e.rawCashboxId] == selectedCashbox.value)
          .toList();
    }

    if (selectedCategory.value != 'Semua') {
      list = list
          .where(
            (e) => categoryIdMap[e.rawCategoryId] == selectedCategory.value,
          )
          .toList();
    }

    incomes.value = list;
    _applyNameMapping();
  }

  /// Overwrites display fields with human-readable names.
  /// Raw IDs are preserved in rawCashboxId / rawCategoryId on the model.
  void _applyNameMapping() {
    incomes.value = incomes.map((inc) {
      return inc.copyWith(
        cashbox: cashboxIdMap[inc.rawCashboxId] ?? 'Cashbox Tidak Ditemukan',
        financialCategory:
            categoryIdMap[inc.rawCategoryId] ?? 'Kategori Tidak Ditemukan',
      );
    }).toList();
  }

  Future<void> deleteIncome(String id) async {
    await FirebaseFirestore.instance.collection('incomes').doc(id).delete();
    await loadIncomes();
  }
}
