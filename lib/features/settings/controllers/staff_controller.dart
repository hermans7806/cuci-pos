import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/staff_model.dart';

class StaffController extends GetxController {
  final staffs = <StaffModel>[].obs;

  final _usersCollection = FirebaseFirestore.instance.collection('users');
  final _rolesCollection = FirebaseFirestore.instance.collection('roles');
  final _branchesCollection = FirebaseFirestore.instance.collection('branches');

  final roles = <Map<String, dynamic>>[].obs;
  final branches = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchStaffs();
    fetchRoles();
    fetchBranches();
  }

  Future<void> fetchStaffs() async {
    final snapshot = await _usersCollection.get();
    staffs.value = snapshot.docs.map((d) => StaffModel.fromDoc(d)).toList();
  }

  Future<void> fetchRoles() async {
    final snapshot = await _rolesCollection.get();

    roles.value = snapshot.docs.map((d) {
      return {
        "id": d.id, // e.g. "kasir"
        "name": d["name"], // e.g. "Kasir"
        "raw": d.data(), // optional full data if needed later
      };
    }).toList();
  }

  Future<void> fetchBranches() async {
    final snapshot = await _branchesCollection.get();
    branches.value = snapshot.docs.map((d) {
      return {"id": d.id, "name": d["name"]};
    }).toList();
  }

  // CREATE STAFF (Firestore + password creation)
  Future<void> addStaff({
    required String displayName,
    required String nickname,
    required String email,
    required String phone,
    required Map<String, dynamic> role,
    required List<String> branches,
    required String password,
  }) async {
    final docRef = _usersCollection.doc();

    final roleMap = {role["id"]: role["name"]};

    await docRef.set({
      "displayName": displayName,
      "nickname": nickname,
      "email": email,
      "phone": phone,
      "role": roleMap,
      "branches": branches,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // You will call Cloud Function to create the auth user
    // await createAuthAccount(email, password);

    fetchStaffs();
  }

  Future<void> updateStaff(StaffModel staff) async {
    await _usersCollection.doc(staff.id).update({
      ...staff.toMap(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    fetchStaffs();
  }

  Future<void> deleteStaff(String id) async {
    await _usersCollection.doc(id).delete();
    fetchStaffs();
  }
}
