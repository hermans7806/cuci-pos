// lib/features/orders/controllers/order_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/top_notification.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/selected_service_model.dart';
import '../screens/customer_picker_modal.dart';
import '../screens/service_picker_sheet.dart';

class OrderController extends GetxController {
  var customerName = "".obs;
  var customerPhone = "".obs;
  var customerId = "".obs;

  var totalPrice = 0.0.obs;
  var notes = "".obs;

  final customerCtrl = TextEditingController();

  /// ⬇ List of services selected from ServicePickerSheet
  RxList<SelectedService> selectedServices = <SelectedService>[].obs;

  /// Live search results for the "Nama Pelanggan" field
  final RxList<PickerItem> searchResults = <PickerItem>[].obs;
  final isSearching = false.obs;

  Timer? _searchDebounce;

  bool get isValidOrder => customerName.isNotEmpty;

  void setSelectedCustomer(CustomerModel customer) {
    customerName.value = customer.name;
    customerPhone.value = customer.phone;
    customerId.value = customer.id!;

    customerCtrl.text = "${customer.name} - ${customer.phone}";
    // clear any search results shown
    searchResults.clear();
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

  // Firestore search using "keywords" array (Option B)
  Future<void> searchCustomers(String q) async {
    // Debounce: cancel previous timer and schedule
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      // only search when q length >= 3
      final query = q.trim().toLowerCase();
      if (query.length < 3) {
        searchResults.clear();
        isSearching.value = false;
        return;
      }

      try {
        isSearching.value = true;

        final col = FirebaseFirestore.instance.collection('customers');

        // Use arrayContains on keywords. Limit to 30 results.
        final snap = await col
            .where('keywords', arrayContains: query)
            .orderBy('nameLower', descending: false)
            .limit(30)
            .get();

        final results = snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          return PickerItem(id: d.id, name: name, phone: phone);
        }).toList();

        // As an extra safeguard, also filter locally to ensure "contains"
        final filtered = results.where((r) {
          final ln = r.name.toLowerCase();
          return ln.contains(query) || r.phone.contains(query);
        }).toList();

        searchResults.assignAll(filtered);
      } catch (e) {
        // ignore / show snackbar optionally
        debugPrint('searchCustomers error: $e');
        searchResults.clear();
      } finally {
        isSearching.value = false;
      }
    });
  }

  Future<List<PickerItem>> fetchFirestoreCustomers(
    int page,
    String? search,
  ) async {
    // This method kept for CustomerPickerModal usage (paginated modal)
    final col = FirebaseFirestore.instance.collection('customers');

    Query query = col.orderBy('nameLower').limit(20);

    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      query = col
          .where('keywords', arrayContains: s)
          .orderBy('nameLower')
          .limit(20);
    }

    final snap = await query.get();

    final results = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return PickerItem(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
      );
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
          customerId.value = item.id;
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
      return PickerItem(id: c.id, name: c.displayName, phone: phone);
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

  Future<void> submitOrder() async {
    if (customerName.isEmpty) {
      TopNotification.show(
        title: "Gagal",
        message: "Nama pelanggan belum diisi",
        success: false,
      );
      return;
    }

    if (selectedServices.isEmpty) {
      TopNotification.show(
        title: "Gagal",
        message: "Pilih minimal 1 layanan",
        success: false,
      );
      return;
    }

    try {
      // Load branch from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final branchId = prefs.getString('activeBranchId') ?? "";
      final branchName = prefs.getString('activeBranchName') ?? "";

      // Build service list
      final servicesData = selectedServices.map((s) {
        return {
          "id": s.id,
          "name": s.name,
          "price": s.price,
          "qty": s.qty,
          "duration": s.duration,
          "subtotal": s.price * s.qty,
        };
      }).toList();

      final totalBefore = totalPrice.value;

      // prepare for promo integration
      final promoId = null;
      final discountRate = 0.0;
      final discountAmount = totalBefore * discountRate;
      final totalFinal = totalBefore - discountAmount;

      final data = {
        "customer": {
          "id": customerId.value,
          "name": customerName.value,
          "phone": customerPhone.value,
        },

        "services": servicesData,
        "notes": notes.value,

        "branchId": branchId,
        "branchName": branchName,

        "promoId": promoId,
        "discountRate": discountRate,

        "totalBeforeDiscount": totalBefore,
        "totalDiscount": discountAmount,
        "totalFinal": totalFinal,

        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection("orders").add(data);

      TopNotification.show(
        title: "Sukses",
        message: "Transaksi berhasil dibuat",
        success: true,
      );

      // clear order
      selectedServices.clear();
      totalPrice.value = 0;
      notes.value = "";
      customerCtrl.clear();
      customerName.value = "";
      customerPhone.value = "";

      // close screen
      Get.back();
    } catch (e) {
      TopNotification.show(
        title: "Gagal",
        message: "Terjadi kesalahan saat membuat transaksi",
        success: false,
      );
      debugPrint("submitOrder error: $e");
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    customerCtrl.dispose();
    super.onClose();
  }
}
