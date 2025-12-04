import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/promo_model.dart';

class PromoCard extends StatelessWidget {
  final PromoModel promo;
  const PromoCard({super.key, required this.promo});

  @override
  Widget build(BuildContext context) {
    final date =
        "${DateFormat('dd MMM yyyy').format(promo.start)}"
        " - "
        "${DateFormat('dd MMM yyyy').format(promo.end)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text("Jenis Potongan: ${promo.type}"),
          Text("Tanggal Berlaku: $date"),
          Text("Diskon Didapat: ${promo.discountRate}%"),
        ],
      ),
    );
  }
}
