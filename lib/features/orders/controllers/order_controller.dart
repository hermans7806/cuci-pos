import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/utils/top_notification.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/selected_service_model.dart';
import '../screens/customer_picker_modal.dart';
import '../screens/service_picker_sheet.dart';

class OrderController extends GetxController {
  var customerName = "".obs;
  var customerPhone = "".obs;

  var totalPrice = 0.0.obs;
  var notes = "".obs;

  final customerCtrl = TextEditingController();

  /// ⬇ List of services selected from ServicePickerSheet
  RxList<SelectedService> selectedServices = <SelectedService>[].obs;

  bool get isValidOrder => customerName.isNotEmpty;

  void setSelectedCustomer(CustomerModel customer) {
    customerName.value = customer.name;
    customerPhone.value = customer.phone;

    customerCtrl.text = "${customer.name} - ${customer.phone}";
  }

  // ---------------------------
  //  CONTACT PICKER FUNCTIONS
  // ---------------------------

  Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) return true;
    final result = await Permission.contacts.request();
    return result.isGranted;
  }

  Future<List<PickerItem>> fetchFirestoreCustomers(
    int page,
    String? search,
  ) async {
    final col = FirebaseFirestore.instance.collection('customers');

    Query query = col.orderBy('nameLower').limit(20);

    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      query = col
          .orderBy('nameLower')
          .startAt([s])
          .endAt([s + '\uf8ff'])
          .limit(20);
    }

    final snap = await query.get();

    final results = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return PickerItem(name: data['name'] ?? '', phone: data['phone'] ?? '');
    }).toList();

    if (search != null && search.isNotEmpty) {
      return results
          .where(
            (i) =>
                i.name.toLowerCase().contains(search.toLowerCase()) ||
                i.phone.contains(search),
          )
          .toList();
    }

    return results;
  }

  void pickExistingCustomer() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerPickerModal(
        fetchItems: fetchFirestoreCustomers,
        onSelected: (item) {
          customerCtrl.text = "${item.name} - ${item.phone}";
          customerName.value = item.name;
          customerPhone.value = item.phone;
        },
      ),
    );
  }

  Future<List<PickerItem>> fetchPhoneContacts(int page, String? search) async {
    final contacts = await FastContacts.getAllContacts();

    final filtered = contacts.where((c) {
      final name = c.displayName.toLowerCase();
      if (search == null || search.isEmpty) return true;
      return name.contains(search.toLowerCase());
    }).toList();

    final start = page * 20;
    final end = start + 20;

    if (start >= filtered.length) return [];

    final slice = filtered.sublist(
      start,
      end > filtered.length ? filtered.length : end,
    );

    return slice.map((c) {
      final phone = c.phones.isNotEmpty ? c.phones.first.number : '';
      return PickerItem(name: c.displayName, phone: phone);
    }).toList();
  }

  void pickFromPhoneContacts() async {
    final allowed = await requestContactPermission();
    if (!allowed) {
      Get.snackbar(
        "Izin Ditolak",
        "Aplikasi butuh akses kontak",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerPickerModal(
        fetchItems: fetchPhoneContacts,
        onSelected: (item) {
          customerCtrl.text = "${item.name} - ${item.phone}";
          customerName.value = item.name;
          customerPhone.value = item.phone;
        },
      ),
    );
  }

  // ----------------------
  // SERVICE PICKER
  // ----------------------

  void openAddServiceBottomSheet() {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => ServicePickerSheet(
        onAdd: (selectedService) {
          addService(selectedService);
        },
      ),
    );
  }

  void addService(SelectedService item) {
    final exist = selectedServices.firstWhereOrNull((s) => s.id == item.id);

    if (exist != null) {
      exist.qty++;
    } else {
      selectedServices.add(item);
    }

    _recalculateTotal();
    selectedServices.refresh();
  }

  void updateQty(SelectedService s, double newQty) {
    if (newQty <= 0) {
      selectedServices.remove(s);
    } else {
      s.qty = newQty;
    }
    _recalculateTotal();
    selectedServices.refresh();
  }

  void increaseQty(SelectedService s) {
    s.qty++;
    _recalculateTotal();
    selectedServices.refresh();
  }

  void decreaseQty(SelectedService s) {
    s.qty = s.qty - 1;
    if (s.qty <= 0) {
      selectedServices.remove(s);
    }
    _recalculateTotal();
    selectedServices.refresh();
  }

  void removeService(SelectedService s) {
    selectedServices.remove(s);
    _recalculateTotal();
  }

  void _recalculateTotal() {
    totalPrice.value = selectedServices.fold(
      0.0,
      (sum, item) => sum + (item.price * item.qty),
    );
  }

  // ----------------------
  // SUBMIT
  // ----------------------

  void submitOrder() {
    TopNotification.show(
      title: "Sukses",
      message: "Transaksi berhasil dibuat",
      success: true,
    );
  }
}
