import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuci_pos/features/settings/controllers/service_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    loadServiceItemsFromCategoryController();
  }

  Future<void> loadServiceItemsFromCategoryController() async {
    final serviceCtrl = Get.find<ServiceController>();

    serviceItems.value = serviceCtrl.getFlatServiceItems();
  }

  Future<void> fetchPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final activeBranchId = prefs.getString('activeBranchId') ?? '';

    if (activeBranchId.isEmpty) {
      packages.clear();
      return;
    }

    final snapshot = await _collection
        .where('branchId', isEqualTo: activeBranchId)
        .get();
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
    final prefs = await SharedPreferences.getInstance();
    final activeBranchId = prefs.getString('activeBranchId') ?? '';

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
      "branchId": activeBranchId,
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
