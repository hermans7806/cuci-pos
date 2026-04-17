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
  final String dashboardStatus;
  final String? notes;
  final Timestamp createdAt;
  final Timestamp? dueDate;
  final bool isLate;

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
    required this.dashboardStatus,
    this.notes,
    required this.createdAt,
    this.dueDate,
    this.isLate = false,
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
      'dashboardStatus': dashboardStatus,
      'notes': notes,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'isLate': isLate,
    };
  }

  static String mapDashboardStatus(String status) {
    switch (status) {
      case 'new':
        return 'konfirmasi';
      case 'picking-up':
        return 'penjemputan';
      case 'pending':
        return 'antrian';
      case 'washing':
      case 'drying':
      case 'ironing':
        return 'proses';
      case 'packing':
        return 'siap_ambil';
      case 'delivering':
        return 'pengantaran';
      case 'done':
        return 'selesai';
      default:
        return 'unknown';
    }
  }
}
