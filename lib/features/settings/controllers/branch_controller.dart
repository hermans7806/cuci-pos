import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/branch_model.dart';

class BranchController extends GetxController {
  final branches = <BranchModel>[].obs;
  final _collection = FirebaseFirestore.instance.collection('branches');

  @override
  void onInit() {
    super.onInit();
    fetchBranches();
  }

  Future<void> fetchBranches() async {
    final snapshot = await _collection.get();
    branches.value = snapshot.docs
        .map((doc) => BranchModel.fromDoc(doc))
        .toList();
  }

  Future<void> addBranch(BranchModel branch) async {
    final docRef = _collection.doc(); // auto-generate ID

    await docRef.set({
      ...branch.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    fetchBranches();
  }

  Future<void> updateBranch(BranchModel branch) async {
    await _collection.doc(branch.id).update({
      ...branch.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    fetchBranches();
  }

  Future<void> deleteBranch(String id) async {
    await _collection.doc(id).delete();
    fetchBranches();
  }
}
