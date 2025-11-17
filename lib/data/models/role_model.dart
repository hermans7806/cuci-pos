import 'package:cloud_firestore/cloud_firestore.dart';

class RoleModel {
  final String id;
  final String name;
  final String? description;
  final Map<String, bool>? permissions;

  RoleModel({
    required this.id,
    required this.name,
    this.description,
    this.permissions,
  });

  factory RoleModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      permissions: Map<String, bool>.from(data['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'permissions': permissions ?? {},
    };
  }
}
