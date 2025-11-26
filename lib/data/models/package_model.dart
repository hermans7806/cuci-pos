import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final String serviceType; // kiloan | satuan
  final List<String> serviceOption; // list of service IDs
  final String image;
  final num price;
  final num quota;
  final String description;
  final num validityPeriod;
  final bool accumulateValidity;

  PackageModel({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.serviceOption,
    required this.image,
    required this.price,
    required this.quota,
    required this.description,
    required this.validityPeriod,
    required this.accumulateValidity,
  });

  factory PackageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name'] ?? '',
      serviceType: data['serviceType'] ?? '',
      serviceOption: data['serviceOption'] != null
          ? List<String>.from(data['serviceOption'])
          : <String>[],
      image: data['image'] ?? '',
      price: data['price'] ?? 0,
      quota: data['quota'] ?? 0,
      description: data['description'] ?? '',
      validityPeriod: data['validityPeriod'] ?? 0,
      accumulateValidity: data['accumulateValidity'] ?? false,
    );
  }

  PackageModel copyWith({
    String? id,
    String? name,
    String? serviceType,
    List<String>? serviceOption,
    String? image,
    double? price,
    int? quota,
    String? description,
    int? validityPeriod,
    bool? accumulateValidity,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      serviceOption: serviceOption ?? this.serviceOption,
      image: image ?? this.image,
      price: price ?? this.price,
      quota: quota ?? this.quota,
      description: description ?? this.description,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      accumulateValidity: accumulateValidity ?? this.accumulateValidity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "serviceType": serviceType,
      "serviceOption": serviceOption,
      "image": image,
      "price": price,
      "quota": quota,
      "description": description,
      "validityPeriod": validityPeriod,
      "accumulateValidity": accumulateValidity,
    };
  }
}
