import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel {
  final String id;
  final String title;
  final String type;
  final double discountRate;
  final DateTime start;
  final DateTime end;
  final bool isActive;
  final bool isAutomatic;
  final String branchId;

  PromoModel({
    required this.id,
    required this.title,
    required this.type,
    required this.discountRate,
    required this.start,
    required this.end,
    required this.isActive,
    required this.isAutomatic,
    required this.branchId,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json, String id) {
    return PromoModel(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? 'percentage',
      discountRate: (json['discountRate'] ?? 0).toDouble(),
      start: (json['start'] as Timestamp).toDate(),
      end: (json['end'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      isAutomatic: json['isAutomatic'] ?? false,
      branchId: json['branchId'] ?? "",
    );
  }
}
