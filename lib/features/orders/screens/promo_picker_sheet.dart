import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../data/models/promo_model.dart';

class PromoPickerSheet extends StatefulWidget {
  final String branchId;
  const PromoPickerSheet({super.key, required this.branchId});

  @override
  State<PromoPickerSheet> createState() => _PromoPickerSheetState();
}

class _PromoPickerSheetState extends State<PromoPickerSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<PromoModel> promos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromos();
  }

  Future<void> _loadPromos() async {
    setState(() => isLoading = true);
    try {
      final now = DateTime.now();
      final snap = await _db
          .collection('promos')
          .where('branchId', isEqualTo: widget.branchId)
          .where('isActive', isEqualTo: true)
          .where('isAutomatic', isEqualTo: false)
          .orderBy('start', descending: true)
          .get();

      promos = snap.docs.map((d) => PromoModel.fromJson(d.data(), d.id)).where((
        p,
      ) {
        final start = p.start;
        final end = p.end;

        return now.isAfter(start) && now.isBefore(end);
      }).toList();
    } catch (e) {
      debugPrint('loadPromos error: $e');
      promos = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Pilih Promo",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (isLoading) const CircularProgressIndicator(),
              if (!isLoading && promos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("Tidak ada promo aktif untuk cabang ini."),
                ),
              if (!isLoading)
                Expanded(
                  child: ListView.builder(
                    itemCount: promos.length,
                    itemBuilder: (_, i) {
                      final p = promos[i];
                      final label = p.type == 'percentage'
                          ? "${p.discountRate}%"
                          : "Rp ${p.discountRate}";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(p.title),
                          subtitle: Text(label),
                          onTap: () {
                            Navigator.pop(context, p);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
