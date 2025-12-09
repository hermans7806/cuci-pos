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
  final List<String> days;
  final String? conditionType;
  final num? conditionValue;
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

  /// -----------------------------
  /// fromJson (safe parser)
  /// -----------------------------
  factory PromoModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    /// Parse eligibleServices (List<Map<String,String>>)
    final rawEligible = json['eligibleServices'];
    List<Map<String, String>> eligible = [];

    if (rawEligible is List) {
      for (var el in rawEligible) {
        if (el is Map) {
          eligible.add({
            'serviceId': (el['serviceId'] ?? '').toString(),
            'itemId': (el['itemId'] ?? '').toString(),
          });
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
          ? List<String>.from(json['days'] as List)
          : <String>[],
      conditionType: json['conditionType'],
      conditionValue: json['conditionValue'],
      useMaxDiscount: json['useMaxDiscount'] ?? false,
      maxDiscount: json['maxDiscount'],
      eligibleServices: eligible,
    );
  }

  /// -----------------------------
  /// Firestore encoder
  /// -----------------------------
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

  /// -----------------------------
  /// fromFirestore (the FIXED version!)
  /// -----------------------------
  factory PromoModel.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;

    /// Parse eligibleServices correctly
    final rawEligible = json['eligibleServices'];
    List<Map<String, String>> eligible = [];

    if (rawEligible is List) {
      for (var el in rawEligible) {
        if (el is Map) {
          eligible.add({
            'serviceId': (el['serviceId'] ?? '').toString(),
            'itemId': (el['itemId'] ?? '').toString(),
          });
        }
      }
    }

    /// Safe days list
    final parsedDays = json['days'] != null
        ? List<String>.from(json['days'] as List)
        : <String>[];

    return PromoModel(
      id: doc.id,
      title: json['title'] ?? '',
      type: json['type'] ?? 'percentage',
      discountRate: (json['discountRate'] ?? 0).toDouble(),
      start: (json['start'] as Timestamp).toDate(),
      end: (json['end'] as Timestamp).toDate(),
      isAutomatic: json['isAutomatic'] ?? false,
      isActive: json['isActive'] ?? true,
      branchId: json['branchId'] ?? '',
      days: parsedDays,
      conditionType: json['conditionType'],
      conditionValue: json['conditionValue'],
      useMaxDiscount: json['useMaxDiscount'] ?? false,
      maxDiscount: json['maxDiscount'],
      eligibleServices: eligible,
    );
  }
}
