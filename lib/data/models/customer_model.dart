// lib/data/models/customer_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String nameLower;
  final String branch;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.nameLower,
    required this.branch,
  });

  /// Auto-ID constructor: generates ID using Firestore
  factory CustomerModel.createNew({
    required String name,
    required String phone,
    required String address,
    required String branch,
    required String nameLower,
  }) {
    final newId = FirebaseFirestore.instance.collection("customers").doc().id;

    return CustomerModel(
      id: newId,
      name: name,
      phone: phone,
      address: address,
      nameLower: nameLower,
      branch: branch,
    );
  }

  /// To keep the number of keywords reasonable we:
  ///  - lowercase and trim
  ///  - split into words and generate substrings per word
  ///  - limit substrings length (maxLen) and limit total keywords per name (cap)
  List<String> generateKeywords() {
    final lower = name.toLowerCase().trim();
    final parts = lower
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    final keywords = <String>{};

    const int maxLen = 20; // avoid extremely long substrings
    const int capPerWord = 120; // safety cap per word

    for (var word in parts) {
      final w = word;
      final n = w.length;
      var count = 0;
      for (var start = 0; start < n; start++) {
        for (var end = start + 1; end <= n && (end - start) <= maxLen; end++) {
          keywords.add(w.substring(start, end));
          count++;
          if (count >= capPerWord) break;
        }
        if (count >= capPerWord) break;
      }
      // also include full phrase of joined words
    }

    // also include the full name phrase
    keywords.add(lower);

    // include phone variants (raw and digits-only)
    final phoneTrim = phone.trim();
    if (phoneTrim.isNotEmpty) {
      keywords.add(phoneTrim);
      final digitsOnly = phoneTrim.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isNotEmpty) keywords.add(digitsOnly);
    }

    return keywords.toList();
  }

  Map<String, dynamic> toMap() => {
    "name": name,
    "phone": phone,
    "address": address,
    "nameLower": nameLower,
    "keywords": generateKeywords(),
    'branch': branch,
  };

  factory CustomerModel.fromDoc(String id, Map<String, dynamic> data) {
    return CustomerModel(
      id: id,
      name: data["name"] ?? "",
      phone: data["phone"] ?? "",
      address: data["address"] ?? "",
      nameLower: data["nameLower"] ?? "",
      branch: data['branch'] ?? '',
    );
  }
}
