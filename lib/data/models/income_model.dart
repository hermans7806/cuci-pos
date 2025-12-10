import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String id;
  final DateTime date;
  final String cashbox;
  final String financialCategory;
  final double nominal;
  final String description;
  final String branchId;

  IncomeModel({
    required this.id,
    required this.date,
    required this.cashbox,
    required this.financialCategory,
    required this.nominal,
    required this.description,
    required this.branchId,
  });

  factory IncomeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return IncomeModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      cashbox: data['cashbox'] ?? '',
      financialCategory: data['financialCategory'] ?? '',
      nominal: (data['nominal'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      branchId: data['branchId'] ?? '',
    );
  }
}
