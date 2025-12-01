import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItemModel {
  final String id;
  final String name;
  final num price;
  final int durationHours; // stored as hours
  final String notes;

  ServiceItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationHours,
    required this.notes,
  });

  factory ServiceItemModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ServiceItemModel(
      id: doc.id,
      name: d['name'] ?? '',
      price: d['price'] ?? 0,
      durationHours: d['durationHours'] ?? 0,
      notes: d['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'durationHours': durationHours,
      'notes': notes,
    };
  }
}
