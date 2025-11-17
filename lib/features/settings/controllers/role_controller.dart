import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../data/models/role_model.dart';

class RoleController extends GetxController {
  final roles = <RoleModel>[].obs;

  final _collection = FirebaseFirestore.instance.collection('roles');

  @override
  void onInit() {
    super.onInit();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    final snapshot = await _collection.get();
    roles.value = snapshot.docs.map((doc) => RoleModel.fromDoc(doc)).toList();
  }

  Future<void> createRole(RoleModel role) async {
    await _collection.doc(role.id).set(role.toMap());
    fetchRoles();
  }

  Future<void> updateRole(RoleModel role) async {
    await _collection.doc(role.id).update(role.toMap());
    fetchRoles();
  }

  Future<void> deleteRole(String id) async {
    await _collection.doc(id).delete();
    fetchRoles();
  }
}
