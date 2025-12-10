class CashboxModel {
  final String id;
  final String name;
  final String branchId;
  final bool isActive;

  CashboxModel({
    required this.id,
    required this.name,
    required this.branchId,
    required this.isActive,
  });

  factory CashboxModel.fromDoc(String id, Map<String, dynamic> data) {
    return CashboxModel(
      id: id,
      name: data['name'] ?? '',
      branchId: data['branchId'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'branchId': branchId,
    'isActive': isActive,
    'createdAt': DateTime.now(),
  };
}
