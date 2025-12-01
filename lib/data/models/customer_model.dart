class CustomerModel {
  String? id;
  final String name;
  final String phone;
  final String address;

  CustomerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  List<String> generateKeywords() {
    final lower = name.toLowerCase().trim();
    final parts = lower.split(' ').where((e) => e.isNotEmpty).toList();

    final keywords = <String>{};

    // add individual words
    keywords.addAll(parts);

    // add full phrase
    keywords.add(lower);

    // (Optional) add phone number as keyword
    if (phone.trim().isNotEmpty) {
      keywords.add(phone.trim());
    }

    return keywords.toList();
  }

  Map<String, dynamic> toMap() => {
    "name": name,
    "phone": phone,
    "address": address,
    "keywords": generateKeywords(),
  };

  factory CustomerModel.fromDoc(String id, Map<String, dynamic> data) {
    return CustomerModel(
      id: id,
      name: data["name"] ?? "",
      phone: data["phone"] ?? "",
      address: data["address"] ?? "",
    );
  }
}
