import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String displayName;
  final String nickname;
  final String email;
  final String phone;
  final Map<String, dynamic> role;
  final List<String>? branches;

  StaffModel({
    required this.id,
    required this.displayName,
    required this.nickname,
    required this.email,
    required this.phone,
    required this.role,
    this.branches,
  });

  factory StaffModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      nickname: data['nickname'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] is Map ? Map<String, dynamic>.from(data['role']) : {},
      branches: data['branches'] != null && data['branches'] is List<String>
          ? List<String>.from(data['branches'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'nickname': nickname,
      'email': email,
      'phone': phone,
      'role': role,
      'branches': branches,
    };
  }
}
