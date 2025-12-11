import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/income_model.dart';

class IncomeController extends GetxController {
  final incomes = <IncomeModel>[].obs;

  final cashboxes = <String>[].obs; // cashbox display names
  final cashboxIdMap = <String, String>{}.obs; // id → name

  final categories = <String>[].obs; // category display names
  final categoryIdMap = <String, String>{}.obs; // id → name

  final selectedCashbox = "Semua".obs;
  final selectedCategory = "Semua".obs;

  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().obs;

  late String branchId;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadBranchId();
    await loadCashboxes();
    await loadCategories();
    await loadIncomes();
  }

  Future<void> _loadBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    branchId = prefs.getString("activeBranchId") ?? "";
  }

  // --------------------------
  // LOAD CASHBOXES
  // --------------------------
  Future<void> loadCashboxes() async {
    final qs = await FirebaseFirestore.instance
        .collection("cashboxes")
        .where("isActive", isEqualTo: true)
        .where("branchId", isEqualTo: branchId)
        .get();

    cashboxes.clear();
    cashboxIdMap.clear();

    cashboxes.add("Semua");

    for (var d in qs.docs) {
      final name = d["name"];
      final id = d.id;

      cashboxes.add(name);
      cashboxIdMap[id] = name;
    }
  }

  // --------------------------
  // LOAD FINANCIAL CATEGORIES
  // --------------------------
  Future<void> loadCategories() async {
    final qs = await FirebaseFirestore.instance
        .collection("financial_categories")
        .where("branchId", isEqualTo: branchId)
        .where("category", isEqualTo: "pendapatan")
        .get();

    categories.clear();
    categoryIdMap.clear();

    categories.add("Semua");

    for (var d in qs.docs) {
      final name = d["name"];
      final id = d.id;

      categories.add(name);
      categoryIdMap[id] = name;
    }
  }

  // --------------------------
  // LOAD INCOMES (RAW)
  // --------------------------
  Future<void> loadIncomes() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59);

    final qs = await FirebaseFirestore.instance
        .collection("incomes")
        .where("branchId", isEqualTo: branchId)
        .where("date", isGreaterThanOrEqualTo: start)
        .where("date", isLessThanOrEqualTo: end)
        .orderBy("date", descending: true)
        .get();

    incomes.value = qs.docs
        .map((d) => IncomeModel.fromMap(d.id, d.data()))
        .toList();

    _applyNameMapping();
  }

  // --------------------------
  // FILTER LOGIC
  // --------------------------
  Future<void> applyFilters() async {
    final qs = FirebaseFirestore.instance
        .collection("incomes")
        .where("branchId", isEqualTo: branchId)
        .where(
          "date",
          isGreaterThanOrEqualTo: DateTime(
            startDate.value.year,
            startDate.value.month,
            startDate.value.day,
          ),
        )
        .where(
          "date",
          isLessThanOrEqualTo: DateTime(
            endDate.value.year,
            endDate.value.month,
            endDate.value.day,
            23,
            59,
          ),
        );

    final result = await qs.orderBy("date", descending: true).get();

    var list = result.docs
        .map((d) => IncomeModel.fromMap(d.id, d.data()))
        .toList();

    // Filter Cashbox by NAME not ID
    if (selectedCashbox.value != "Semua") {
      list = list
          .where((e) => cashboxIdMap[e.cashbox] == selectedCashbox.value)
          .toList();
    }

    // Filter Category by NAME not ID
    if (selectedCategory.value != "Semua") {
      list = list
          .where(
            (e) => categoryIdMap[e.financialCategory] == selectedCategory.value,
          )
          .toList();
    }

    incomes.value = list;
    _applyNameMapping();
  }

  // --------------------------
  // MAP IDs into readable names
  // --------------------------
  void _applyNameMapping() {
    for (var i = 0; i < incomes.length; i++) {
      final inc = incomes[i];

      final readableCashbox = cashboxIdMap[inc.cashbox] ?? inc.cashbox;

      final readableCategory =
          categoryIdMap[inc.financialCategory] ?? inc.financialCategory;

      incomes[i] = inc.copyWith(
        cashbox: readableCashbox,
        financialCategory: readableCategory,
      );
    }
  }
}
