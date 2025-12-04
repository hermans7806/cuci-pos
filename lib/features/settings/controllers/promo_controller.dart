import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/promo_model.dart';

class PromoController extends GetxController {
  RxList<PromoModel> allPromos = <PromoModel>[].obs;
  RxString filter = "active".obs;
  RxString branchId = "".obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadBranch();
    loadPromos();
  }

  Future<void> _loadBranch() async {
    final prefs = await SharedPreferences.getInstance();
    branchId.value = prefs.getString('activeBranchId') ?? "";
  }

  Future<void> loadPromos() async {
    if (branchId.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection("promos")
        .where("branchId", isEqualTo: branchId.value)
        .orderBy("start", descending: true)
        .get();

    allPromos.value = snap.docs
        .map((d) => PromoModel.fromJson(d.data(), d.id))
        .toList();
  }

  List<PromoModel> get filteredPromos {
    switch (filter.value) {
      case "inactive":
        return allPromos.where((p) => p.isActive == false).toList();
      case "all":
        return allPromos;
      default:
        return allPromos.where((p) => p.isActive == true).toList();
    }
  }

  List<PromoModel> get pilihanPromos =>
      filteredPromos.where((p) => p.isAutomatic == false).toList();

  List<PromoModel> get otomatisPromos =>
      filteredPromos.where((p) => p.isAutomatic == true).toList();

  Future<void> deletePromo(String id) async {
    await FirebaseFirestore.instance.collection("promos").doc(id).delete();
  }
}
