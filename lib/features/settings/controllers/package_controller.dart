import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/package_model.dart';

class PackageController extends GetxController {
  final _collection = FirebaseFirestore.instance.collection('package');

  final packages = <PackageModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPackages();
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
      "serviceOption": [],
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
