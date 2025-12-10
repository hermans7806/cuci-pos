// lib/features/finances/controllers/fin_category_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/financial_category_model.dart';
import '../../../data/services/shared_reference.dart';

class FinCategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<FinancialCategory> income = <FinancialCategory>[].obs;
  RxList<FinancialCategory> expense = <FinancialCategory>[].obs;

  RxBool isLoading = false.obs;
  String branchId = '';

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    branchId = await SharedReference.getActiveBranchId();

    final snap = await _firestore
        .collection('financial_categories')
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .get();

    final docs = snap.docs;
    final cats = docs
        .map(
          (d) =>
              FinancialCategory.fromDoc(d.id, d.data() as Map<String, dynamic>),
        )
        .toList();

    income.value = cats.where((c) => c.category == 'pendapatan').toList();
    expense.value = cats.where((c) => c.category == 'pengeluaran').toList();

    isLoading.value = false;
  }

  Future<void> addCategory({
    required String name,
    required String category, // 'pendapatan' | 'pengeluaran'
  }) async {
    final ref = _firestore.collection('financial_categories').doc();
    await ref.set({
      'name': name,
      'category': category,
      'branchId': branchId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await loadData();
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('financial_categories').doc(id).delete();
    await loadData();
  }
}
