import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../controllers/customer_controller.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      nameCtrl.text = widget.customer!.name;
      phoneCtrl.text = widget.customer!.phone;
      addressCtrl.text = widget.customer!.address;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              /// NAME
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),

              /// PHONE
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Phone required' : null,
              ),
              const SizedBox(height: 16),

              /// ADDRESS
              TextFormField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Address required' : null,
              ),

              const Spacer(),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final name = nameCtrl.text.trim();
                    final phone = phoneCtrl.text.trim();
                    final address = addressCtrl.text.trim();

                    /// UPDATE existing customer
                    if (widget.customer != null) {
                      final updated = CustomerModel(
                        id: widget.customer!.id,
                        name: name,
                        phone: phone,
                        address: address,
                        nameLower: name.toLowerCase(),
                        branch: widget.customer!.branch,
                      );

                      await controller.saveCustomer(updated);
                      Get.back();
                      return;
                    }

                    /// CREATE new customer using createNew()
                    final newCustomer = CustomerModel.createNew(
                      name: name,
                      phone: phone,
                      address: address,
                      branch: controller.activeBranchId,
                      nameLower: name.toLowerCase(),
                    );

                    await controller.saveCustomer(newCustomer);
                    Get.back();
                  },
                  child: Text(
                    widget.customer == null
                        ? 'Save Customer'
                        : 'Update Customer',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
