import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final Map<String, dynamic> customer;
  final List<Map<String, dynamic>> services;
  final String branchId;
  final String branchName;
  final String? promoId;
  final double promoRate;
  final double totalBeforeDiscount;
  final double totalDiscount;
  final double totalFinal;
  final String status;
  final String? notes;
  final Timestamp createdAt;

  OrderModel({
    this.id,
    required this.customer,
    required this.services,
    required this.branchId,
    required this.branchName,
    this.promoId,
    required this.promoRate,
    required this.totalBeforeDiscount,
    required this.totalDiscount,
    required this.totalFinal,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customer': customer,
      'services': services,
      'branchId': branchId,
      'branchName': branchName,
      'promoId': promoId,
      'promoRate': promoRate,
      'totalBeforeDiscount': totalBeforeDiscount,
      'totalDiscount': totalDiscount,
      'totalFinal': totalFinal,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
    };
  }
}
