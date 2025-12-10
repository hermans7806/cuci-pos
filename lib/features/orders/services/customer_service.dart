import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/customer_model.dart';

class CustomerService {
  static final col = FirebaseFirestore.instance.collection("customers");

  static Future<CustomerModel> saveCustomer(CustomerModel model) async {
    final data = model.toMap(); // includes keywords
    final doc = await col.add(data);

    return model;
  }

  static Stream<List<CustomerModel>> searchCustomers(String query) {
    if (query.length < 3) {
      // return empty stream
      return Stream.value([]);
    }

    return col
        .where("keywords", arrayContains: query.toLowerCase())
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CustomerModel.fromDoc(d.id, d.data()))
              .toList(),
        );
  }
}
