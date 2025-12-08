// lib/features/promos/screens/add_promo_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/promo_model.dart';
import '../../profile/controllers/profile_controller.dart';

class _ServiceItem {
  final String id;
  final String name;
  final num price;
  final num durationHours;
  _ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.durationHours,
  });
}

class _ServiceWithItems {
  final String serviceId;
  final String name;
  final String unit;
  final List<_ServiceItem> items;
  _ServiceWithItems({
    required this.serviceId,
    required this.name,
    required this.unit,
    required this.items,
  });
}

class AddPromoScreen extends StatefulWidget {
  final PromoModel? promo; // editing if provided

  const AddPromoScreen({super.key, this.promo});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  final titleCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final conditionValueCtrl = TextEditingController();
  final maxDiscountCtrl = TextEditingController();

  // "percentage" or "fixed"
  String type = "percentage";
  bool isAutomatic = false;
  DateTime? start;
  DateTime? end;

  // automatic fields
  List<String> days = []; // "mon", "tue", ...
  String? conditionType; // "minQty" | "minTotal"
  bool useMaxDiscount = false;

  // eligible services selection keyed by "serviceId|itemId"
  final Set<String> selectedEligibility = <String>{};

  // services loaded from firestore for the branch
  List<_ServiceWithItems> services = [];

  // editing
  bool get editing => widget.promo != null;
  bool isActive = true;

  final dayOptions = const [
    ['mon', 'Senin'],
    ['tue', 'Selasa'],
    ['wed', 'Rabu'],
    ['thu', 'Kamis'],
    ['fri', 'Jumat'],
    ['sat', 'Sabtu'],
    ['sun', 'Minggu'],
  ];

  String branchId = "";

  @override
  void initState() {
    super.initState();
    if (editing) _loadFromPromo(widget.promo!);
    _loadBranchAndServices();
  }

  void _loadFromPromo(PromoModel p) {
    titleCtrl.text = p.title;
    rateCtrl.text = p.discountRate.toString();
    type = p.type;
    isAutomatic = p.isAutomatic;
    start = p.start;
    end = p.end;
    isActive = p.isActive;
    days = List<String>.from(p.days);
    conditionType = p.conditionType;
    if (p.conditionValue != null) {
      conditionValueCtrl.text = p.conditionValue.toString();
    }
    useMaxDiscount = p.useMaxDiscount;
    if (p.maxDiscount != null) {
      maxDiscountCtrl.text = p.maxDiscount.toString();
    }
    // eligibleServices
    for (var el in p.eligibleServices) {
      final s = el['serviceId'] ?? '';
      final i = el['itemId'] ?? '';
      if (s.isNotEmpty && i.isNotEmpty) {
        selectedEligibility.add("$s|$i");
      }
    }
  }

