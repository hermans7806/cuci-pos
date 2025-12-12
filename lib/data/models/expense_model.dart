import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final DateTime date;
  final String cashbox;
  final String financialCategory;
  final double nominal;
  final String description;
  final String branchId;

  ExpenseModel({
    required this.id,
    required this.date,
    required this.cashbox,
    required this.financialCategory,
    required this.nominal,
    required this.description,
    required this.branchId,
  });

  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExpenseModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      cashbox: data['cashbox'] ?? '',
      financialCategory: data['financialCategory'] ?? '',
      nominal: (data['nominal'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      branchId: data['branchId'] ?? '',
    );
  }

  factory ExpenseModel.fromMap(String id, Map<String, dynamic> data) {
    return ExpenseModel(
      id: id,
      date: (data["date"] as Timestamp).toDate(),
      cashbox: data["cashbox"],
      financialCategory: data["financialCategory"],
      nominal: (data["nominal"] ?? 0).toDouble(),
      description: data["description"] ?? "",
      branchId: data['branchId'] ?? '',
    );
  }

  ExpenseModel copyWith({String? cashbox, String? financialCategory}) {
    return ExpenseModel(
      id: id,
      date: date,
      cashbox: cashbox ?? this.cashbox,
      financialCategory: financialCategory ?? this.financialCategory,
      nominal: nominal,
      description: description,
      branchId: branchId,
    );
  }
}
