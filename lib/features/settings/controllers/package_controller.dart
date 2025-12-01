import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/package_model.dart';

class PackageController extends GetxController {
  final _collection = FirebaseFirestore.instance.collection('packages');
  final serviceItems = <Map<String, dynamic>>[].obs;
  final packages = <PackageModel>[].obs;
  final isServiceExpanded = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
    fetchServiceItems();
  }

  Future<void> fetchServiceItems() async {
    final servicesCol = FirebaseFirestore.instance.collection('services');
    final servicesSnapshot = await servicesCol.get();

    List<Map<String, dynamic>> results = [];

    for (var serviceDoc in servicesSnapshot.docs) {
      final categoryUnit = serviceDoc['unit'] ?? '';
      final itemsSnap = await serviceDoc.reference.collection('items').get();

      for (var item in itemsSnap.docs) {
        results.add({
          "id": item.id,
          "serviceId": serviceDoc.id,
          "name": item['name'] ?? '',
          "unit": categoryUnit.toLowerCase(),
        });
      }
    }

    serviceItems.value = results;
  }

  Future<void> fetchPackages() async {
    final snapshot = await _collection.get();
    packages.value = snapshot.docs.map((d) => PackageModel.fromDoc(d)).toList();
  }

  Future<void> addPackage({
    required String name,
    required String serviceType,
    required double price,
    required int quota,
    required String description,
    required int validityPeriod,
    required bool accumulateValidity,
    required List<String> serviceOptions,
  }) async {
    final docRef = _collection.doc(); // auto ID

    await docRef.set({
      "id": docRef.id,
      "name": name,
      "serviceType": serviceType,
      "price": price,
      "quota": quota,
      "description": description,
      "validityPeriod": validityPeriod,
      "accumulateValidity": accumulateValidity,
      "serviceOptions": serviceOptions,
      "image": "",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    fetchPackages();
  }

  Future<void> updatePackage(PackageModel model) async {
    await _collection.doc(model.id).update(model.toMap());
    fetchPackages();
  }

  Future<void> deletePackage(String id) async {
    await _collection.doc(id).delete();
    fetchPackages();
  }
}
