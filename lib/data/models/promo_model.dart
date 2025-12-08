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
  final List<String> days; // ["mon","tue",...]
  final String? conditionType; // "minQty" | "minTotal" or null
  final num? conditionValue; // value for the condition
  final bool useMaxDiscount;
  final num? maxDiscount;
  final List<Map<String, String>> eligibleServices;

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
    required this.days,
    this.conditionType,
    this.conditionValue,
    required this.useMaxDiscount,
    this.maxDiscount,
    required this.eligibleServices,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    final rawEligible = json['eligibleServices'];
    List<Map<String, String>> eligible = [];
    if (rawEligible is List) {
      for (var el in rawEligible) {
        if (el is Map) {
          final sId = (el['serviceId'] ?? '').toString();
          final iId = (el['itemId'] ?? '').toString();
          if (sId.isNotEmpty && iId.isNotEmpty) {
            eligible.add({'serviceId': sId, 'itemId': iId});
          }
        }
      }
    }

    return PromoModel(
      id: id,
      title: json['title'] ?? '',
      type: json['type'] ?? 'percentage',
      discountRate: (json['discountRate'] ?? 0).toDouble(),
      start: parseTs(json['start']),
      end: parseTs(json['end']),
      isActive: json['isActive'] ?? true,
      isAutomatic: json['isAutomatic'] ?? false,
      branchId: json['branchId'] ?? "",
      days: json['days'] != null
          ? List<String>.from(json['days'] as List<dynamic>)
          : <String>[],
      conditionType: json['conditionType'] != null
          ? json['conditionType'] as String
          : null,
      conditionValue: json['conditionValue'],
      useMaxDiscount: json['useMaxDiscount'] ?? false,
      maxDiscount: json['maxDiscount'],
      eligibleServices: eligible,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'discountRate': discountRate,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'isActive': isActive,
      'isAutomatic': isAutomatic,
      'branchId': branchId,
      'days': days,
      'conditionType': conditionType,
      'conditionValue': conditionValue,
      'useMaxDiscount': useMaxDiscount,
      'maxDiscount': maxDiscount,
      'eligibleServices': eligibleServices,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
