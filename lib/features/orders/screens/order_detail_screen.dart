import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order_model.dart';
import 'create_order_screen.dart';

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
  static const _editableStatuses = {'new', 'picking-up', 'pending'};
  static const _workflows = {
    'cuci': 'washing',
    'kering': 'drying',
    'strika': 'ironing',
    'setrika': 'ironing',
  };

  List<String> _steps(Map<String, dynamic> service) {
    final types = List<String>.from(
      service['processTypes'] ?? service['processType'] ?? [],
    );
    return [
      'pending',
      ...types.map((type) => _workflows[type]).whereType<String>(),
      'packing',
    ];
  }

  String _label(String status) =>
      {
        'pending': 'Pending',
        'washing': 'Cuci',
        'drying': 'Kering',
        'ironing': 'Strika',
        'packing': 'Packing',
      }[status] ??
      status;

  IconData _icon(String status) =>
      {
        'pending': Icons.hourglass_empty,
        'washing': Icons.local_laundry_service,
        'drying': Icons.air,
        'ironing': Icons.iron,
        'packing': Icons.inventory_2,
      }[status] ??
      Icons.help_outline;

  Future<void> _advanceItem(
    BuildContext context,
    List<Map<String, dynamic>> services,
    int index,
  ) async {
    final item = services[index];
    final steps = _steps(item);
    final current = item['itemStatus']?.toString() ?? 'pending';
    final nextIndex = steps.indexOf(current) + 1;
    if (nextIndex <= 0 || nextIndex >= steps.length) return;
    final next = steps[nextIndex];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Perbarui Status Layanan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['name']?.toString() ?? 'Layanan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Jumlah: ${item['qty'] ?? 0} • ${_label(current)} → ${_label(next)}',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated = services
                        .map((service) => Map<String, dynamic>.from(service))
                        .toList();
                    updated[index]['itemStatus'] = next;
                    final allPacked = updated.every(
                      (service) => service['itemStatus'] == 'packing',
                    );
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({
                          'services': updated,
                          'dashboardStatus': allPacked
                              ? 'siap_ambil'
                              : 'proses',
                          'status': allPacked ? 'packing' : 'washing',
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: Icon(_icon(next)),
                  label: Text('Ubah ke ${_label(next)}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          return _buildContent(context, order);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> order) {
    final customer = order['customer'] as Map<String, dynamic>? ?? {};
    final services = (order['services'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final notes = order['notes']?.toString().trim() ?? '';
    final status = _dashboardStatus(order);
    final createdAt = order['createdAt'] as Timestamp?;
    final dueDate = order['dueDate'] as Timestamp?;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(label: Text(_statusLabels[status] ?? status)),
                    Text(
                      createdAt == null
                          ? 'Baru dibuat'
                          : 'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Estimasi selesai: ${DateFormat('dd MMM yyyy, HH:mm').format(dueDate.toDate())}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_editableStatuses.contains(order['status'])) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateOrderScreen(orderId: orderId),
                            ),
                          ),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Pesanan'),
                        ),
                      ),
                    ],
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
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (entry) => _serviceRow(
                                context,
                                services,
                                entry.key,
                                entry.value,
                                status,
                              ),
                            )
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

  Widget _serviceRow(
    BuildContext context,
    List<Map<String, dynamic>> services,
    int index,
    Map<String, dynamic> service,
    String orderStatus,
  ) {
    final price = (service['price'] as num?) ?? 0;
    final qty = (service['qty'] as num?) ?? 0;
    final subtotal = (service['subtotal'] as num?) ?? price * qty;

    final steps = _steps(service);
    final itemStatus = service['itemStatus']?.toString() ?? 'pending';
    final canAdvance =
        (orderStatus == 'antrian' || orderStatus == 'proses') &&
        steps.length > 2 &&
        itemStatus != 'packing';
    return InkWell(
      onTap: canAdvance ? () => _advanceItem(context, services, index) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
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
            if (steps.length <= 2)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Workflow belum tersedia',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: steps.map((step) {
                    final stepIndex = steps.indexOf(step);
                    final currentIndex = steps.indexOf(itemStatus);
                    final color = stepIndex < currentIndex
                        ? Colors.green
                        : stepIndex == currentIndex
                        ? Colors.blue
                        : Colors.grey;
                    return Column(
                      children: [
                        Icon(_icon(step), color: color),
                        Text(
                          _label(step),
                          style: TextStyle(fontSize: 10, color: color),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
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
