import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/order_model.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  late String? _selectedStatus = widget.initialStatus;
  late final Future<String> _branchId = _loadBranchId();

  static const _statuses = <String, String>{
    'konfirmasi': 'Konfirmasi',
    'penjemputan': 'Penjemputan',
    'antrian': 'Antrian',
    'proses': 'Proses',
    'siap_ambil': 'Siap Ambil',
    'pengantaran': 'Siap Antar',
  };

  Future<String> _loadBranchId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('activeBranchId') ?? '';
  }

  String _dashboardStatus(Map<String, dynamic> order) {
    final saved = order['dashboardStatus']?.toString();
    return saved?.isNotEmpty == true
        ? saved!
        : OrderModel.mapDashboardStatus(
            order['status']?.toString() ?? 'pending',
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan')),
      body: FutureBuilder<String>(
        future: _branchId,
        builder: (context, branchSnapshot) {
          if (!branchSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final branchId = branchSnapshot.data!;
          if (branchId.isEmpty) {
            return const Center(child: Text('Cabang aktif belum dipilih.'));
          }

          return Column(
            children: [
              _buildStatusFilters(),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('branchId', isEqualTo: branchId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Pesanan tidak dapat dimuat.'),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders =
                        snapshot.data!.docs.where((doc) {
                          return _selectedStatus == null ||
                              _dashboardStatus(doc.data()) == _selectedStatus;
                        }).toList()..sort((a, b) {
                          final aDate = a.data()['createdAt'] as Timestamp?;
                          final bDate = b.data()['createdAt'] as Timestamp?;
                          return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
                            aDate?.millisecondsSinceEpoch ?? 0,
                          );
                        });

                    if (orders.isEmpty) {
                      final label = _selectedStatus == null
                          ? 'Belum ada pesanan.'
                          : 'Belum ada pesanan ${_statuses[_selectedStatus] ?? ''}.';
                      return Center(child: Text(label));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildOrderCard(orders[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Semua'),
            selected: _selectedStatus == null,
            onSelected: (_) => setState(() => _selectedStatus = null),
          ),
          ..._statuses.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _selectedStatus == entry.key,
                onSelected: (_) => setState(() => _selectedStatus = entry.key),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot<Map<String, dynamic>> order) {
    final data = order.data();
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'] as Timestamp?;
    final status = _dashboardStatus(data);
    final total = (data['totalFinal'] as num?)?.toDouble() ?? 0;

    return Card(
      child: ListTile(
        onTap: () =>
            Navigator.pushNamed(context, '/orders/detail', arguments: order.id),
        leading: const CircleAvatar(child: Icon(Icons.local_laundry_service)),
        title: Text(customer['name']?.toString() ?? 'Pelanggan'),
        subtitle: Text(
          '${_statuses[status] ?? status}\n${createdAt == null ? 'Baru dibuat' : DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate())}',
        ),
        isThreeLine: true,
        trailing: Text(
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(total),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
