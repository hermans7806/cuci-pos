import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String id;
  final DateTime date;

  /// May be overwritten with a display name by _applyNameMapping().
  /// Use [rawCashboxId] when you need the original Firestore document ID.
  final String cashbox;
  final String financialCategory;

  final double nominal;
  final String description;
  final String branchId;

  /// Always holds the original Firestore document ID, even after name mapping.
  final String rawCashboxId;
  final String rawCategoryId;

  IncomeModel({
    required this.id,
    required this.date,
    required this.cashbox,
    required this.financialCategory,
    required this.nominal,
    required this.description,
    required this.branchId,
    String? rawCashboxId,
    String? rawCategoryId,
  }) : rawCashboxId = rawCashboxId ?? cashbox,
       rawCategoryId = rawCategoryId ?? financialCategory;

  factory IncomeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final cashboxId = data['cashbox'] ?? '';
    final categoryId = data['financialCategory'] ?? '';

    return IncomeModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      cashbox: cashboxId,
      financialCategory: categoryId,
      nominal: (data['nominal'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      branchId: data['branchId'] ?? '',
      rawCashboxId: cashboxId,
      rawCategoryId: categoryId,
    );
  }

  factory IncomeModel.fromMap(String id, Map<String, dynamic> data) {
    final cashboxId = data['cashbox'] ?? '';
    final categoryId = data['financialCategory'] ?? '';

    return IncomeModel(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      cashbox: cashboxId,
      financialCategory: categoryId,
      nominal: (data['nominal'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      branchId: data['branchId'] ?? '',
      rawCashboxId: cashboxId,
      rawCategoryId: categoryId,
    );
  }

  /// Used by _applyNameMapping() to set display names while preserving raw IDs.
  IncomeModel copyWith({String? cashbox, String? financialCategory}) {
    return IncomeModel(
      id: id,
      date: date,
      cashbox: cashbox ?? this.cashbox,
      financialCategory: financialCategory ?? this.financialCategory,
      nominal: nominal,
      description: description,
      branchId: branchId,
      // Always carry the original IDs forward.
      rawCashboxId: rawCashboxId,
      rawCategoryId: rawCategoryId,
    );
  }
}
