import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String name;
  final String serviceType; // kiloan | satuan
  final List<String> serviceOptions; // list of service IDs
  final String image;
  final num price;
  final num quota;
  final String description;
  final num validityPeriod;
  final bool accumulateValidity;
  final String branchId;

  PackageModel({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.serviceOptions,
    required this.image,
    required this.price,
    required this.quota,
    required this.description,
    required this.validityPeriod,
    required this.accumulateValidity,
    required this.branchId,
  });

  factory PackageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PackageModel(
      id: doc.id,
      name: data['name'] ?? '',
      serviceType: data['serviceType'] ?? '',
      serviceOptions: data['serviceOptions'] != null
          ? List<String>.from(data['serviceOptions'])
          : <String>[],
      image: data['image'] ?? '',
      price: data['price'] ?? 0,
      quota: data['quota'] ?? 0,
      description: data['description'] ?? '',
      validityPeriod: data['validityPeriod'] ?? 0,
      accumulateValidity: data['accumulateValidity'] ?? false,
      branchId: data['branchId'] ?? "",
    );
  }

  PackageModel copyWith({
    String? id,
    String? name,
    String? serviceType,
    List<String>? serviceOptions,
    String? image,
    double? price,
    int? quota,
    String? description,
    int? validityPeriod,
    bool? accumulateValidity,
    String? branchId,
  }) {
    return PackageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      serviceOptions: serviceOptions ?? this.serviceOptions,
      image: image ?? this.image,
      price: price ?? this.price,
      quota: quota ?? this.quota,
      description: description ?? this.description,
      validityPeriod: validityPeriod ?? this.validityPeriod,
      accumulateValidity: accumulateValidity ?? this.accumulateValidity,
      branchId: branchId ?? this.branchId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "serviceType": serviceType,
      "serviceOptions": serviceOptions,
      "image": image,
      "price": price,
      "quota": quota,
      "description": description,
      "validityPeriod": validityPeriod,
      "accumulateValidity": accumulateValidity,
      "branchId": branchId,
    };
  }
}
