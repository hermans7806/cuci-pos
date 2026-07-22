import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  static const _statusLabels = <String, String>{
    'konfirmasi': 'Konfirmasi',
    'penjemputan': 'Penjemputan',
    'antrian': 'Antrian',
    'proses': 'Proses',
    'siap_ambil': 'Siap Ambil',
    'pengantaran': 'Siap Antar',
    'selesai': 'Selesai',
  };

  String _dashboardStatus(Map<String, dynamic> order) {
    final saved = order['dashboardStatus']?.toString();
    return saved?.isNotEmpty == true
        ? saved!
        : OrderModel.mapDashboardStatus(
            order['status']?.toString() ?? 'pending',
          );
  }

  String _currency(num value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Pesanan tidak dapat dimuat.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }

          final order = snapshot.data!.data()!;
          return _buildContent(order);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> order) {
    final customer = order['customer'] as Map<String, dynamic>? ?? {};
    final services = (order['services'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final notes = order['notes']?.toString().trim() ?? '';
    final status = _dashboardStatus(order);
    final createdAt = order['createdAt'] as Timestamp?;
    final totalBefore = (order['totalBeforeDiscount'] as num?) ?? 0;
    final discount = (order['totalDiscount'] as num?) ?? 0;
    final totalFinal = (order['totalFinal'] as num?) ?? totalBefore - discount;
    final perfume = order['perfume'] == true;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionCard(
                title: 'Pelanggan',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(customer['name']?.toString() ?? 'Pelanggan'),
                  subtitle: Text(customer['phone']?.toString() ?? '-'),
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Status Pesanan',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(label: Text(_statusLabels[status] ?? status)),
                    Text(
                      createdAt == null
                          ? 'Baru dibuat'
                          : DateFormat(
                              'dd MMM yyyy, HH:mm',
                            ).format(createdAt.toDate()),
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Detail Pesanan',
                child: services.isEmpty
                    ? const Text('Tidak ada layanan.')
                    : Column(
                        children: services
                            .map((service) => _serviceRow(service))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Informasi Tambahan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Gunakan parfum', perfume ? 'Ya' : 'Tidak'),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Catatan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(notes),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Informasi Tagihan',
                child: Column(
                  children: [
                    _infoRow('Total Harga', _currency(totalBefore)),
                    if (discount > 0) ...[
                      const SizedBox(height: 8),
                      _infoRow('Diskon', '- ${_currency(discount)}'),
                    ],
                    const Divider(height: 24),
                    _infoRow(
                      'Total Tagihan',
                      _currency(totalFinal),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border(top: BorderSide(color: Colors.blue.shade100)),
          ),
          child: const Text(
            'Detail pesanan hanya dapat dilihat saat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _serviceRow(Map<String, dynamic> service) {
    final price = (service['price'] as num?) ?? 0;
    final qty = (service['qty'] as num?) ?? 0;
    final subtotal = (service['subtotal'] as num?) ?? price * qty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_laundry_service, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name']?.toString() ?? 'Layanan',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text('${_currency(price)} × $qty'),
              ],
            ),
          ),
          Text(
            _currency(subtotal),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
