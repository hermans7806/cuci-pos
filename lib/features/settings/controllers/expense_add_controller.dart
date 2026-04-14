import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/cashbox_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/financial_category_model.dart';
import '../../../data/services/shared_reference.dart';

class ExpenseAddController extends GetxController {
  /// Pass the model to edit directly from the screen — do NOT rely on
  /// Get.arguments, which may be cleared by Get.delete before onInit runs.
  ExpenseAddController({ExpenseModel? editingModel}) : _editing = editingModel;

  final formKey = GlobalKey<FormState>();

  // ── Firestore data ───────────────────────────────────────────────────────
  final cashboxes = <CashboxModel>[].obs;
  final categories = <FinancialCategory>[].obs;

  // ── Form state ───────────────────────────────────────────────────────────
  /// Always holds a Firestore document ID, never a display name.
  final selectedCashbox = ''.obs;
  final selectedCategory = ''.obs;

  final nominal = TextEditingController();
  final description = TextEditingController();
  final date = DateTime.now().obs;

  // ── UI flags ─────────────────────────────────────────────────────────────
  final isLoading = true.obs; // starts true — prevents empty-form flash
  final isSaving = false.obs;

  // ── Internal ─────────────────────────────────────────────────────────────
  late String _activeBranchId;
  final ExpenseModel? _editing;

  bool get isEditing => _editing != null;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    nominal.dispose();
    description.dispose();
    super.onClose();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    try {
      _activeBranchId = await SharedReference.getActiveBranchId();
      await _loadCashboxes();
      await _loadCategories();
      if (_editing != null) _fillEditingData();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCashboxes() async {
    final snap = await FirebaseFirestore.instance
        .collection('cashboxes')
        .where('isActive', isEqualTo: true)
        .where('branchId', isEqualTo: _activeBranchId)
        .get();

    cashboxes.value = snap.docs
        .map((e) => CashboxModel.fromFirestore(e))
        .toList();
  }

  Future<void> _loadCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection('financial_categories')
        .where('branchId', isEqualTo: _activeBranchId)
        .where('category', isEqualTo: 'pengeluaran')
        .get();

    categories.value = snap.docs
        .map((e) => FinancialCategory.fromFirestore(e))
        .toList();
  }

  /// Uses rawCashboxId / rawCategoryId — works correctly whether or not
  /// _applyNameMapping() has already overwritten the display fields.
  void _fillEditingData() {
    final exp = _editing!;

    selectedCashbox.value = exp.rawCashboxId;
    selectedCategory.value = exp.rawCategoryId;

    nominal.text = exp.nominal.truncateToDouble() == exp.nominal
        ? exp.nominal.toStringAsFixed(0)
        : exp.nominal.toStringAsFixed(2);

    description.text = exp.description;
    date.value = exp.date;
  }

  // ── Public ────────────────────────────────────────────────────────────────

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      final db = FirebaseFirestore.instance;

      final payload = <String, dynamic>{
        'branchId': _activeBranchId,
        'cashbox': selectedCashbox.value,
        'financialCategory': selectedCategory.value,
        'nominal': double.parse(nominal.text.trim()),
        'description': description.text.trim(),
        'date': DateTime(date.value.year, date.value.month, date.value.day),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editing == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await db.collection('expenses').add(payload);
      } else {
        await db.collection('expenses').doc(_editing.id).update(payload);
      }

      Get.back(result: true);

      TopNotification.show(
        title: 'Sukses',
        message: _editing == null
            ? 'Pengeluaran berhasil ditambahkan.'
            : 'Pengeluaran berhasil diperbaharui.',
        success: true,
      );
    } catch (e) {
      TopNotification.show(
        title: 'Gagal',
        message: 'Terjadi kesalahan. Silakan coba lagi.',
        success: false,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
