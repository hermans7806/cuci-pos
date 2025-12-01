import 'package:cloud_firestore/cloud_firestore.dart';

import './service_item_model.dart';

class ServiceCategoryModel {
  final String id;
  final String categoryName;
  final List<String> processTypes;
  final String unit;
  final List<ServiceItemModel> items;

  ServiceCategoryModel({
    required this.id,
    required this.categoryName,
    required this.processTypes,
    required this.unit,
    required this.items,
  });

  factory ServiceCategoryModel.fromDoc(
    DocumentSnapshot doc,
    List<ServiceItemModel> items,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceCategoryModel(
      id: doc.id,
      categoryName: data['name'] ?? '',
      processTypes: List<String>.from(data['types'] ?? []),
      unit: data['unit'] ?? 'Satuan', // default
      items: items,
    );
  }

  Map<String, dynamic> toMap() {
    return {"name": categoryName, "types": processTypes, "unit": unit};
  }
}
