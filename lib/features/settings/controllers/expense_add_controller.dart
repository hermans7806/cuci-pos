import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/cashbox_model.dart';
import '../../../data/models/financial_category_model.dart';
import '../../../data/services/shared_reference.dart';

class ExpenseAddController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Loaded from Firestore
  var cashboxes = <CashboxModel>[].obs;
  var categories = <FinancialCategory>[].obs;

  // Selected items
  var selectedCashbox = "".obs;
  var selectedCategory = "".obs;

  // Inputs
  final nominal = TextEditingController();
  final description = TextEditingController();
  var date = DateTime.now().obs;

  var isLoading = false.obs;

  late String activeBranchId;

  @override
  void onInit() async {
    super.onInit();
    activeBranchId = await SharedReference.getActiveBranchId();

    loadFilters();
  }

  Future<void> loadFilters() async {
    isLoading.value = true;

    final db = FirebaseFirestore.instance;

    // Load active cashboxes
    final cbSnap = await db
        .collection("cashboxes")
        .where("isActive", isEqualTo: true)
        .where("branchId", isEqualTo: activeBranchId)
        .get();

    cashboxes.value = cbSnap.docs
        .map((e) => CashboxModel.fromFirestore(e))
        .toList();

    // Load categories (pengeluaran)
    final catSnap = await db
        .collection("financial_categories")
        .where("branchId", isEqualTo: activeBranchId)
        .where("category", isEqualTo: "pengeluaran")
        .get();

    categories.value = catSnap.docs
        .map((e) => FinancialCategory.fromFirestore(e))
        .toList();

    isLoading.value = false;
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    final db = FirebaseFirestore.instance;

    await db.collection("expenses").add({
      "branchId": activeBranchId,
      "cashbox": selectedCashbox.value,
      "financialCategory": selectedCategory.value,
      "nominal": double.parse(nominal.text),
      "description": description.text.trim(),
      "date": DateTime(date.value.year, date.value.month, date.value.day),
      "createdAt": FieldValue.serverTimestamp(),
    });

    isLoading.value = false;
    Get.back(result: true); // return to list screen
    TopNotification.show(
      title: 'Sukses',
      message: 'Pengeluaran berhasil ditambahkan.',
      success: true,
    );
  }
}