  Future<void> _loadBranchAndServices() async {
    final prefs = await SharedPreferences.getInstance();
    branchId = prefs.getString('activeBranchId') ?? '';
    if (branchId.isEmpty) return;

    // fetch services where branchId == activeBranchId
    final snap = await FirebaseFirestore.instance
        .collection('services')
        .where('branchId', isEqualTo: branchId)
        .get();

    final result = <_ServiceWithItems>[];

    for (var doc in snap.docs) {
      final data = doc.data();
      final unit = (data['unit'] ?? '').toString();
      final name = (data['name'] ?? '').toString();

      // fetch items subcollection
      final itemsSnap = await doc.reference.collection('items').get();
      final items = itemsSnap.docs.map((it) {
        final d = it.data();
        return _ServiceItem(
          id: it.id,
          name: d['name'] ?? '',
          price: d['price'] ?? 0,
          durationHours: d['durationHours'] ?? 0,
        );
      }).toList();

      result.add(
        _ServiceWithItems(
          serviceId: doc.id,
          name: name,
          unit: unit,
          items: items,
        ),
      );
    }

    setState(() => services = result);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    rateCtrl.dispose();
    conditionValueCtrl.dispose();
    maxDiscountCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

  Future<void> pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        start = picked;
        // keep end valid
        if (end != null && end!.isBefore(picked)) end = null;
      });
    }
  }

  Future<void> pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: end ?? (start ?? now),
      firstDate: start ?? now,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => end = picked);
  }

  void _toggleDay(String code) {
    setState(() {
      if (days.contains(code)) {
        days.remove(code);
      } else {
        days.add(code);
      }
    });
  }

  void _toggleEligibility(String serviceId, String itemId) {
    final key = "$serviceId|$itemId";
    setState(() {
      if (selectedEligibility.contains(key))
        selectedEligibility.remove(key);
      else
        selectedEligibility.add(key);
    });
  }

  Future<void> submit() async {
    final title = titleCtrl.text.trim();
    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Judul promo belum diisi",
        success: false,
      );
      return;
    }
    if (start == null || end == null) {
      TopNotification.show(
        title: "Error",
        message: "Tanggal mulai & selesai wajib diisi",
        success: false,
      );
      return;
    }
    if (end!.isBefore(start!)) {
      TopNotification.show(
        title: "Error",
        message: "Tanggal berakhir harus setelah mulai",
        success: false,
      );
      return;
    }
    if (isAutomatic && days.isEmpty) {
      TopNotification.show(
        title: "Error",
        message: "Pilih minimal 1 hari berlaku untuk promo otomatis",
        success: false,
      );
      return;
    }

    try {
      if (editing) {
        await _updatePromo(rate);
      } else {
        await _createPromo(rate);
      }
      TopNotification.show(
        title: "Success",
        message: editing ? "Promo diperbarui" : "Promo disimpan",
        success: true,
      );
      if (mounted) Get.back(result: true);
    } catch (e) {
      TopNotification.show(
        title: "Error",
        message: "Gagal menyimpan promo: $e",
        success: false,
      );
    }
  }

  Future<void> _createPromo(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    final bId = prefs.getString('activeBranchId') ?? '';

    final docRef = FirebaseFirestore.instance.collection("promos").doc();
    final eligibleList = selectedEligibility.map((k) {
      final parts = k.split('|');
      return {'serviceId': parts[0], 'itemId': parts[1]};
    }).toList();

    await docRef.set({
      "title": titleCtrl.text.trim(),
      "type": type,
      "discountRate": rate,
      "start": Timestamp.fromDate(start!),
      "end": Timestamp.fromDate(end!),
      "isAutomatic": isAutomatic,
      "isActive": true,
      "branchId": bId,
      "days": days,
      "conditionType": conditionType,
      "conditionValue": conditionValueCtrl.text.isNotEmpty
          ? num.tryParse(conditionValueCtrl.text)
          : null,
      "useMaxDiscount": useMaxDiscount,
      "maxDiscount": maxDiscountCtrl.text.isNotEmpty
          ? num.tryParse(maxDiscountCtrl.text)
          : null,
      "eligibleServices": eligibleList,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updatePromo(double rate) async {
    final id = widget.promo!.id;
    final docRef = FirebaseFirestore.instance.collection("promos").doc(id);

    final eligibleList = selectedEligibility.map((k) {
      final parts = k.split('|');
      return {'serviceId': parts[0], 'itemId': parts[1]};
    }).toList();

    final updateData = <String, dynamic>{
      "title": titleCtrl.text.trim(),
      "type": type,
      "discountRate": rate,
      "start": Timestamp.fromDate(start!),
      "end": Timestamp.fromDate(end!),
      "isAutomatic": isAutomatic,
      "isActive": isActive,
      "days": days,
      "conditionType": conditionType,
      "conditionValue": conditionValueCtrl.text.isNotEmpty
          ? num.tryParse(conditionValueCtrl.text)
          : null,
      "useMaxDiscount": useMaxDiscount,
      "maxDiscount": maxDiscountCtrl.text.isNotEmpty
          ? num.tryParse(maxDiscountCtrl.text)
          : null,
      "eligibleServices": eligibleList,
      "updatedAt": FieldValue.serverTimestamp(),
    };

    await docRef.update(updateData);
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.role.value != 'owner') {
      Future.microtask(
        () => Navigator.pushReplacementNamed(context, '/dashboard'),
      );
      return const SizedBox.shrink();
    }

    final discountLabel = type == "percentage"
        ? "Discount Rate (%)"
        : "Discount Rate (Rp.)";

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? "Edit Promo" : "Add Promo"),
        actions: [
          if (editing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Hapus Promo?"),
                    content: const Text(
                      "Promo akan dihapus permanen. Lanjutkan?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        child: const Text("Hapus"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  try {
                    await FirebaseFirestore.instance
                        .collection("promos")
                        .doc(widget.promo!.id)
                        .delete();
                    TopNotification.show(
                      title: "Success",
                      message: "Promo dihapus",
                      success: true,
                    );
                    if (mounted) Get.back(result: true);
                  } catch (e) {
                    TopNotification.show(
                      title: "Error",
                      message: "Gagal menghapus: $e",
                      success: false,
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Promo Otomatis"),
            value: isAutomatic,
            onChanged: (v) => setState(() => isAutomatic = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Promo Title"),
          ),
          const SizedBox(height: 12),

          // START DATE
          ListTile(
            onTap: pickStartDate,
            title: Text(
              start == null
                  ? "Pilih Tanggal Mulai"
                  : "Mulai: ${_formatDate(start!)}",
            ),
            trailing: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 12),

          // END DATE
          ListTile(
            onTap: pickEndDate,
            title: Text(
              end == null
                  ? "Pilih Tanggal Berakhir"
                  : "Berakhir: ${_formatDate(end!)}",
            ),
            trailing: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 12),

          // If automatic, show days picker & conditions & eligible services
          if (isAutomatic) ...[
            const Text(
              "Berlaku untuk hari",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: dayOptions.map((d) {
                final code = d[0];
                final label = d[1];
                final selected = days.contains(code);
                return FilterChip(
                  selected: selected,
                  label: Text(label),
                  onSelected: (_) => _toggleDay(code),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            const Text(
              "Syarat Promo",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: conditionType,
              decoration: const InputDecoration(labelText: "Syarat promo"),
              items: const [
                DropdownMenuItem(value: "minQty", child: Text("Minimal Qty")),
                DropdownMenuItem(
                  value: "minTotal",
                  child: Text("Minimal Total Harga"),
                ),
              ],
              onChanged: (v) => setState(() {
                conditionType = v;
                conditionValueCtrl.clear();
              }),
            ),
            const SizedBox(height: 8),
            if (conditionType != null)
              TextField(
                controller: conditionValueCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: conditionType == "minQty"
                      ? "Syarat minimal jumlah (pcs)"
                      : "Syarat minimal total (Rp.)",
                ),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),
            const Text(
              "Berlaku untuk produk/layanan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text("No services found for this branch."),
              )
            else
              ...services.map((s) {
                return ExpansionTile(
                  title: Text("${s.name} (${s.unit})"),
                  children: s.items.map((it) {
                    final key = "${s.serviceId}|${it.id}";
                    final checked = selectedEligibility.contains(key);
                    return CheckboxListTile(
                      value: checked,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      title: Text(it.name),
                      subtitle: Text(
                        "Rp ${it.price} • ${it.durationHours} jam",
                      ),
                      onChanged: (_) => _toggleEligibility(s.serviceId, it.id),
                    );
                  }).toList(),
                );
              }).toList(),

            const SizedBox(height: 12),
          ],

          // NON-automatic & automatic both have discount fields
          TextField(
            controller: rateCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: discountLabel),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: "Jenis Potongan"),
            items: const [
              DropdownMenuItem(value: "percentage", child: Text("Percentage")),
              DropdownMenuItem(value: "fixed", child: Text("Fixed Amount")),
            ],
            onChanged: (v) => setState(() => type = v ?? "percentage"),
          ),
          const SizedBox(height: 12),

          // MAX DISCOUNT
          CheckboxListTile(
            title: const Text("Gunakan Maksimal Diskon"),
            value: useMaxDiscount,
            onChanged: (v) => setState(() => useMaxDiscount = v ?? false),
          ),
          if (useMaxDiscount)
            TextField(
              controller: maxDiscountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Maksimal Diskon (Rp.)",
              ),
            ),

          const SizedBox(height: 12),

          // If editing show Active toggle
          if (editing)
            SwitchListTile(
              title: const Text("Aktifkan Promo"),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: submit,
            child: Text(editing ? "Update Promo" : "Save Promo"),
          ),
        ],
      ),
    );
  }
}
