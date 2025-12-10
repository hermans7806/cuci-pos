import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/services/shared_reference.dart';

class CustomerController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<CustomerModel> customers = <CustomerModel>[].obs;
  RxBool isLoading = false.obs;
  RxBool isMoreLoading = false.obs;

  DocumentSnapshot? lastDoc;
  final int limit = 15;

  RxBool isMore = true.obs;
  RxString searchQuery = ''.obs;

  String activeBranchId = '';

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    activeBranchId = await SharedReference.getActiveBranchId();
    fetchInitial();
  }

  /// Reset list and fetch again
  Future<void> fetchInitial() async {
    isLoading.value = true;
    lastDoc = null;
    customers.clear();
    isMore.value = true;

    await fetchMore();

    isLoading.value = false;
  }

  /// 🔍 Search customers
  void search(String query) {
    searchQuery.value = query.toLowerCase().trim();

    customers.clear();
    lastDoc = null;
    isMore.value = true;

    fetchMore();
  }

  /// Pagination + Search support
  Future<void> fetchMore() async {
    if (!isMore.value || isMoreLoading.value) return;

    isMoreLoading.value = true;

    Query query = _firestore
        .collection('customers')
        .where('branch', isEqualTo: activeBranchId)
        .orderBy('nameLower')
        .limit(limit);

    // 🔍 If searching, apply search filter using keywords
    if (searchQuery.value.isNotEmpty) {
      query = _firestore
          .collection('customers')
          .where('branch', isEqualTo: activeBranchId)
          .where('keywords', arrayContains: searchQuery.value)
          .limit(limit);
    }

    // Pagination
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      lastDoc = snapshot.docs.last;
      customers.addAll(
        snapshot.docs.map(
          (e) => CustomerModel.fromDoc(e.id, e.data() as Map<String, dynamic>),
        ),
      );
    }

    if (snapshot.docs.length < limit) {
      isMore.value = false;
    }

    isMoreLoading.value = false;
  }

  /// Save / Update
  Future<void> saveCustomer(CustomerModel c) async {
    await _firestore.collection('customers').doc(c.id).set(c.toMap());
    fetchInitial();
  }

  /// Delete
  Future<void> deleteCustomer(String id) async {
    await _firestore.collection('customers').doc(id).delete();
    fetchInitial();
  }
}
