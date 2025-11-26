import './service_item_model.dart';

class ServiceCategoryModel {
  final String id;
  final String categoryName;
  final List<String> processTypes;
  final List<ServiceItemModel> items;

  ServiceCategoryModel({
    required this.id,
    required this.categoryName,
    required this.processTypes,
    required this.items,
  });
}
