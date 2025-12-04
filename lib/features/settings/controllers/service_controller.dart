import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/top_notification.dart';
import '../../../data/models/service_category_model.dart';
import '../../../data/models/service_item_model.dart';

class ServiceController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final categories = <ServiceCategoryModel>[].obs;
  final isLoading = false.obs;
  final categoryUnit = "Satuan".obs;

  // TEMP in-memory buffer for items when creating a new category
  final tempItems = <ServiceItemModel>[].obs;
  bool initializedForAdd = false;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  /// Add item into memory buffer only
  void addTempItem(ServiceItemModel item) {
    tempItems.add(item);
  }

  void removeTempItem(String id) {
    tempItems.removeWhere((e) => e.id == id);
  }

  void clearTemp() {
    tempItems.clear();
  }

  /// Persist category and its items to Firestore in bulk
  /// categoryDoc data example: { 'name': 'CATEGORY A', 'types': ['cuci','kering'] }
  Future<void> saveCategoryWithItems({
    required String categoryName,
    required List<String> types,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getString('activeBranchId') ?? '';

    if (categoryName.isEmpty) throw Exception("Category name required");
    if (types.isEmpty) throw Exception("Select at least one process type");
    if (branchId.isEmpty) throw Exception("Branch ID missing");

    final catRef = _db.collection('services').doc();
    final batch = _db.batch();

    batch.set(catRef, {
      "name": categoryName,
      "types": types,
      "unit": categoryUnit.value,
      "branchId": branchId,
      "createdAt": FieldValue.serverTimestamp(),
    });

    for (var item in tempItems) {
      final itemRef = catRef.collection("items").doc();
      batch.set(itemRef, item.toMap());
    }

    await batch.commit();

    clearTemp();
    fetchCategories();
  }

  Future<void> updateCategoryWithItems({
    required String categoryId,
    required String categoryName,
    required List<String> types,
    required List<ServiceItemModel> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final branchId = prefs.getString('activeBranchId') ?? '';

    final catRef = _db.collection('services').doc(categoryId);
    final batch = _db.batch();

    // Update category data
    batch.update(catRef, {
      "name": categoryName,
      "types": types,
      "unit": categoryUnit.value,
      "branchId": branchId,
    });

    // Delete old items
    final oldItems = await catRef.collection("items").get();
    for (var doc in oldItems.docs) {
      batch.delete(doc.reference);
    }

    // Insert new items
    for (var item in items) {
      final newRef = catRef
          .collection("items")
          .doc(item.id.isEmpty ? null : item.id);
      batch.set(newRef, item.toMap());
    }

    await batch.commit();
    await fetchCategories();
  }

  /// Optional: fetch categories with their items (not required by your current screen)
  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeBranchId = prefs.getString('activeBranchId') ?? '';

      if (activeBranchId.isEmpty) {
        categories.value = [];
        return;
      }

      final snap = await _db
          .collection('services')
          .where('branchId', isEqualTo: activeBranchId)
          .get();

      final list = <ServiceCategoryModel>[];

      for (var doc in snap.docs) {
        final data = doc.data();

        // fetch items
        final itemsSnap = await doc.reference.collection('items').get();

        final items = itemsSnap.docs
            .map((d) => ServiceItemModel.fromDoc(d))
            .toList();

        list.add(
          ServiceCategoryModel(
            id: doc.id,
            categoryName: data['name'] ?? '',
            processTypes: List<String>.from(data['types'] ?? []),
            unit: data['unit'] ?? '',
            branchId: data['branchId'] ?? '',
            items: items,
          ),
        );
      }

      categories.value = list;
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> getFlatServiceItems() {
    final flat = <Map<String, dynamic>>[];

    for (final cat in categories) {
      for (final item in cat.items) {
        flat.add({
          "id": item.id,
          "name": item.name,
          "unit": cat.unit.toLowerCase(),
          "serviceId": cat.id,
        });
      }
    }

    return flat;
  }

  // Delete item
  Future<void> deleteServiceItem(String categoryId, String itemId) async {
    await _db
        .collection('services')
        .doc(categoryId)
        .collection('items')
        .doc(itemId)
        .delete();

    fetchCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      final catRef = _db.collection('services').doc(categoryId);

      // Fetch items inside the category
      final itemsSnap = await catRef.collection("items").get();

      // Use batch to delete everything safely
      final batch = _db.batch();

      // delete each item
      for (var doc in itemsSnap.docs) {
        batch.delete(doc.reference);
      }

      // delete the category itself
      batch.delete(catRef);

      await batch.commit();

      // refresh UI
      await fetchCategories();
    } catch (e) {
      TopNotification.show(
        title: "Error",
        message: "Error deleting category: $e",
        success: true,
      );
      rethrow;
    }
  }
}
