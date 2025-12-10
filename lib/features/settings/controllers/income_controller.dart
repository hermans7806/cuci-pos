import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/income_model.dart';

class IncomeController extends GetxController {
  final incomes = <IncomeModel>[].obs;
  final cashboxes = <String>[].obs; // Cashbox names
  final categories = <String>[].obs; // Pendapatan categories

  final selectedCashbox = 'Semua'.obs;
  final selectedCategory = 'Semua'.obs;
  final startDate = DateTime.now().obs;
  final endDate = DateTime.now().obs;

  late String activeBranchId;

  @override
  void onInit() {
    super.onInit();
    _loadBranch();
  }

  Future<void> _loadBranch() async {
    final prefs = await SharedPreferences.getInstance();
    activeBranchId = prefs.getString('activeBranchId') ?? '';

    await loadFilters();
    await loadIncomes();
  }

  Future<void> loadFilters() async {
    // Cashboxes
    final cbSnap = await FirebaseFirestore.instance
        .collection('cashboxes')
        .where('branchId', isEqualTo: activeBranchId)
        .where('isActive', isEqualTo: true)
        .get();

    cashboxes.assignAll(['Semua', ...cbSnap.docs.map((e) => e['name'])]);

    // Categories
    final catSnap = await FirebaseFirestore.instance
        .collection('financial_categories')
        .where('branchId', isEqualTo: activeBranchId)
        .where('category', isEqualTo: 'pendapatan')
        .get();

    categories.assignAll(['Semua', ...catSnap.docs.map((e) => e['name'])]);
  }

  Future<void> loadIncomes() async {
    Query ref = FirebaseFirestore.instance
        .collection('incomes')
        .where('branchId', isEqualTo: activeBranchId)
        .where(
          'date',
          isGreaterThanOrEqualTo: DateTime(
            startDate.value.year,
            startDate.value.month,
            startDate.value.day,
          ),
        )
        .where(
          'date',
          isLessThanOrEqualTo: DateTime(
            endDate.value.year,
            endDate.value.month,
            endDate.value.day,
            23,
            59,
            59,
          ),
        );

    if (selectedCashbox.value != 'Semua') {
      ref = ref.where('cashbox', isEqualTo: selectedCashbox.value);
    }

    if (selectedCategory.value != 'Semua') {
      ref = ref.where('financialCategory', isEqualTo: selectedCategory.value);
    }

    final snap = await ref.orderBy('date', descending: true).get();

    incomes.assignAll(snap.docs.map((d) => IncomeModel.fromDoc(d)));
  }

  void applyFilters() => loadIncomes();
}
