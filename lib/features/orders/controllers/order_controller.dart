// lib/features/orders/controllers/order_controller.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/top_notification.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/order_picker_item.dart';
import '../../../data/models/promo_model.dart';
import '../../../data/models/selected_service_model.dart';
import '../screens/customer_picker_modal.dart';
import '../screens/service_picker_sheet.dart';

class OrderController extends GetxController {
  var customerName = "".obs;
  var customerPhone = "".obs;
  var customerId = "".obs;
  var perfumeEnabled = false.obs;

  // base total (before promo)
  var totalPrice = 0.0.obs;
  var notes = "".obs;

  final customerCtrl = TextEditingController();

  /// selected promo (nullable)
  final Rxn<PromoModel> selectedPromo = Rxn<PromoModel>();

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
    customerId.value = customer.id ?? '';

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

  // Firestore search using "keywords" array
  Future<void> searchCustomers(String q) async {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final query = q.trim().toLowerCase();
      if (query.length < 3) {
        searchResults.clear();
        isSearching.value = false;
        return;
      }

      try {
        isSearching.value = true;

        final col = FirebaseFirestore.instance.collection('customers');

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

        final filtered = results.where((r) {
          final ln = r.name.toLowerCase();
          return ln.contains(query) || r.phone.contains(query);
        }).toList();

        searchResults.assignAll(filtered);
      } catch (e) {
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
        id: d.id,
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
    applyAutomaticPromo();
  }

  void updateQty(SelectedService s, double newQty) {
    if (newQty <= 0) {
      selectedServices.remove(s);
    } else {
      s.qty = newQty;
    }
    _recalculateTotal();
    selectedServices.refresh();
    applyAutomaticPromo();
  }

  void increaseQty(SelectedService s) {
    s.qty++;
    _recalculateTotal();
    selectedServices.refresh();
    applyAutomaticPromo();
  }

  void decreaseQty(SelectedService s) {
    s.qty = s.qty - 1;
    if (s.qty <= 0) {
      selectedServices.remove(s);
    }
    _recalculateTotal();
    selectedServices.refresh();
    applyAutomaticPromo();
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
  // PROMO / DISCOUNT HELPERS
  // ----------------------

  double get totalBeforePromo => totalPrice.value;

  double get discountAmount {
    final promo = selectedPromo.value;
    if (promo == null) return 0.0;

    final eligibleSubtotal = calculateEligibleSubtotal(promo);

    if (eligibleSubtotal <= 0) return 0.0;

    if (promo.type == 'percentage' || promo.type == 'percent') {
      double disc = eligibleSubtotal * (promo.discountRate / 100);

      if (promo.useMaxDiscount == true && promo.maxDiscount != null) {
        disc = disc.clamp(0, promo.maxDiscount!).toDouble();
      }
      return disc;
    }

    // fixed amount
    return promo.discountRate > eligibleSubtotal
        ? eligibleSubtotal
        : promo.discountRate;
  }

  double get totalAfterPromo =>
      (totalBeforePromo - discountAmount).clamp(0.0, double.infinity);

  void setPromo(PromoModel? promo) {
    selectedPromo.value = promo;
  }

  void clearPromo() => selectedPromo.value = null;

  bool selectedServicesMatchPromo(
    Map<String, dynamic> promoData,
    List<SelectedService> selectedServices,
  ) {
    final rawEligible = promoData['eligibleServices'];
    if (rawEligible == null) return false;

    final eligible = List<Map<String, dynamic>>.from(rawEligible);

    for (final sel in selectedServices) {
      for (final e in eligible) {
        if (sel.id == e['itemId'] && sel.serviceId == e['serviceId']) {
          return true; // at least one item matches
        }
      }
    }

    return false;
  }

  double calculateEligibleSubtotal(PromoModel promo) {
    if (promo.eligibleServices == null || promo.eligibleServices!.isEmpty) {
      return totalBeforePromo; // fallback
    }

    double sum = 0;

    for (final sel in selectedServices) {
      for (final e in promo.eligibleServices!) {
        final promoItemId = e['itemId'];
        final promoServiceId = e['serviceId'];
        if (sel.id == promoItemId && sel.serviceId == promoServiceId) {
          sum += sel.price * sel.qty;
        }
      }
    }

    return sum;
  }

  Future<void> applyAutomaticPromo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeBranchId = prefs.getString('activeBranchId') ?? '';
      if (activeBranchId.isEmpty) return;

      final today = DateTime.now();
      final todayWeekday = DateFormat(
        'EEE',
      ).format(today).toLowerCase(); // 1=Mon ... 7=Sun

      // 1. Fetch automatic promos for this branch
      final snap = await FirebaseFirestore.instance
          .collection('promos')
          .where('branchId', isEqualTo: activeBranchId)
          .where('isAutomatic', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint("No automatic promos available.");
        clearPromo();
        update();
        return;
      }

      PromoModel? foundPromo;
      bool appliedSomething = false;

      for (var doc in snap.docs) {
        final data = doc.data();
        final start = (data['start'] as Timestamp).toDate();
        final end = (data['end'] as Timestamp).toDate();

        // 2. Date range check
        if (today.isBefore(start) || today.isAfter(end)) continue;

        // 3. Day check
        final rawDays = data['days'];
        final List<String> days = rawDays == null
            ? []
            : List<String>.from(rawDays.map((e) => e.toString().toLowerCase()));
        if (days.isNotEmpty && !days.contains(todayWeekday)) {
          continue;
        }

        // 4. Eligibility check by serviceId + itemId
        final selectedIds = selectedServices.map((e) => e.id).toList();
        final matches = selectedServicesMatchPromo(
          data,
          selectedServices.toList(),
        );

        if (!matches) continue;

        // PASS ALL CONDITIONS → promo eligible
        foundPromo = PromoModel.fromFirestore(doc);

        setPromo(foundPromo); // <— proper UI + total update
        _recalculateTotal(); // refresh numbers
        update(); // refresh GetX UI

        appliedSomething = true;
        break;
      }

      // If no promos matched, clear current automatic promo
      if (!appliedSomething) {
        debugPrint("❌ No automatic promo applicable → removing promo");
        clearPromo();
        _recalculateTotal();
        update();
      }
    } catch (e, st) {
      debugPrint("❌ ERROR IN applyAutomaticPromo → $e");
      debugPrint(st.toString());
    }
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

      final promo = selectedPromo.value;
      final promoId = promo?.id;
      final promoRate = promo?.discountRate ?? 0.0;
      final discount = discountAmount;
      final totalBefore = totalBeforePromo;
      final totalFinal = totalAfterPromo;

      final orderData = {
        "customer": {
          "id": customerId.value,
          "name": customerName.value,
          "phone": customerPhone.value,
        },
        "services": servicesData,
        "perfume": perfumeEnabled.value,
        "notes": notes.value,
        "branchId": branchId,
        "branchName": branchName,
        "promoId": promoId,
        "promoRate": promoRate,
        "totalBeforeDiscount": totalBefore,
        "totalDiscount": discount,
        "totalFinal": totalFinal,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Optionally use OrderModel to serialize — here we store as map
      await FirebaseFirestore.instance.collection("orders").add(orderData);

      TopNotification.show(
        title: "Sukses",
        message: "Transaksi berhasil dibuat",
        success: true,
      );

      // clear order
      selectedServices.clear();
      totalPrice.value = 0;
      notes.value = "";
      perfumeEnabled.value = false;
      customerCtrl.clear();
      customerName.value = "";
      customerPhone.value = "";
      customerId.value = "";
      clearPromo();

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

  void togglePerfume(bool value) {
    perfumeEnabled.value = value;
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    customerCtrl.dispose();
    super.onClose();
  }
}
