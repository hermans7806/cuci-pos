class ServiceModel {
  final String id;
  final String category;
  final String type; // cuci, kering, setrika, dll
  final String name;
  final int price;
  final int durationDays;
  final String unit; // kg, pcs, dll

  ServiceModel({
    required this.id,
    required this.category,
    required this.type,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.unit,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      durationDays: data['durationDays'] ?? 0,
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'type': type,
      'name': name,
      'price': price,
      'durationDays': durationDays,
      'unit': unit,
    };
  }
}
