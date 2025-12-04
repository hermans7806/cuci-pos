import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuci_pos/core/utils/top_notification.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/promo_model.dart';
import '../../profile/controllers/profile_controller.dart';

class AddPromoScreen extends StatefulWidget {
  final PromoModel? promo; // if provided -> editing mode

  const AddPromoScreen({super.key, this.promo});

  @override
  State<AddPromoScreen> createState() => _AddPromoScreenState();
}

class _AddPromoScreenState extends State<AddPromoScreen> {
  final titleCtrl = TextEditingController();
  final rateCtrl = TextEditingController();

  // "percentage" or "fixed"
  String type = "percentage";
  bool isAutomatic = false;
  DateTime? start;
  DateTime? end;

  // editing flag
  bool get editing => widget.promo != null;

  // active toggle (only shown in editing mode)
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    if (editing) {
      final p = widget.promo!;
      titleCtrl.text = p.title;
      rateCtrl.text = p.discountRate.toString();
      type = p.type;
      isAutomatic = p.isAutomatic;
      start = p.start;
      end = p.end;
      isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    rateCtrl.dispose();
    super.dispose();
  }

  Future<void> pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => start = picked);
      // if end is before start, reset end
      if (end != null && end!.isBefore(picked)) {
        setState(() => end = null);
      }
    }
  }

  Future<void> pickEndDate() async {
    final now = DateTime.now();
    final initial = end ?? (start ?? now);
    final first = start ?? DateTime(2020);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => end = picked);
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
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
        message: "Tanggal berakhir harus setelah tanggal mulai",
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
    final branchId = prefs.getString('activeBranchId') ?? "";

    final docRef = FirebaseFirestore.instance.collection("promos").doc();

    await docRef.set({
      "title": titleCtrl.text.trim(),
      "type": type,
      "discountRate": rate,
      "start": Timestamp.fromDate(start!),
      "end": Timestamp.fromDate(end!),
      "isAutomatic": isAutomatic,
      "isActive": true, // new promos default to active
      "branchId": branchId,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updatePromo(double rate) async {
    final id = widget.promo!.id;
    final docRef = FirebaseFirestore.instance.collection("promos").doc(id);

    final updateData = <String, dynamic>{
      "title": titleCtrl.text.trim(),
      "type": type,
      "discountRate": rate,
      "start": Timestamp.fromDate(start!),
      "end": Timestamp.fromDate(end!),
      "isAutomatic": isAutomatic,
      "updatedAt": FieldValue.serverTimestamp(),
      // include isActive only when editing (allow toggling)
      "isActive": isActive,
    };

    await docRef.update(updateData);
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    if (profileCtrl.role.value != 'owner') {
      // redirect non-owner users back to dashboard
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
              icon: Icon(Icons.delete),
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
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: "Promo Title"),
          ),
          const SizedBox(height: 12),

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

          // Only show "Promo Otomatis" toggle (checked/unchecked) for both add & edit
          SwitchListTile(
            title: const Text("Promo Otomatis"),
            value: isAutomatic,
            onChanged: (v) => setState(() => isAutomatic = v),
          ),
          const SizedBox(height: 8),

          // If editing show Active toggle
          if (editing)
            SwitchListTile(
              title: const Text("Aktifkan Promo"),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),

          const SizedBox(height: 8),

          // START DATE PICKER
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

          // END DATE PICKER
          ListTile(
            onTap: pickEndDate,
            title: Text(
              end == null
                  ? "Pilih Tanggal Berakhir"
                  : "Berakhir: ${_formatDate(end!)}",
            ),
            trailing: const Icon(Icons.calendar_today),
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
