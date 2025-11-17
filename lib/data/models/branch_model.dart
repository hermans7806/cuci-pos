import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
  });

  factory BranchModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BranchModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address, 'phone': phone};
  }
}
