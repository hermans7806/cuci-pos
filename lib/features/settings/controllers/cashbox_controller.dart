import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/cashbox_model.dart';
import '../../../data/services/shared_reference.dart';

class CashboxController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<CashboxModel> active = <CashboxModel>[].obs;
  RxList<CashboxModel> inactive = <CashboxModel>[].obs;

  String branchId = '';
  RxBool isLoading = false.obs;

  final predefinedCashboxes = ["BRI", "BCA", "BNI", "MANDIRI", "QRIS", "TUNAI"];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    branchId = await SharedReference.getActiveBranchId();

    /// Fetch active cashboxes only (from Firestore)
    final snap = await _firestore
        .collection("cashboxes")
        .where("branchId", isEqualTo: branchId)
        .get();

    active.value = snap.docs
        .map((e) => CashboxModel.fromDoc(e.id, e.data()))
        .toList();

    /// Determine inactive by comparing predefined vs active names
    final activeNames = active.map((e) => e.name).toSet();

    inactive.value = predefinedCashboxes
        .where((name) => !activeNames.contains(name))
        .map(
          (name) => CashboxModel(
            id: "",
            name: name,
            branchId: branchId,
            isActive: false,
          ),
        )
        .toList();

    isLoading.value = false;
  }

  Future<void> activateCashbox(String name) async {
    final ref = _firestore.collection("cashboxes").doc();

    final data = CashboxModel(
      id: ref.id,
      name: name,
      branchId: branchId,
      isActive: true,
    );

    await ref.set(data.toMap());
    await loadData();
  }

  Future<void> addCustomCashbox(String name) async {
    await activateCashbox(name);
  }

  Future<void> deleteCashbox(String id) async {
    await _firestore.collection("cashboxes").doc(id).delete();
    await loadData();
  }
}
