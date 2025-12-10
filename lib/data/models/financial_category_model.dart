// lib/data/models/financial_category_model.dart
class FinancialCategory {
  final String id;
  final String name;
  final String category; // "pendapatan" or "pengeluaran"
  final String branchId;

  FinancialCategory({
    required this.id,
    required this.name,
    required this.category,
    required this.branchId,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'branchId': branchId,
    'createdAt': DateTime.now(),
  };

  factory FinancialCategory.fromDoc(String id, Map<String, dynamic> d) {
    return FinancialCategory(
      id: id,
      name: d['name'] ?? '',
      category: d['category'] ?? '',
      branchId: d['branchId'] ?? '',
    );
  }

  factory FinancialCategory.fromFirestore(doc) {
    final d = doc.data();
    return FinancialCategory(
      id: doc.id,
      name: d["name"] ?? "",
      category: d["category"] ?? "",
      branchId: d['branchId'] ?? "",
    );
  }
}
